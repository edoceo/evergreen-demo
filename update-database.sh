#!/bin/bash

swd=$(dirname $(readlink -f $0))

echo $(( $(awk '/MemTotal/ { print $2 }' /proc/meminfo) * 1024 / 2 )) > /proc/sys/kernel/shmmax
/etc/init.d/postgresql-9.1 restart

#
# Create/Update the PostgreSQL Side
function update_database()
{

    # su -l -c 'createuser --superuser egpg' postgres || true
    echo -en "egpg\negpg\n" | su -l -c 'createuser --superuser egpg' postgres || true
    cd /usr/src/Evergreen

    perl Open-ILS/src/support-scripts/eg_db_config.pl \
        --update-config --service all --create-database --create-schema --create-offline \
        --user egpg --password egpg --hostname localhost \
        --database evergreen --admin-user egsa --admin-pass egsa >/dev/null

    # psql -U evergreen -h hostname -f Open-ILS/tests/datasets/concerto.sql
    # psql -U evergreen -h hostname -f Open-ILS/tests/datasets/users_patrons_100.sql
    # psql -U evergreen -h hostname -f Open-ILS/tests/datasets/users_staff_134.sql

    export PGUSER="egpg"
    export PGPASSWORD="egpg"
    export PGHOSTNAME="localhost"
    export PGDATABASE="evergreen"

    cd "$swd"
    psql --quiet --set=ON_ERROR_STOP --file ./sql/05-demo-user.sql
    psql --quiet --set=ON_ERROR_STOP --file ./sql/06-patrons.sql
    psql --quiet --set=ON_ERROR_STOP --file ./sql/10-item-import.sql

}
update_database

echo $FILE