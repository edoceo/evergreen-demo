#!/bin/bash -x
# @file
# @brief Updates the OpenSRF and Evergreen to git Master
# @see http://praxis.edoceo.com/howto/evergreen-ils
# @see http://www.open-ils.org/irc_logs/openils-evergreen/2009-09/%23openils-evergreen.23-Wed-2009.log#line390

set -o errexit
set -o nounset

egd_root=$(dirname $(readlink -f $0))

openils_branch="master"
# remotes/origin/tags/rel_2_3_0 is the one true 2.3.0 code.
# openils_branch="remotes/origin/tags/rel_2_3_0"
# remotes/origin/rel_2_3 is 2.3.0 plus post-release fixes
# openils_branch="remotes/origin/rel_2_3"

# Stop Stack
/etc/init.d/apache2 stop
/etc/init.d/opensrf stop
/etc/init.d/ejabberd stop
/etc/init.d/memcached stop
/etc/init.d/postgresql-9.1 stop

export PGUSER="egpg"
export PGPASSWORD="egpg"
export PGHOSTNAME="localhost"
export PGDATABASE="evergreen"

export EGUSER="egsa"
export EGPASSWORD="egsa"

$egd_root/update-opensrf.sh
$egd_root/update-evergreen.sh
$egd_root/update-evergreen-client.sh

# Update Database Stuff
/opt/edoceo/egd/update-postgresql.sh
/etc/init.d/postgresql-9.1 restart

# Update eJabberd
/opt/edoceo/egd/update-ejabberd.sh
/etc/init.d/memcached restart
/etc/init.d/ejabberd restart

#echo "Now you should edit /openils/bin/osrf_ctl.sh"
# This ugly hack, to make full paths for the openils libs?
sed -i 's|ion>\(o.*.so\)</imp|ion>/openils/lib/\1</imp|' /openils/etc/opensrf.xml
sed -i 's|loglevel>\([0-9]\)</loglevel|loglevel>1</loglevel|' /openils/etc/opensrf_core.xml
sed -i 's|logfile>.+</logfile|logfile>syslog</logfile|' /openils/etc/opensrf_core.xml

#nano -w /openils/bin/osrf_ctl.sh
sed -i 's|/bin/sh|/bin/sh -x|' /openils/bin/osrf_ctl.sh
/etc/init.d/opensrf restart || true
/etc/init.d/opensrf restart
sleep 4

# Now Test OpenSRF Services
echo -en "request opensrf.math add 2 2\nquit\n" | su -c /openils/bin/srfsh opensrf

#
# Updates for Web-Server
/opt/edoceo/egd/update-apache.sh
/etc/init.d/apache2 restart

/usr/src/Evergreen/Open-ILS/src/support-scripts/settings-tester.pl
# /etc/init.d/apache2 restart

echo
echo "You should now manually run the settings tester!"
echo "  /usr/src/Evergreen/Open-ILS/src/support-scripts/settings-tester.pl"
echo
echo "On Gentoo you can ignore warnings about libdbdpgsql.so (provided you see it below)"
locate libdbdpgsql.so
echo
