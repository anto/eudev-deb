# -*-Shell-script-*-
# /etc/lsb-base-logging.sh

if [ -e /sys/fs/cgroup/systemd ] ; then

    # Some init scripts use "set -e" and "set -u", we don't want that
    # here
    set +e
    set +u

    if [ -n "$DPKG_MAINTSCRIPT_PACKAGE" ] ; then
    # If we are called by a maintainer script, chances are good that a
    # new or updated sysv init script was installed.  Reload daemon to
    # pick up any changes.
	echo "Reloading systemd"
	systemctl daemon-reload
    fi

    # Redirect SysV init scripts when executed by the user
    if [ $PPID -ne 1 ] && [ -z "$init" ] && [ -z "$_SYSTEMCTL_SKIP_REDIRECT" ] ; then
        case "$0" in
            /etc/init.d/*)
		_use_systemctl=1
		;;
	esac
    else
	export _SYSTEMCTL_SKIP_REDIRECT="true"
    fi
else
    _use_systemctl=0
fi

systemctl_redirect () {
	local s
	local rc
	local prog=${1##*/}
        local command=$2

	case "$command" in
	start)
		s="Starting $prog (via systemctl)"
		;;
	stop)
		s="Stopping $prog (via systemctl)"
		;;
	reload|force-reload)
		s="Reloading $prog configuration (via systemctl)"
		;;
	restart)
		s="Restarting $prog (via systemctl)"
		;;
	esac

	service="${prog%.sh}.service"
	[ "$command" = status ] || log_daemon_msg "$s" "$service"
	/bin/systemctl $command "$service"
	rc=$?
	[ "$command" = status ] || log_end_msg $rc

	return $rc
}

if [ "$_use_systemctl" = "1" ]; then
        if  [ "x$1" = xstart -o \
                "x$1" = xstop -o \
                "x$1" = xrestart -o \
                "x$1" = xreload -o \
                "x$1" = xforce-reload -o \
                "x$1" = xstatus ] ; then

		systemctl_redirect $0 $1
		exit $?
	fi
fi