#!/bin/sh

# SPDX-FileCopyrightText: Copyright 2025-2026, macmpi
# SPDX-License-Identifier: MIT

##  Install minimal diskless Alpine with customizable install STEPS on media containing headless.apkovl file.

# HOW TO USE (Customize MY_xxxx values and STEPS  to your needs. Defaults are ok for Pi)
# - prepare install media (Alpine 3.23 and later) as per Alpine wiki for your target hardware
# - add headless.apkovl.tar.gz, this file (as unattended.sh) and wpa_supplicant.conf (if wifi) onto media
# - boot machine, and let unattended install proceed & reboot (may be observed via root ssh login)
# - after reboot, log-in as admin user via ssh (WARNING change default password in MY_PASS)

## CUSTOMIZE values below to your needs
MY_USER="alpine" # admin account user name
MY_PASS="enipla" # password for that user
MY_IFACE="wlan0" # network interface to be used; may be eth0, etc...(DHCP by default)
MY_HOSTNAME="alpine-diskless"

# Uncomment to redirect stdout and errors to logfile as service won't show messages
# exec 1>>/tmp/alhb.log 2>&1

# shellcheck disable=SC2142  # known special case
alias _logger='logger -st "${0##*/}"'

# grab used ovl filename from dmesg
ovl="$( dmesg | grep -o 'Loading user settings from .*:' | awk '{print $5}' | sed 's/:.*$//' )"
if [ -f "${ovl}" ]; then
	ovlpath="$( dirname "$ovl" )"
else
	# search path again as mountpoint have been changed later in the boot process...
	ovl="$( basename "${ovl}" )"
	ovlpath=$( find /media -maxdepth 2 -type d -path '*/.*' -prune -o -type f -name "${ovl}" -exec dirname {} \; | head -1 )
	ovl="${ovlpath}/${ovl}"
fi

_logger "Starting base diskless installation"
cat <<-EOF > /tmp/ANSWERFILE
	KEYMAPOPTS=none
	HOSTNAMEOPTS="$MY_HOSTNAME"
	DEVDOPTS=mdev
	INTERFACESOPTS="auto lo
	iface lo inet loopback

	auto $MY_IFACE
	iface $MY_IFACE inet dhcp
	"
	DNSOPTS=""
	TIMEZONEOPTS=UTC
	PROXYOPTS=none
	APKREPOSOPTS="-1 -c"
	USEROPTS="-a -u $MY_USER"
	SSHDOPTS=openssh
	NTPOPTS=chrony

	# No disk install (diskless)
	DISKOPTS=none

	# Setup storage for diskless: use media where headless overlay is located
	LBUOPTS="$ovlpath"
	APKCACHEOPTS="\$LBUOPTS/cache"

	EOF

SSH_CONNECTION="FAKE" setup-alpine -ef /tmp/ANSWERFILE

if install -m644 "${ovlpath}"/interfaces /etc/network/interfaces >/dev/null 2>&1; then
	_logger "Imported interfaces file"
fi

# Setup wifi if available
if [ -e "$ovlpath/wpa_supplicant.conf" ]; then
	apk add wpa_supplicant
	install -m644 "$ovlpath/wpa_supplicant.conf" /etc/wpa_supplicant/wpa_supplicant.conf
	rc-update add wpa_supplicant boot
	_logger "Wifi configured with imported wpa_supplicant.conf"
fi

# Provision sshd authorized keys if available (host keys imported by default)
if install -Dm600 /root/.ssh/authorized_keys  /home/"$MY_USER"/.ssh/authorized_keys >/dev/null 2>&1 || 
	install -Dm600 "${ovlpath}"/authorized_keys /home/"$MY_USER"/.ssh/authorized_keys >/dev/null 2>&1; then
		_logger "Imported public key SSH for authentication."
		chown -R "$MY_USER" /home/"$MY_USER"/.ssh
		lbu include /home/"$MY_USER"/.ssh/authorized_keys 
fi

echo "$MY_USER:$MY_PASS" | chpasswd
passwd -l root

#############################################
## Customize the script below with desired configuration elements
_logger "Install customizations"

apk update
apk upgrade --available

lbu commit -d
sync
_logger "Finished unattended script - rebooting system"
reboot

