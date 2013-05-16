#!/bin/bash -x

# @see http://openlibrary.org/developers/dumps

set -o errexit

if [ -z "${openils_source}" ]; then
    echo "I Need openils_source to be set"
    exit 1
fi

if [ -z "${PGUSER}" ]; then
    exit "I Need PGUSER to be set"
fi

# Load all the Evergreen Sample Data
cd "$openils_source/Open-ILS/tests/datasets/sql/"
if [ -f load_all.sql ]
then
    psql --quiet --set=ON_ERROR_STOP --file load_all.sql
fi
cd -

psql --quiet --set=ON_ERROR_STOP --file ./sql/01-init.sql >/dev/null
psql --quiet --set=ON_ERROR_STOP --file ./sql/05-demo-user.sql >/dev/null
psql --quiet --set=ON_ERROR_STOP --file ./sql/06-patrons.sql >/dev/null
# psql --quiet --set=ON_ERROR_STOP --file ./sql/10-import.sql >/dev/null

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

# 42300 records,
# processes about 240 records per second, takes about 3 minutes
rm -f catalog.bre catalog.marc catalog.marc.zip catalog.sql catalog_import_*
wget -q http://www.gutenberg.org/feeds/catalog.marc.zip >/dev/null
unzip catalog.marc.zip >/dev/null
perl /openils/bin/marc2bre.pl \
    --db_user ${PGUSER} --db_host ${PGHOST} --db_pw $PGPASSWORD --db_name $PGDATABASE \
    catalog.marc > catalog.bre

# Don't do this now
# perl /usr/src/Evergreen/Open-ILS/src/extras/import/direct_ingest.pl catalog.bre > catalog.ingest
# perl /usr/src/Evergreen/Open-ILS/src/extras/import/pg_loader.pl -or bre -or mrd -or mfr -or mtfe -or mafe -or msfe -or mkfe -or msefe -a mrd -a mfr -a mtfe -a mafe -a msfe -a mkfe -a msefe >catalog.sql <catalog.bre

# Split into chunks for importing
# Each Iteration takes about 5 minutes - 6.8 records per second
# Gutenberg takes from 2:54 to 5:45 - so ~3 hours
split --lines=2048 catalog.bre catalog_import_
for f in catalog_import_*
do
    perl \
        $openils_source/Open-ILS/src/extras/import/pg_loader.pl \
        -or bre -or mrd -or mfr -or mtfe -or mafe -or msfe -or mkfe -or msefe -a mrd -a mfr -a mtfe -a mafe -a msfe -a mkfe -a msefe \
        >catalog.sql <$f

    psql --command='\i catalog.sql'
    rm $f
done
rm -f catalog.bre catalog.marc catalog.marc.zip catalog.sql

# Update Maps
psql --command="\\i $openils_source/Open-ILS/src/extras/import/quick_metarecord_map.sql"

# Set Gutenberg Source
# psql -U postgres evergreen -c 'UPDATE biblio.record_entry SET source = 3; ';

# This will take many minutes
time psql --file ./sql/30-fill-call-copy.sql
