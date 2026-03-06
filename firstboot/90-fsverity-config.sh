#!/usr/bin/env sh

# The goal of this script is to protect some critical
# Linux files from tampering. Each file is made
# read-only using fs-verity and the hash of
# each one (Merkle tree) is authenticated with
# signatures (using a PKCS#11 communication engine).
#
# All the configuration is done once during
# firstboot process (as root). The security model of
# this feature requires a completed secure bootflow
# (Secure boot, trusted HSM, unmodified certificate
# in the Kernel keyrings...) with other verification
# in userspace before read access (e.g. an eBFP) or
# after an update of a verity file (e.g. RPM plugin).

set -euo pipefail

# List of files protected by fsverity mechanism
FILES_TO_PROTECT="
/etc/firewalld/firewalld.conf
/etc/chrony.conf
/etc/passwd
/etc/group
/etc/shadow
/etc/sudoers
/etc/fstab
/etc/yum.repos.d/hygarde_dfb1e502--redpesk-lts-corn-3.0-update-build.repo
/etc/yum.repos.d/hygarde-hummingboard_5a46cd3a--redpesk-lts-corn-3.0-update-build.repo
/etc/yum.repos.d/redpesk.repo
"

# Add PostgreSQL files if exist
PG_BASE="/data/pgsql"

if [ -d "$PG_BASE" ]; then
    PG_VERSION_DIR=$(find "$PG_BASE" -maxdepth 1 -type d -regex ".*/[0-9]+" | sort -V | tail -n 1)

    if [ -n "${PG_VERSION_DIR:-}" ]; then
        PG_DATA_DIR="$PG_VERSION_DIR/data"
    else
        echo "NO PostgreSQL version found in $PG_BASE"
        PG_DATA_DIR=""
    fi
else
    PG_DATA_DIR=""
fi

if [ -n "$PG_DATA_DIR" ]; then
    FILES_TO_PROTECT="$FILES_TO_PROTECT
$PG_DATA_DIR/postgresql.conf
$PG_DATA_DIR/pg_hba.conf
$PG_DATA_DIR/pg_ident.conf"
fi

# List of mandatory packages needed
REQUIRED_CMDS="fsverity pkcs11-tool openssl keyctl"

for cmd in $REQUIRED_CMDS; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd is not installed!"
        exit 1
    fi
done

# Exit if PKCS#11 communication isn't well configured
# NOTE: an authentication feature must be enabled for
# the eUICC access in an industrial "prod" context!
if ! pkcs11-tool --list-slots 2>/dev/null | grep -q "token label.*IOT_SAFE"; then
    echo "Error: PKCS11 'IOT_SAFE' not detected (wrong opensc/openct config, missing eUICC, etc)."
    exit 1
fi

CERT_DIR=/etc/fsverity
SIG_DIR=/tmp/fsverity/signatures
# Creation of directories (sign)
mkdir -p "$CERT_DIR" "$SIG_DIR"
chmod 700 "$SIG_DIR"

# Certificate configuration/creation using eUICC (RSA key)
# The certificate must be created by taking the provided
# keys in the eUICC so it's only created if it doesn't exist.
#
# /!\  Certificate creation at firstboot is possible   /!\
# /!\  since we trust the filesystem and boot steps.   /!\
#
# openssl-pkcs11 required (because of libfsverity/fsverity-utils)
if [ ! -f "$CERT_DIR/cert.pem" ]; then
    echo "Generating fsverity certificate..."
    openssl req -new -x509 -sha256 \
        -engine pkcs11 \
        -keyform engine \
        -key "pkcs11:token=IOT_SAFE;object=STATIC_KEY_CA_1;type=private" \
        -out "$CERT_DIR/cert.pem" \
        -days 3650 \
        -subj "/C=FR/ST=Bretagne/L=Lorient/O=IoT.bzh/OU=Security/CN=IOT_SAFE_CA/emailAddress=contact@hygarde.fr"
fi

# Add the certificate (public key) in the Kernel keyrings (keys storage)
openssl x509 -in "$CERT_DIR/cert.pem" -out "$CERT_DIR/cert.der" -outform der
if ! keyctl list %keyring:.fs-verity 2>/dev/null | grep -q "IOT_SAFE_CA"; then
    keyctl padd asymmetric '' %keyring:.fs-verity < "$CERT_DIR/cert.der"
fi

# Protect each file of the defined list
for file in $FILES_TO_PROTECT
do
    if [ ! -f "$file" ]; then
        echo " $file not found, skipped"
        continue
    fi
    filename=$(basename "$file")

    # After an update of a file - because fsverity allows the
    # deletion of a file -  it's necessary to protect it again.
    # But if the file is already protected, we skip it.
    if fsverity measure "$file" >/dev/null 2>&1; then
        echo "$file already protected, skipped"
        continue
    fi

    fsverity sign \
        "$file" \
        "$SIG_DIR/${filename}.sig" \
        --pkcs11-engine /usr/lib64/engines-3/pkcs11.so \
        --pkcs11-module /usr/lib64/pkcs11/opensc-pkcs11.so \
        --cert "$CERT_DIR/cert.pem" \
        --pkcs11-keyid "pkcs11:token=IOT_SAFE;object=STATIC_KEY_CA_1;type=private"

    fsverity enable "$file" --signature="$SIG_DIR/${filename}.sig"

    echo "Protection done on "$file" which is now read-only"
done

exit 0
