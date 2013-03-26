#!/bin/bash -x
# @file
# @brief Updates the OpenSRF and Evergreen to git Master
# @see http://praxis.edoceo.com/howto/evergreen-ils
# @see http://www.open-ils.org/irc_logs/openils-evergreen/2009-09/%23openils-evergreen.23-Wed-2009.log#line390

# Tested OK on 2.2
# Tested OK on 2.4
# Tested OK on master

set -o errexit
set -o nounset

egd_root=$(dirname $(readlink -f $0))

. "$egd_root/update-env.sh"

# Stop Stack
/etc/init.d/apache2 stop
/etc/init.d/opensrf stop
/etc/init.d/ejabberd stop
/etc/init.d/memcached stop
/etc/init.d/postgresql-9.2 stop

# Update eJabberd
$egd_root/update-ejabberd.sh

# Run the Updates
$egd_root/update-opensrf.sh

$egd_root/update-evergreen.sh
cp $opensrf_source/src/extras/docgen.xsl /openils/var/web/opac/extras/docgen.xsl

# Update Database Stuff
$egd_root/update-postgresql.sh

$egd_root/update-evergreen-client.sh

#
#
/etc/init.d/postgresql-9.2 restart
/etc/init.d/memcached restart
/etc/init.d/ejabberd restart

#nano -w /openils/bin/osrf_ctl.sh
# sed -i 's|/bin/sh|/bin/sh -x|' /openils/bin/osrf_ctl.sh
# Yes, Twice, first time opensrf doesn't always start properly
/etc/init.d/opensrf restart
sleep 4

#
# Some Left Overs

# Autogen
chown -R opensrf:opensrf -R /openils/var/web/
su -l -c '/openils/bin/autogen.sh -u' opensrf

# Dojo
if [ ! -f /openils/var/web/js/dojo/dojo/dojo.js ]; then
    d=$(mktemp -d)
    cd $d
    wget http://download.dojotoolkit.org/release-1.3.2/dojo-release-1.3.2.tar.gz
    tar -zxf dojo-release-1.3.2.tar.gz
    cp -r dojo-release-1.3.2/* /openils/var/web/js/dojo/.
    cd -
fi

# Now Test OpenSRF Services
echo -en "request opensrf.math add 2 2\nquit\n" | su -c /openils/bin/srfsh opensrf

#
# Updates for Web-Server
$egd_root/update-apache.sh
/etc/init.d/apache2 restart

# /usr/src/Evergreen/Open-ILS/src/support-scripts/settings-tester.pl
$openils_source/Open-ILS/src/support-scripts/settings-tester.pl
# /etc/init.d/apache2 restart

#
# Add the Demo Data
# $egd_root/update-demodata.sh
