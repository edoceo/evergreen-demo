#!/bin/bash -x
#
# Build the Evergreen Server

set -o errexit

if [ -z "${openils_branch}" ]; then
    echo "I Need openils_branch to be set"
    exit 1
fi

if [ -z "${openils_source}" ]; then
    echo "I Need openils_source to be set"
    exit 1
fi

#
# Evergreen
function update_openils()
{
    if [ -d "$openils_source" ]; then
        cd "$openils_source"
        git checkout master
        git pull
        git checkout $openils_branch
        # make clean
    else
        git clone git://git.evergreen-ils.org/Evergreen.git "$openils_source"
        cd "$openils_source"
        git checkout $openils_branch
    fi

    cd "$openils_source"
    chown -R opensrf:opensrf .

    su -c 'PATH="/openils/bin:/usr/bin:/bin" make clean' opensrf >/dev/null || true
    su -c 'PATH="/openils/bin:/usr/bin:/bin" autoreconf -i' opensrf >/dev/null

    su -c 'PATH="/openils/bin:/usr/bin:/bin" ./configure --prefix=/openils --disable-python \
        --with-apxs=/usr/sbin/apxs2 --with-libxml2=/usr/include/libxml2 \
        --with-opensrf-headers=/openils/include --with-opensrf-libs=/openils/lib' opensrf >/dev/null

    su -c 'make' opensrf >/dev/null

    # make install >/dev/null
    make install-strip >/dev/null

    cd /openils
    # is ./etc or ./conf the authortative name?
    if [ ! -e conf ];
    then
        ln -s etc conf
    fi

    cd ./etc
    for f in *.example
    do
        mv $f "${f%%.example}"
    done

}
update_openils

#echo "Now you should edit /openils/bin/osrf_ctl.sh"
# mv /openils/etc/opensrf_core.xml.example /openils/etc/opensrf_core.xml
sed -i 's|loglevel>\([0-9]\)</loglevel|loglevel>1</loglevel|' /openils/etc/opensrf_core.xml
sed -i 's|logfile>.+</logfile|logfile>syslog</logfile|' /openils/etc/opensrf_core.xml

# turn everything down
# mv /openils/etc/opensrf.xml.example /openils/etc/opensrf.xml
# This ugly hack, to make full paths for the openils libs?
sed -i 's|ion>\(o.*.so\)</imp|ion>/openils/lib/\1</imp|' /openils/etc/opensrf.xml
sed -i 's|<min_children>[0-9]*</min_children>|<min_children>1</min_children>|' /openils/etc/opensrf.xml
sed -i 's|<max_children>[0-9]*</max_children>|<max_children>8</max_children>|' /openils/etc/opensrf.xml
sed -i 's|<min_spare_children>[0-9]*</min_spare_children>|<min_spare_children>1</min_spare_children>|' /openils/etc/opensrf.xml
sed -i 's|<max_spare_children>[0-9]*</max_spare_children>|<max_spare_children>4</max_spare_children>|' /openils/etc/opensrf.xml

#    !  RPC::XML::Function is not installed
#    !  RPC::XML::Method is not installed


#
#
cpan Template::Plugin::POSIX
cpan Business::CreditCard::Object
cpan Net::Z3950::SimpleServer
cpan Net::Z3950::Simple2ZOOM

# Update FS Permissions
chown -R opensrf:opensrf /openils/var/log
chown -R opensrf:opensrf /openils/var/run
