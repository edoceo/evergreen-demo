#!/bin/bash -x
# @file
# @brief Updates the OpenSRF and Evergreen to git Master
# @see http://praxis.edoceo.com/howto/evergreen-ils
# @see http://www.open-ils.org/irc_logs/openils-evergreen/2009-09/%23openils-evergreen.23-Wed-2009.log#line390

set -o errexit

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
    su -c 'make clean' opensrf >/dev/null
    su -c 'autoreconf -i' opensrf >/dev/null
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
    grep LoadModule /etc/apache2/apache2.conf || echo -en "#A placeholder\nLoadModule placeholder modules/mod_placeholder.so" >> /etc/apache2/apache2.conf

    make install-strip >/dev/null

    # cp /usr/src/OpenSRF/src/extras/docgen.xsl /openils/var/web/opac/extras/docgen.xsl

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
