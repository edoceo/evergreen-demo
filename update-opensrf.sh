#!/bin/bash -x
# @file
# @brief Updates the OpenSRF and Evergreen to git Master
# @see http://praxis.edoceo.com/howto/evergreen-ils
# @see http://www.open-ils.org/irc_logs/openils-evergreen/2009-09/%23openils-evergreen.23-Wed-2009.log#line390

set -o errexit

if [ -z "${opensrf_branch}" ]; then
    echo "I Need opensrf_branch to be set"
    exit 1
fi

if [ -z "${opensrf_source}" ]; then
    echo "I Need opensrf_source to be set"
    exit 1
fi


# OpenSRF
function update_opensrf()
{
    rm -fr

    # git update
    if [ -d $opensrf_source ]
    then
        cd $opensrf_source
        git checkout master
        git pull --rebase
        git checkout $opensrf_branch
    else
        git clone git://git.evergreen-ils.org/OpenSRF.git $opensrf_source
        cd $opensrf_source
        git checkout $opensrf_branch
    fi

    # chown -R opensrf:opensrf .
    # su -c 'cd /usr/src/OpenSRF && make clean' opensrf >/dev/null
    # su -c 'cd /usr/src/OpenSRF && autoreconf -i' opensrf >/dev/null
    # su -c 'cd /usr/src/OpenSRF && ./configure --prefix=/openils && make' opensrf >/dev/null
    autoreconf -i
    ./configure --prefix=/openils
    make

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
    grep LoadModule /etc/apache2/apache2.conf || echo -en "#A placeholder\nLoadModule placeholder modules/mod_placeholder.so" >> /etc/apache2/apache2.conf

    make install-strip >/dev/null

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
update_opensrf

#echo "Now you should edit /openils/bin/osrf_ctl.sh"
mv /openils/etc/opensrf_core.xml.example /openils/etc/opensrf_core.xml
sed -i 's|loglevel>\([0-9]\)</loglevel|loglevel>1</loglevel|' /openils/etc/opensrf_core.xml
sed -i 's|logfile>.+</logfile|logfile>syslog</logfile|' /openils/etc/opensrf_core.xml

# turn everything down
mv /openils/etc/opensrf.xml.example /openils/etc/opensrf.xml
# This ugly hack, to make full paths for the openils libs?
sed -i 's|ion>\(o.*.so\)</imp|ion>/openils/lib/\1</imp|' /openils/etc/opensrf.xml
sed -i 's|<min_children>[0-9]*</min_children>|<min_children>1</min_children>|' /openils/etc/opensrf.xml
sed -i 's|<max_children>[0-9]*</max_children>|<max_children>8</max_children>|' /openils/etc/opensrf.xml
sed -i 's|<min_spare_children>[0-9]*</min_spare_children>|<min_spare_children>1</min_spare_children>|' /openils/etc/opensrf.xml
sed -i 's|<max_spare_children>[0-9]*</max_spare_children>|<max_spare_children>4</max_spare_children>|' /openils/etc/opensrf.xml


