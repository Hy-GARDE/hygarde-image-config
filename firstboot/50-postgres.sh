#!/usr/bin/env sh

# This initializes a PostgreSQL cluster in a specific directory which is
# meant to be encrypted, and configures it to use TimescaleDB (also
# applying some tuning in the process). The packages which are useful
# only to this script are then uninstalled.

set -e

# create Postgres data dir
echo "firstboot PostgreSQL: create data dir"
mkdir -p /data/pgsql/data
chown --recursive postgres:postgres /data/pgsql
chmod --recursive 700 /data/pgsql
chsmack --recursive --access System /data/pgsql

# init and tune database
echo "firstboot PostgreSQL: init and tune cluster"
/usr/sbin/postgresql-new-systemd-unit --unit postgresql@hygarde --datadir=/data/pgsql/data
postgresql-setup --initdb --unit postgresql@hygarde --port 5432
timescaledb-tune -yes -conf-path /data/pgsql/data/postgresql.conf

# apply changes
echo "firstboot PostgreSQL: apply changes and remove tools"
systemctl start postgresql@hygarde
# equivalent of `dnf remove timescaledb-tune`
rpm -v -e timescaledb-tune keyutils-libs-devel krb5-devel libcom_err-devel libicu-devel libkadm5 libselinux-devel libsepol-devel libverto-devel openssl-devel pcre2-devel pcre2-utf16 pcre2-utf32 postgresql-private-devel postgresql-server-devel

echo "firstboot PostgreSQL: init done"
