#/bin/sh

## collection of few code snippets as sample unnatteded actions some may find usefull


## Obvious one; reminder: is run in the background
echo hello world !!
sleep 60

########################################################


## This snippet removes apkovl file on volume after initial boot
ovlpath=$( find /media -maxdepth 2 -type d -path '*/.*' -prune -o -type f -name *.apkovl.tar.gz -exec dirname {} \; | head -1 )

# also works in case volume is mounted read-only
grep -q "${ovlpath}.*[[:space:]]ro[[:space:],]" /proc/mounts; RO=$?
[ "$RO" -eq "0" ] && mount -o remount,rw "${ovlpath}"
rm "${ovlpath}"/*.apkovl.tar.gz
[ "$RO" -eq "0" ] && mount -o remount,ro "${ovlpath}"

########################################################


## This snippet configures Minimal diskless environment
# note: with INTERFACESOPTS=none, no networking will be setup so it won't work after reboot!
# Change it or run setup-interfaces in interractive mode afterwards (and lbu commit -d thenafter)

logger -st ${0##*/} "Setting-up minimal environment"

cat <<-EOF > /tmp/ANSWERFILE
	# base answer file for setup-alpine script

	# Do not set keyboard layout
	KEYMAPOPTS=none

	# Keep hostname
	HOSTNAMEOPTS="$(hostname)"

	# Set device manager to mdev
	DEVDOPTS=mdev

	# Contents of /etc/network/interfaces
	INTERFACESOPTS=none

	# Set Public nameserver
	DNSOPTS="-n 208.67.222.222"

	# Set timezone to UTC
	TIMEZONEOPTS="UTC"

	# set http/ftp proxy
	PROXYOPTS=none

	# Add first mirror (CDN)
	APKREPOSOPTS="-1"

	# Do not create any user
	USEROPTS=none

	# No Openssh
	SSHDOPTS=none

	# Use openntpd
	NTPOPTS="chrony"

	# No disk install (diskless)
	DISKOPTS=none

	# Setup storage for diskless (find boot directory in /media/xxxx/apk/.boot_repository)
	LBUOPTS="$( find /media -maxdepth 3 -type d -path '*/.*' -prune -o -type f -name '.boot_repository' -exec dirname {} \; | head -1 | xargs dirname )"
	APKCACHEOPTS="\$LBUOPTS/cache"

	EOF

# trick setup-alpine to pretend existing SSH connection
# and therefore keep (do not reset) network interfaces while running in background
SSH_CONNECTION="FAKE" setup-alpine -ef /tmp/ANSWERFILE
lbu commit -d

########################################################


logger -st ${0##*/} "Finished unattended script"

