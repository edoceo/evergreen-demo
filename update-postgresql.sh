#!/bin/bash -x

set -o errexit

if [ -z "${EGUSER}" ]; then
    echo "I Need EGUSER to be set"
    exit
fi

if [ -z "${PGUSER}" ]; then
    echo "I Need PGUSER to be set"
    exit
fi

# 25% of RAM to PostgreSQL
echo $(( $(awk '/MemTotal/ { print $2 }' /proc/meminfo) * 1024 / 4 )) > /proc/sys/kernel/shmmax

# x=$(( $(cat /proc/sys/kernel/shmmax) / 1048576))
# x=$(( $x / 100 * 80 ))
# echo -e " ${R}*${N} shared_buffers should be set to ${x}MB"
# sed -i "s/^shared_buffers.*/shared_buffers = ${x}MB/" /etc/postgresql/9.2/main/postgresql.conf
# grep -inr shared_buffers /etc/postgresql/

if [ -x /etc/init.d/postgresql-9.1 ]
then 
    /etc/init.d/postgresql-9.1 restart
fi
if [ -x /etc/init.d/postgresql-9.2 ]
then 
    /etc/init.d/postgresql-9.2 restart
fi

#
# Create/Update the PostgreSQL Side
function update_database()
{
    # su -l -c 'createuser --superuser egpg' postgres || true
    su -l -c "dropdb ${PGDATABASE}" postgres || true
    su -l -c "dropuser ${PGUSER}" postgres || true
    echo -en "${PGUSER}\n${PGUSER}\n" | su -l -c "createuser --superuser ${PGUSER}" postgres || true
    cd /usr/src/Evergreen

    perl Open-ILS/src/support-scripts/eg_db_config.pl \
        --update-config --service all --create-database --create-schema --create-offline \
        --user ${PGUSER} --password ${PGUSER} --hostname ${PGHOSTNAME} \
        --database ${PGDATABASE} --admin-user ${EGUSER} --admin-pass ${EGUSER} >/dev/null

}
update_database

if [ -x /etc/init.d/postgresql-9.1 ]
then 
    /etc/init.d/postgresql-9.1 stop
fi
if [ -x /etc/init.d/postgresql-9.2 ]
then 
    /etc/init.d/postgresql-9.2 stop
fi
