#!/bin/bash
# @file
# @brief Build a Custom Dojo to make it faster
#

wget http://download.dojotoolkit.org/release-1.3.3/dojo-release-1.3.3-src.tar.gz
tar -zxf dojo-release-1.3.3-src.tar.gz
rm -fr dojo-release-1.3.3-src.tar.gz

cd dojo-release-1.3.3-src/util/buildscripts

cp /usr/src/Evergreen/Open-ILS/examples/openils.profile.js ./profiles
./build.sh profile=openils action=release version=1.3.3 cssOptimize=comments mini=true stripConsole=all