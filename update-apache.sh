#!/bin/bash -x
# @brief Update the Apache Configurations

#
# completely destroys existing Apache configuration
d=$(dirname $(readlink -f $0 ))

# cp "$d/etc/apache2.conf" /etc/apache2/apache2.conf

wget http://download.dojotoolkit.org/release-1.3.3/dojo-release-1.3.3.tar.gz
tar -C /openils/var/web/js -xzf dojo-release-1.3.3.tar.gz
cp -r /openils/var/web/js/dojo-release-1.3.3/* /openils/var/web/js/dojo/.
rm dojo-release-1.3.3.tar.gz

# What's differnce between -u and without?
su -c 'env PATH="/openils/bin:/bin:/usr/bin" autogen.sh' opensrf || ( echo "Autogen Failed" && exit 1)
# su -c 'env PATH="/openils/bin:/bin:/usr/bin" autogen.sh -u' opensrf

# touch /openils/var/web/xul/demo/server/locale/en-US/auth_custom.properties
# touch /openils/var/web/xul/demo/server/locale/en-US/common_custom.properties
# touch /openils/var/web/xul/demo/server/locale/en-US/offline_custom.properties
# touch /openils/var/web/xul/versions.html

exit 0
