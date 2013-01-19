#!/bin/bash -x
# @file
# @brief Updates the ejabberd configuration
# Expects: dev-lang/erlang-15.2 net-im/ejabberd-2.1.10 net-im/jabber-base-0.01

# ----- /etc/jabber/ejabberd.cfg
# ----- sed -e 's/%.*//' -e 's/[ \t]*$//' -e '/^$/ d' /etc/jabber/ejabberd.cfg

#
# Update ejabberd config
cat > /etc/jabber/ejabberd.cfg <<EOC
{loglevel, 3}.
{hosts, ["localhost", "private.localhost", "public.localhost"]}.
{listen, [
    {5222, ejabberd_c2s, [
        {access, c2s},
		{shaper, c2s_shaper},
		{max_stanza_size, 2000000}
    ]},
    {5269, ejabberd_s2s_in, [
		{shaper, s2s_shaper},
		{max_stanza_size, 2000000}
    ]},
    {5280, ejabberd_http, [
        captcha,
		http_bind,
		http_poll,
		web_admin
    ]}
]}.
{auth_method, internal}.
{shaper, normal, {maxrate, 500000}}.
{shaper, fast, {maxrate, 500000}}.
{max_fsm_queue, 1000}.
{acl, admin, {user,"ejabberd","localhost"}}.
{acl, local, {user_regexp, ""}}.
{access, max_user_sessions, [{10000, all}]}.
{access, max_user_offline_messages, [{5000, admin}, {100, all}]}.
{access, local, [{allow, local}]}.
{access, c2s, [{deny, blocked}, {allow, all}]}.
{access, c2s_shaper, [{none, admin}, {normal, all}]}.
{access, s2s_shaper, [{fast, all}]}.
{access, announce, [{allow, admin}]}.
{access, configure, [{allow, admin}]}.
{access, muc_admin, [{allow, admin}]}.
{access, muc_create, [{allow, local}]}.
{access, muc, [{allow, all}]}.
{access, pubsub_createnode, [{allow, local}]}.
{access, register, [{allow, all}]}.
{language, "en"}.
{modules, [
    {mod_adhoc,    []},
    {mod_announce, [{access, announce}]},
    {mod_blocking,[]},
    {mod_caps,     []},
    {mod_configure,[]},
%%    {mod_disco,    []},
    {mod_irc,      []},
%%    {mod_http_bind, []},
    {mod_last,     []},
    {mod_muc,      [
        {access, muc},
        {access_create, muc_create},
        {access_persistent, muc_create},
        {access_admin, muc_admin}
    ]},
    {mod_ping,     []},
    {mod_privacy,  []},
    {mod_private,  []},
    {mod_pubsub,   [
        {access_createnode, pubsub_createnode},
        {ignore_pep_from_offline, true},
        {last_item_cache, false},
        {plugins, ["flat", "hometree", "pep"]}
    ]},
    {mod_register, [
        {welcome_message, {"Welcome!", "Hi.\nWelcome to this XMPP server."}},
        {ip_access, [{allow, "127.0.0.0/8"}, {deny, "0.0.0.0/0"}]},
        {access, register}
    ]},
%%    {mod_roster,   []},
%%    {mod_shared_roster,[]},
%%    {mod_stats,    []},
%%    {mod_time,     []},
%%    {mod_vcard,    []},
    {mod_version,  []}
]}.
EOC

#
# Update /etc/hosts
grep 'public.localhost' /etc/hosts || echo "127.0.0.1 public.localhost public" >> /etc/hosts
grep 'private.localhost' /etc/hosts || echo "127.0.0.1 private.localhost private" >> /etc/hosts

/etc/init.d/ejabberd stop
kill -INT $(pidof epmd)
/etc/init.d/ejabberd zap
/etc/init.d/ejabberd start
sleep 16

#
# register $location $host $user (we set password to "password")
ejabberdctl register router private.localhost password
ejabberdctl register opensrf private.localhost password
ejabberdctl register router public.localhost password
ejabberdctl register opensrf public.localhost password

echo " *"
echo " * eJabber Configured and Runing"
echo " * Should see listeners on 5222 (xmpp-client), 5280 (xmpp-server) "
echo " *"

netstat -tanpu | grep beam
