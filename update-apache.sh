#!/bin/bash
# @brief Update the Apache Configurations

#
# completely destroys existing Apache configuration
function update_apache()
{
    cat > /etc/apache2/httpd.conf <<EOC
DocumentRoot "/openils/var/web"
User opensrf
Group opensrf

Listen 80
Listen 443

LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
CustomLog /var/log/apache2/access.log combined
ErrorLog /var/log/apache2/error.log
PidFile /var/run/apache2.pid

# Apache Modules
LoadModule alias_module modules/mod_alias.so
LoadModule autoindex_module modules/mod_autoindex.so
LoadModule include_module modules/mod_include.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule mime_module modules/mod_mime.so
LoadModule perl_module modules/mod_perl.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule setenvif_module modules/mod_setenvif.so
LoadModule ssl_module modules/mod_ssl.so

# Evergreen / OpenSRF Modules
LoadModule xmlent_module               modules/mod_xmlent.so
LoadModule idlchunk_module             modules/mod_idlchunk.so
LoadModule osrf_json_gateway_module    modules/osrf_json_gateway.so
LoadModule osrf_http_translator_module modules/osrf_http_translator.so

AliasMatch ^/opac/.*/skin/(.*)/(.*)/(.*) /openils/var/web/opac/skin/\$1/\$2/\$3
AliasMatch ^/opac/.*/extras/slimpac/(.*) /openils/var/web/opac/extras/slimpac/\$1
AliasMatch ^/opac/.*/extras/selfcheck/(.*) /openils/var/web/opac/extras/selfcheck/\$1

DefaultType text/plain
TypesConfig /etc/mime.types

#
# Staff Client downloads go here
<Directory /openils/var/web/pub/>
    Options +Indexes
    IndexOptions +FancyIndexing +NameWidth=* +SuppressDescription +VersionSort
</Directory>

<VirtualHost *:80>
    # ServerName evergreen-demo
    DocumentRoot /openils/var/web/
    # DirectoryIndex index.xml index.html index.xhtml
    ## - absorb the shared virtual host settings
    # Include /etc/apache2/eg_vhost.conf
    RewriteEngine On
    RewriteRule (.*) https://%{http_host}$1 [l,r=301]
</VirtualHost>

<VirtualHost *:443>

    DocumentRoot /openils/var/web

	SSLEngine on
	# SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL

    # If you don't have an SSL cert, you can create self-signed
    # certificate and key with:
    # openssl req -new -x509 -nodes -out server.crt -keyout server.key
	SSLCertificateFile /etc/apache2/ssl/server.crt
	SSLCertificateKeyFile /etc/apache2/ssl/server.key
    SetEnvIf User-Agent ".*MSIE [6-9].*" ssl-unclean-shutdown

    # root redirect
    RedirectMatch 301 ^/$ /opac/en-US/skin/default/xml/index.xml
    <LocationMatch ^/$>
        Options +ExecCGI
        SetHandler perl-script
        PerlHandler OpenILS::WWW::Redirect
        PerlSendHeader On
        PerlSetVar OILSRedirectTpac "true"
    </LocationMatch>

    # Offline Importer Tool
    Alias /cgi-bin/offline/ "/openils/var/cgi-bin/offline/"
    <Directory "/openils/var/cgi-bin/offline">
        AddHandler cgi-script .cgi .pl
        AllowOverride None
        Options None
        Options FollowSymLinks ExecCGI Indexes
    </Directory>

    RedirectMatch 301 ^/opac/extras/slimpac/start.html$    /opac/en-US/extras/slimpac/start.html
    RedirectMatch 301 ^/opac/extras/slimpac/advanced.html$ /opac/en-US/extras/slimpac/advanced.html

    OSRFGatewayConfig /openils/conf/opensrf_core.xml

    <LocationMatch /opac/>
        AddType application/xhtml+xml .xml

        # - configure mod_xmlent
        XMLEntStripPI "yes"
        XMLEntEscapeScript "no"
        XMLEntStripComments "yes"
        XMLEntContentType "text/html; charset=utf-8"
        # forces quirks mode which we want for now
        XMLEntStripDoctype "yes"

        # - set up the include handlers
        Options +Includes
        AddOutputFilter INCLUDES .xsl
        AddOutputFilter INCLUDES;XMLENT .xml

        SetEnvIf Request_URI ".*" OILS_OPAC_BASE=/opac/

        # This gives you the option to configure a different host to serve OPAC images from
        # Specify the hostname (without protocol) and path to the images.  Protocol will
        # be determined at runtime
        #SetEnvIf Request_URI ".*" OILS_OPAC_IMAGES_HOST=static.example.org/opac/

        # In addition to loading images from a static host, you can also load CSS and/or
        # Javascript from a static host or hosts. Protocol will be determined at runtime
        # and/or by configuration options immediately following.
        #SetEnvIf Request_URI ".*" OILS_OPAC_CSS_HOST=static.example.org/opac/
        #SetEnvIf Request_URI ".*" OILS_OPAC_JS_HOST=static.example.org/opac/

        # If you are not able to serve static content via https and
        # wish to force http:// (and are comfortable with mixed-content
        # warnings in client browsers), set this:
        #SetEnvIf Request_URI ".*" OILS_OPAC_STATIC_PROTOCOL=http

        # If you would prefer to fall back to your non-static servers for
        # https pages, avoiding mixed-content warnings in client browsers
        # and are willing to accept some increased server load, set this:
        #SetEnvIf Request_URI ".*" OILS_OPAC_BYPASS_STATIC_FOR_HTTPS=yes

        # Specify a ChiliFresh account to integrate their services with the OPAC
        #SetEnv OILS_CHILIFRESH_ACCOUNT
        #SetEnv OILS_CHILIFRESH_PROFILE
        #SetEnv OILS_CHILIFRESH_URL http://chilifresh.com/on-site/js/evergreen.js
        #SetEnv OILS_CHILIFRESH_HTTPS_URL https://secure.chilifresh.com/on-site/js/evergreen.js

        # Specify the initial script URL for Novelist (containing account credentials, etc.)
        #SetEnv OILS_NOVELIST_URL
        #

        # Uncomment to force SSL any time a patron is logged in.  This protects
        # authentication tokens.  Left commented out for backwards compat for now.
        #SetEnv OILS_OPAC_FORCE_LOGIN_SSL 1

        # If set, the skin uses the combined JS file at \$SKINDIR/js/combined.js
        #SetEnv OILS_OPAC_COMBINED_JS 1

    </LocationMatch>

    <Location /opac/>
        # ----------------------------------------------------------------------------------
        # Some mod_deflate fun
        # ----------------------------------------------------------------------------------
        <IfModule mod_deflate.c>
            SetOutputFilter DEFLATE

            BrowserMatch ^Mozilla/4 gzip-only-text/html
            BrowserMatch ^Mozilla/4\.0[678] no-gzip
            BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html

            SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary

            <IfModule mod_headers.c>
                Header append Vary User-Agent env=!dont-vary
            </IfModule>
        </IfModule>

    </Location>

    <Location /osrf-gateway-v1>
        SetHandler osrf_json_gateway_module
        OSRFGatewayLegacyJSON "false"
        # Allow from all
    </Location>

    <Location /osrf-http-translator>
        SetHandler osrf_http_translator_module
        # allow from all
    </Location>

</VirtualHost>

EOC

}
update_apache

wget http://download.dojotoolkit.org/release-1.3.3/dojo-release-1.3.3.tar.gz
tar -C /openils/var/web/js -xzf dojo-release-1.3.3.tar.gz
cp -r /openils/var/web/js/dojo-release-1.3.3/* /openils/var/web/js/dojo/.
rm dojo-release-1.3.3.tar.gz

# What's differnce between -u and without?
su -c 'env PATH="/openils/bin:/bin:/usr/bin" autogen.sh' opensrf
# su -c 'env PATH="/openils/bin:/bin:/usr/bin" autogen.sh -u' opensrf

