#!/bin/bash -x

set -o errexit

/etc/init.d/postgresql-9.1 restart

if [ -z "${PGUSER}" ]; then
    exit "I Need PGUSER to be set"
fi

# Load all the Evergreen Sample Data
cd /usr/src/Evergreen/Open-ILS/tests/datasets/sql
psql --quiet --file ./load_all.sql
cd -

psql --quiet --set=ON_ERROR_STOP --file ./sql/01-init.sql >/dev/null
psql --quiet --set=ON_ERROR_STOP --file ./sql/05-demo-user.sql >/dev/null
psql --quiet --set=ON_ERROR_STOP --file ./sql/06-patrons.sql >/dev/null
# psql --quiet --set=ON_ERROR_STOP --file ./sql/10-import.sql >/dev/null

#
#  535  psql -U egpg -h localhost -f tests/datasets/concerto.sql
#  536  psql -U egpg -h localhost -f tests/datasets/concerto.sql evergreen
#  537  psql -U egpg -h localhost -f tests/datasets/users_patrons_100.sql
#  538  psql -U egpg -h localhost -f tests/datasets/users_patrons_100.sql evergreen
#  539  psql -U egpg -h localhost -f tests/datasets/users_staff_134.sql evergreen
#  540  cd tests/datasets/
#  541  perl ../../src/extras/import/marc2bre.pl --marctype XML --start 1 --idfield 901 --idsubfield a serials_marc21.xml | perl ../../src/extras/import/pg_loader.pl -or bre -or mrd -or mfr -or mtfe -or mafe -or msfe -or mkfe -or msefe -a mrd -a mfr -a mtfe -a mafe -a msfe -a mkfe -a msefe | psql -U egpg -h localhost evergreen
#  542  pgsql -f ../../src/extras/import/quick_metarecord_map.sql evergreen
#  543  psql -U egpg -f ../../src/extras/import/quick_metarecord_map.sql evergreen
#  544  perl ../../src/extras/import/marc2sre.pl --marctype XML --libmap serials_lib.map --password open-ils serials_mfhd.xml | perl ../../src/extras/import/pg_loader.pl -or sre > mfhd21.sql
#  545  psql -U egpg -f mfhd21.sql evergreen
#

rm -f catalog.bre catalog.marc catalog.marc.zip catalog.sql
wget -qs http://www.gutenberg.org/feeds/catalog.marc.zip >/dev/null
unzip catalog.marc.zip >/dev/null
# processes about 240 records per second
perl /openils/bin/marc2bre.pl \
    --db_user ${PGUSER} --db_host ${PGHOSTNAME} --db_pw $PGPASSWORD --db_name $PGDATABASE \
    catalog.marc > catalog.bre

# perl /usr/src/Evergreen/Open-ILS/src/extras/import/direct_ingest.pl catalog.bre > catalog.ingest
# perl /usr/src/Evergreen/Open-ILS/src/extras/import/pg_loader.pl -or bre -or mrd -or mfr -or mtfe -or mafe -or msfe -or mkfe -or msefe -a mrd -a mfr -a mtfe -a mafe -a msfe -a mkfe -a msefe >catalog.sql <catalog.bre
/etc/init.d/ejabberd restart
/etc/init.d/opensrf restart

# Need to split this into chunks
split --lines=2048 catalog.bre catalog_import_
for f in catalog_import_*
do
    perl \
        /usr/src/Evergreen/Open-ILS/src/extras/import/pg_loader.pl \
        -or bre -or mrd -or mfr -or mtfe -or mafe -or msfe -or mkfe -or msefe -a mrd -a mfr -a mtfe -a mafe -a msfe -a mkfe -a msefe \
        >catalog.sql <$f

    psql --command='\i catalog.sql'
    rm $f
done

psql --command='\i /usr/src/Evergreen/Open-ILS/src/extras/import/quick_metarecord_map.sql'
# psql -U postgres evergreen -c 'UPDATE biblio.record_entry SET source = 3; ';

# This will take many minutes
time psql --file ./sql/30-fill-call-copy.sql

# /etc/init.d/postgresql-9.1 stop
rm -f catalog.bre catalog.marc catalog.marc.zip catalog.sql