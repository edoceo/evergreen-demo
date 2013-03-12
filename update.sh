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
if [ -x /etc/init.d/postgresql-9.1 ]
then 
    /etc/init.d/postgresql-9.1 stop
fi
if [ -x /etc/init.d/postgresql-9.2 ]
then 
    /etc/init.d/postgresql-9.2 stop
fi

# Run the Updates
$egd_root/update-opensrf.sh
$egd_root/update-evergreen.sh
cp $opensrf_source/src/extras/docgen.xsl /openils/var/web/opac/extras/docgen.xsl

$egd_root/update-evergreen-client.sh

#
# Some Left Overs

# Autogen
su -l -c '/openils/bin/autogen.sh -u' opensrf

# Dojo
if [ ! -f /openils/var/web/js/dojo/dojo/dojo.js ]; then
    d=$(mktemp -d)
    cd $d
    wget http://download.dojotoolkit.org/release-1.3.2/dojo-release-1.3.2.tar.gz
    tar -zxf dojo-release-1.3.2.tar.gz
    cp -r dojo-release-1.3.2/* /openils/var/web/js/dojo/.
    cd -
if

# Update Database Stuff
$egd_root/update-postgresql.sh
if [ -x /etc/init.d/postgresql-9.1 ]
then 
    /etc/init.d/postgresql-9.1 restart
fi
if [ -x /etc/init.d/postgresql-9.2 ]
then 
    /etc/init.d/postgresql-9.2 restart
fi

# Update eJabberd
$egd_root/update-ejabberd.sh
/etc/init.d/memcached restart
/etc/init.d/ejabberd restart

#echo "Now you should edit /openils/bin/osrf_ctl.sh"
# This ugly hack, to make full paths for the openils libs?
sed -i 's|loglevel>\([0-9]\)</loglevel|loglevel>1</loglevel|' /openils/etc/opensrf_core.xml
sed -i 's|logfile>.+</logfile|logfile>syslog</logfile|' /openils/etc/opensrf_core.xml

# turn everything down
sed -i 's|ion>\(o.*.so\)</imp|ion>/openils/lib/\1</imp|' /openils/etc/opensrf.xml
sed -i 's|<min_children>[0-9]*</min_children>|<min_children>1</min_children>|' /openils/etc/opensrf.xml
sed -i 's|<max_children>[0-9]*</max_children>|<max_children>8</max_children>|' /openils/etc/opensrf.xml
sed -i 's|<min_spare_children>[0-9]*</min_spare_children>|<min_spare_children>1</min_spare_children>|' /openils/etc/opensrf.xml
sed -i 's|<max_spare_children>[0-9]*</max_spare_children>|<max_spare_children>4</max_spare_children>|' /openils/etc/opensrf.xml

#nano -w /openils/bin/osrf_ctl.sh
# sed -i 's|/bin/sh|/bin/sh -x|' /openils/bin/osrf_ctl.sh
# Yes, Twice, first time opensrf doesn't always start properly
/etc/init.d/opensrf restart
sleep 4

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
