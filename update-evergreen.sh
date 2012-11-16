#!/bin/bash -x

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
        # make clean
    else
        git clone git://git.evergreen-ils.org/Evergreen.git
        cd ./Evergreen
        git checkout $openils_branch
    fi

    chown -R opensrf:opensrf .

    su -c 'make clean' opensrf >/dev/null

    su -c 'autoreconf -i' opensrf >/dev/null

    su -c './configure --prefix=/openils --disable-python --with-apache \
        --with-apr=/usr/include/apr-1.0 --with-apxs=/usr/sbin/apxs2 --with-libxml2=/usr/include/libxml2 \
        --with-opensrf-headers=/openils/include --with-opensrf-libs=/openils/lib' opensrf >/dev/null

    su -c 'make' opensrf >/dev/null

    # make install >/dev/null
    make install-strip >/dev/null
    rm -fr /openils/conf/*example

    cd /openils
    # is ./etc or ./conf the authortative name?
    if [ ! -e conf ];
    then
        ln -s etc conf
    fi

}
update_openils

#
#
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
chown -R opensrf:opensrf /openils/var/web
