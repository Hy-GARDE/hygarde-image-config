#!/usr/bin/env sh

# This initializes a PostgreSQL cluster in a specific directory which is
# meant to be encrypted, and configures it to use TimescaleDB (also
# applying some tuning in the process). The packages which are useful
# only to this script are then uninstalled.

set -e

# create Postgres data dir
mkdir /data/pgsql
chown postgres:postgres /data/pgsql
chmod 700 /data/pgsql

# init and tune database
/usr/sbin/postgresql-new-systemd-unit --unit postgresql@hygarde --datadir=/data/pgsql/data
postgresql-setup --initdb --unit postgresql@hygarde --port 5432
timescaledb-tune -yes -/data/pgsql/data/postgresql.conf

# apply changes
systemctl restart postgresql@hygarde
# equivalent of `dnf remove timescaledb-tune`
rpm -vv -e timescaledb-tune keyutils-libs-devel krb5-devel libcom_err-devel libicu-devel libkadm5 libpkgconf libselinux-devel libsepol-devel libverto-devel openssl-devel pcre2-devel pcre2-utf16 pcre2-utf32 pkgconf pkgconf-m4 pkgconf-pkg-config postgresql-private-devel postgresql-server-devel
