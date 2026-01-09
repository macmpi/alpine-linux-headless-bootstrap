#!/bin/sh

# SPDX-FileCopyrightText: Copyright 2025-2026, macmpi
# SPDX-License-Identifier: MIT

##  Install minimal sys-based Alpine with customizable setup script (sys-setup.sh)

# HOW TO USE (Customize MY_xxxx values to your needs. Defaults are ok for Pi)
# - prepare install media (Alpine 3.23 and later) as per Alpine wiki for your target hardware
# - add headless.apkovl.tar.gz, this file (as unattended.sh) and wpa_supplicant.conf (if wifi) onto media
# - boot machine, and let unattended install proceed & reboot (may be observed via root ssh login)
# - after reboot, log-in as admin user via ssh (WARNING change default password in MY_PASS)

## CUSTOMIZE values below to your needs
MY_USER="alpine" # admin account user name
MY_PASS="enipla" # password for that user
MY_IFACE="wlan0" # network interface to be used; may be eth0, etc...(DHCP by default)
MY_HOSTNAME="alpine-sys"
MY_DISK="mmcblk0" # WARNING: this disk dev will be erased for good -- double-check!!
MY_BOOT="${MY_DISK}p1" # dev partition for bootfs on related disk, usually 1st partition
MY_ROOT="${MY_DISK}p2" # dev partition for rootfs related disk, may be 3rd if swap is present
MY_ROOT_SIZE="$((6*1024))" # rootfs partition size in MB (6GB for exemaple)

# Uncomment to redirect stdout and errors to logfile as service won't show messages
# exec 1>>/tmp/alhb 2>&1

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

# Setup wifi if available
if [ -e "$ovlpath/wpa_supplicant.conf" ]; then
	apk add wpa_supplicant
	cp "$ovlpath/wpa_supplicant.conf" /etc/wpa_supplicant/wpa_supplicant.conf
	rc-update add wpa_supplicant boot
	_logger "Wifi configured"
fi

_logger "Starting base sys disk installation"
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

	export ERASE_DISKS=/dev/$MY_DISK
	export ROOT_SIZE=$MY_ROOT_SIZE
	DISKOPTS="-m sys /dev/$MY_DISK"
	EOF

SSH_CONNECTION="FAKE" setup-alpine -ef /tmp/ANSWERFILE

# Prep install script for destination sys-based system
_logger "Prepare sys-setup script"
cat <<-EOF >/tmp/sys-setup.sh
	#!/bin/sh

	## Customize this script with desired configuration elements

	echo "$MY_USER:$MY_PASS" | chpasswd
	passwd -l root

	apk update
	apk upgrade --available

	EOF
chmod +x /tmp/sys-setup.sh

_logger "Mounting new system for post-installation"
mkdir -p /mnt/boot /mnt/tmp /mnt/dev /mnt/proc /mnt/sys
mount /dev/$MY_ROOT /mnt
mount /dev/$MY_BOOT /mnt/boot
mount --bind /tmp /mnt/tmp
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys

_logger "Running sys-setup script on disk-based system"
chroot /mnt /tmp/sys-setup.sh
sync

_logger "Cleaning up mounts"
umount /mnt/sys
umount /mnt/proc
umount /mnt/dev
umount /mnt/tmp
umount /mnt/boot
umount /mnt

_logger "Finished unattended script - rebooting system"
reboot

