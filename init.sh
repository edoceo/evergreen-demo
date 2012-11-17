#!/sbin/runscript
#
# Evergreen OpenSRF init script for Gentoo GNU/Linux

OPENILS_PATH="/openils"
OPENSRF_USER="opensrf"

function depend()
{
    need net
	use jabber-server logger postgresql
	provide openils
}

function start()
{

	ebegin "Starting OpenSRF"

	local ret

	start-stop-daemon --start \
		--env "PATH=/openils/bin:/bin:/usr/bin" \
		--user opensrf \
		--exec '/openils/bin/osrf_ctl.sh' \
		-- -l -a start_all

	ret=$?
    echo " osrf_ctl returned: $ret "

	# if [[ $ret != 0 ]] ; then
	# 	eend $ret
	# 	return $ret
	# fi

	# local pid=$(grep "^[0-9]\+" "$PGDATA/postmaster.pid")
	# ps -p "${pid}" &> /dev/null
	eend $?
}

function stop()
{

    ebegin "Stopping Evergreen ILS"

    local ret

	start-stop-daemon --start \
		--env "PATH=/openils/bin:/bin:/usr/bin" \
		--user opensrf \
		--exec '/openils/bin/osrf_ctl.sh' \
		-- -l -a stop_all >/dev/null

    ret=$?

    if [[ $ret == 0 ]] ; then
        eend $ret
        return $ret
    fi

    ewarn "Shutting down the server gracefully failed. ret=$ret"
    ewarn "You man need to run"
    ewarn "  kill \$(ps -eo pid,cmd |awk '/OpenSRF/ { print \$1 }')"

}

# reload() {
#
# 	ebegin "Reloading Evergreen ILS"
#
# 	stop
# 	start
#
# 	eend 0
#
# }
