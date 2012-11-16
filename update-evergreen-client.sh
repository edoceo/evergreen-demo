#!/bin/bash -x
#
# @see http://open-ils.org/dokuwiki/doku.php?id=scratchpad:debug_console
# @see http://docs.evergreen-ils.org/1.6/draft/html/staffclientinstallation.html

set -o errexit

# https://developer.mozilla.org/en/xul_application_packaging
# The Documentation states:
# BUILD ID should be a unique build identifier, usually date based, and should be different for each released version
# VERSION should be in a format as described here:
# https://developer.mozilla.org/en/Toolkit_version_format

bd="/usr/src/Evergreen/Open-ILS/xul/staff_client"
hm=$(date +%H%M)

BUILD_ID=""
# Stamp is used to make the web-root
STAMP_ID="demo"
VERSION=$(date +%Y.%V)
#AUTOUPDATE_HOST=

function move_to_web()
{
    scpub_dir="/openils/var/web/staff-client"
    mkdir -p $scpub_dir

    d="$scpub_dir/evergreen-staff-client"
    if [ -n "${VERSION}" ]; then d="$d-${VERSION}" ; fi
    if [ -n "${STAMP_ID}" ]; then d="$d-${STAMP_ID}" ; fi
    if [ -n "${BUILD_ID}" ]; then d="$d-${BUILD_ID}" ; fi
    d="$d.exe"
    mv $bd/evergreen_staff_client_setup.exe "$d"

}


# Staff Client
# @see http://www.open-ils.org/dokuwiki/doku.php?id=mozilla-devel:building_the_staff_client
cd $bd/
# sed -i 's|!define PRODUCT_TAG.+|!define PRODUCT_TAG "Busby is Great"|' windowssetup.nsi
make clean >/dev/null
# make STAFF_CLIENT_BUILD_ID="demo" STAFF_CLIENT_STAMP_ID="demo" build
# make STAFF_CLIENT_BUILD_ID="demo" STAFF_CLIENT_STAMP_ID="demo" install
# make STAFF_CLIENT_BUILD_ID="demo" STAFF_CLIENT_STAMP_ID="demo" rigrelease
# make STAFF_CLIENT_BUILD_ID="demo" STAFF_CLIENT_STAMP_ID="demo" win-client

make \
    STAFF_CLIENT_BUILD_ID="$BUILD_ID" \
    STAFF_CLIENT_STAMP_ID="$STAMP_ID" \
    STAFF_CLIENT_VERSION="$VERSION" \
    build >/dev/null

make \
    STAFF_CLIENT_BUILD_ID="$BUILD_ID" \
    STAFF_CLIENT_STAMP_ID="$STAMP_ID" \
    STAFF_CLIENT_VERSION="$VERSION" \
    rigrelease >/dev/null

# Manually Create Linux Client
lc="linux-staff-client-32bit"
mkdir -p ./$lc/
pushd ./$lc/
rsync --archive --delete ../build/ ./staff-client/
curl http://ftp.mozilla.org/pub/mozilla.org/xulrunner/releases/14.0.1/runtimes/xulrunner-14.0.1.en-US.linux-i686.tar.bz2 | tar -xj
cat >evergreen.sh <<EOS
#!/bin/bash

cd \$(dirname \$0)

./xulrunner/xulrunner-bin \
    --app ./staff-client/application.ini --uilocale en-us
EOS
chmod 0755 evergreen.sh
popd
tar -zcf $lc.tgz ./$lc/
mv $lc.tgz /openils/var/web/staff-client

lc="linux-staff-client-64bit"
mkdir -p ./$lc/
pushd ./$lc/
curl http://ftp.mozilla.org/pub/mozilla.org/xulrunner/releases/14.0.1/runtimes/xulrunner-14.0.1.en-US.linux-x86_64.tar.bz2 | tar -xj
cat >evergreen.sh <<EOS
#!/bin/bash

cd \$(dirname \$0)

./xulrunner/xulrunner-bin \
    --app ./staff-client/application.ini --uilocale en-us
EOS
chmod 0755 evergreen.sh
popd
tar -zcf $lc.tgz ./$lc/
mv $lc.tgz /openils/var/web/staff-client
# wget http://ftp.mozilla.org/pub/mozilla.org/xulrunner/releases/16.0/runtimes/xulrunner-16.0.en-US.linux-x86_64.tar.bz2

# Puts to $(DESTDIR)$(WEBDIR)/xul/$(STAFF_CLIENT_STAMP_ID)
# make compress-javascript
# make AUTOUPDATE_HOST="$(hostname -f)" build win-client

make \
    STAFF_CLIENT_BUILD_ID="$BUILD_ID" \
    STAFF_CLIENT_STAMP_ID="$STAMP_ID" \
    STAFF_CLIENT_VERSION="$VERSION" \
    install >/dev/null

make \
    STAFF_CLIENT_BUILD_ID="$BUILD_ID" \
    STAFF_CLIENT_STAMP_ID="$STAMP_ID" \
    STAFF_CLIENT_VERSION="$VERSION" \
    rigrelease >/dev/null

make \
    STAFF_CLIENT_BUILD_ID="$BUILD_ID" \
    STAFF_CLIENT_STAMP_ID="$STAMP_ID" \
    STAFF_CLIENT_VERSION="$VERSION" \
    win-client >/dev/null

move_to_web

#
# Build a Debug Version
BUILD_ID="debug"
make clean >/dev/null
# This is necessary to get DOM Inspector and Venkman
make fetch-extensions >/dev/null
make \
    STAFF_CLIENT_BUILD_ID="$BUILD_ID" \
    STAFF_CLIENT_STAMP_ID="$STAMP_ID" \
    STAFF_CLIENT_VERSION="$VERSION" \
    devbuild >/dev/null

rsync --archive --delete ./build/ ./devbuild/
rsync --archive ./extensions/ ./devbuild/extensions/

make \
    STAFF_CLIENT_BUILD_ID="$BUILD_ID" \
    STAFF_CLIENT_STAMP_ID="$STAMP_ID" \
    STAFF_CLIENT_VERSION="$VERSION" \
    install >/dev/null

make \
    STAFF_CLIENT_BUILD_ID="$BUILD_ID" \
    STAFF_CLIENT_STAMP_ID="$STAMP_ID" \
    STAFF_CLIENT_VERSION="$VERSION" \
    rigrelease >/dev/null

make \
    STAFF_CLIENT_BUILD_ID="$BUILD_ID" \
    STAFF_CLIENT_STAMP_ID="$STAMP_ID" \
    STAFF_CLIENT_VERSION="$VERSION" \
    win-client >/dev/null

move_to_web

# ./Open-ILS/xul/staff_client/client/evergreen.exe
# ./Open-ILS/xul/staff_client/xulrunner-14.0.1.en-US.win32.zip
# ./Open-ILS/xul/staff_client/evergreen_staff_client_setup.exe


# xulrunner on arm
# apt-get install zip
# ./configure --prefix=/mnt/xul/xulrunner/
# rsync -av ./build /mnt/xul/staff-client/