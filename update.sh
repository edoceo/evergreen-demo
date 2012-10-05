#!/bin/bash -x
# @file
# @brief Updates the OpenSRF and Evergreen to git Master
# @see http://praxis.edoceo.com/howto/evergreen-ils
# @see http://www.open-ils.org/irc_logs/openils-evergreen/2009-09/%23openils-evergreen.23-Wed-2009.log#line390

set -o errexit

opensrf_branch="master"
# opensrf_branch="remotes/origin/rel_2_1"

openils_branch="master"
# openils_branch="remotes/origin/tags/rel_2_3_beta2"

# Stop Stack
/etc/init.d/apache2 stop
/etc/init.d/ejabberd stop
/etc/init.d/evergreen stop
/etc/init.d/memcached stop
/etc/init.d/postgresql-9.1 stop

#
# OpenSRF
function update_opensrf()
{
    cd /usr/src

    # git update
    if [ -d OpenSRF ]
    then
        cd ./OpenSRF
        git checkout master
        git pull
        git checkout $opensrf_branch
    else
        git clone git://git.evergreen-ils.org/OpenSRF.git
        cd ./OpenSRF
        git checkout $opensrf_branch
    fi

    chown -R opensrf:opensrf .

    su -c 'autoreconf -i' opensrf
    su -c './configure --prefix=/openils && make' opensrf >/dev/null

    # Prevent:
    ## apxs:Error: Config file /etc/apache2/apache2.conf not found.
    ## make[3]: *** [install-exec-local] Error 1
    ## make[3]: Leaving directory `/usr/src/OpenSRF/src/gateway'
    ## make[2]: *** [install-am] Error 2
    ## make[2]: Leaving directory `/usr/src/OpenSRF/src/gateway'
    ## make[1]: *** [install-recursive] Error 1
    ## make[1]: Leaving directory `/usr/src/OpenSRF/src'
    ## make: *** [install-recursive] Error 1
    touch /etc/apache2/apache2.conf

    make install >/dev/null

    # todo copy from working system
##     cat > /openils/conf/opensrf.xml <<EOX
##
## EOX
##
##     # Update this File Too
##     cat > /openils/conf/opensrf_core.xml <<EOX
##
##
## EOX

}
#update_opensrf

#
# Evergreen
function update_openils()
{
    cd /usr/src

    if [ -d Evergreen ]; then
        cd ./Evergreen
        git checkout master
        git pull
        git checkout $openils_branch
        make clean
    else
        git clone git://git.evergreen-ils.org/Evergreen.git
        cd ./Evergreen
        git checkout $openils_branch
    fi

    chown -R opensrf:opensrf .

    su -c 'autoreconf -i' opensrf

    su -c './configure --prefix=/openils --disable-python --with-apache \
        --with-apr=/usr/include/apr-1.0 --with-apxs=/usr/sbin/apxs2 --with-libxml2=/usr/include/libxml2 \
        --with-opensrf-headers=/openils/include --with-opensrf-libs=/openils/lib' opensrf >/dev/null

    su -c 'make' opensrf >/dev/null

    make install >/dev/null

    # Staff Client
    pushd Open-ILS/xul/staff_client/
    make STAFF_CLIENT_STAMP_ID="demo" build
    make STAFF_CLIENT_STAMP_ID="demo" install
    make STAFF_CLIENT_STAMP_ID="demo" rigrelease
    make STAFF_CLIENT_STAMP_ID="demo" rebuild
    make STAFF_CLIENT_STAMP_ID="demo" win-client
    popd

    # ./Open-ILS/xul/staff_client/client/evergreen.exe
    # ./Open-ILS/xul/staff_client/xulrunner-14.0.1.en-US.win32.zip
    # ./Open-ILS/xul/staff_client/evergreen_staff_client_setup.exe

    cp /openils/etc/opensrf.xml.example /openils/etc/opensrf.xml
    cp /openils/etc/opensrf_core.xml.example /openils/etc/opensrf_core.xml

    cd /openils
    ln -s etc conf


}
# update_openils

# Update Permissions
chown -R opensrf:opensrf /openils/var/log
chown -R opensrf:opensrf /openils/var/run
chown -R opensrf:opensrf /openils/var/web

# /opt/edoceo/update-database.sh
# /opt/edoceo/update-ejabberd.sh
# /opt/edoceo/update-apache.sh

/etc/init.d/memcached restart
/etc/init.d/evergreen restart
sleep 8

# Now Test OpenSRF Services
su -c 'srfsh request opensrf.math add 2,2' opensrf

wget http://download.dojotoolkit.org/release-1.3.3/dojo-release-1.3.3.tar.gz
tar -C /openils/var/web/js -xzf dojo-release-1.3.3.tar.gz
cp -r /openils/var/web/js/dojo-release-1.3.3/* /openils/var/web/js/dojo/.
rm dojo-release-1.3.3.tar.gz

su -c 'env PATH="/openils/bin:/bin:/usr/bin" autogen.sh -u' opensrf

# /usr/src/Evergreen/Open-ILS/src/support-scripts/settings-tester.pl
/etc/init.d/apache2 restart

echo
echo "You should now manually run the settings tester!"
echo "  /usr/src/Evergreen/Open-ILS/src/support-scripts/settings-tester.pl"
echo
echo "On Gentoo you can ignore warnings about libdbdpgsql.so (provided you see it below)"
locate libdbdpgsql.so
echo
