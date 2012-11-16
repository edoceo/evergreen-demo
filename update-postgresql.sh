#!/bin/bash

set -o errexit

# 25% of RAM to PostgreSQL
echo $(( $(awk '/MemTotal/ { print $2 }' /proc/meminfo) * 1024 / 4 )) > /proc/sys/kernel/shmmax

# x=$(( $(cat /proc/sys/kernel/shmmax) / 1048576))
# x=$(( $x / 100 * 80 ))
# echo -e " ${R}*${N} shared_buffers should be set to ${x}MB"
# sed -i "s/^shared_buffers.*/shared_buffers = ${x}MB/" /etc/postgresql/9.1/main/postgresql.conf
# grep -inr shared_buffers /etc/postgresql/

/etc/init.d/postgresql-9.1 restart

if [ -z "${EGUSER}" ]; then
    exit "I Need EGUSER to be set"
fi

if [ -z "${PGUSER}" ]; then
    exit "I Need PGUSER to be set"
fi

#
# Create/Update the PostgreSQL Side
function update_database()
{
    # su -l -c 'createuser --superuser egpg' postgres || true
    echo -en "${PGUSER}\n${PGUSER}\n" | su -l -c "createuser --superuser ${PGUSER}" postgres || true
    cd /usr/src/Evergreen

    perl Open-ILS/src/support-scripts/eg_db_config.pl \
        --update-config --service all --create-database --create-schema --create-offline \
        --user ${PGUSER} --password ${PGUSER} --hostname localhost \
        --database evergreen --admin-user ${EGUSER} --admin-pass ${EGUSER} >/dev/null

}
update_database

/etc/init.d/postgresql-9.1 stop