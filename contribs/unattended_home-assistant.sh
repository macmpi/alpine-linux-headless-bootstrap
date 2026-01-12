#!/bin/sh

# SPDX-FileCopyrightText: Copyright 2025-2026, macmpi
# SPDX-License-Identifier: MIT

##  Install minimal sys-based Alpine with Home-assistant docker image (with tailscale and mosquitto)
##  This script may be run onto any Alpine device (armhf/armv7/aarch64/x86/x86_64).
##  e.g., on 512MB PiZeroW (armhf), uses ~290MB RAM while running; leaves ~170MB RAM available
##  Home-Assistant 32bit last release is 2025.11.3 
##  With zram RAM compression, PiZero2W may run latest Home-Assistant releases on 64bit aarch64.

# HOW TO USE (Customize MY_xxxx values to your needs. Defaults are ok for Pi)
# - prepare install media (Alpine 3.23 and later) as per Alpine wiki for your target hardware
# - add headless.apkovl.tar.gz, this file (as unattended.sh) and wpa_supplicant.conf (if wifi) onto media
# - boot machine, and let unattended install proceed & reboot (may be observed via root ssh login)
# - after reboot, log-in as admin user via ssh (WARNING change default password in MY_PASS)
# - execute: doas ./update_container.sh
# - be patient as initial home-assistant image pull may take (very) long time, ~1h15 on PiZero
# - then setup home-assistant from remote machine via Web interface (avoid logs to preserve SD)
# - associate tailscale to your account info if needed for remote access (enabled by default)
# - finetune mosquitto if needed (enabled by default, WARNING unsecured anonymous allowed on port 1883)

## CUSTOMIZE values below to your needs
MY_USER="alpine" # admin account user name
MY_PASS="enipla" # password for that user
MY_IFACE="wlan0" # network interface to be used; may be eth0, etc...(DHCP by default)
MY_DISK="mmcblk0" # WARNING: this disk dev will be erased for good -- double-check!!
MY_BOOT="${MY_DISK}p1" # dev partition for bootfs on related disk, usually 1st partition
MY_ROOT="${MY_DISK}p2" # dev partition for rootfs related disk, may be 3rd if swap is present
MY_ROOT_SIZE="$((6*2*1024))" # rootfs partition size in MB (allow twice the minimum size for containers updates)
# set to false if willing to use none, or sibling containers (check availability for arch)
NATIVE_TAILSCALE=true
NATIVE_MQTT=true

# Uncomment to redirect stdout and errors to logfile as service won't show messages
# exec 1>>/tmp/alhb 2>&1

# shellcheck disable=SC2142  # known special case
alias _logger='logger -st "${0##*/}"'

# Last Home Assistant docker image for 32-bit (armhf,armv7,x86) is tagged '2025.11.3' not 'stable'
# https://www.home-assistant.io/blog/2025/06/11/release-20256/#deprecating-installation-methods-and-32-bit-architectures
case "$(cat /etc/apk/arch)" in
	armhf|armv7|x86) TAG="2025.11.3";;
	aarch64|x86_64) TAG="stable";;
	*) _logger "Unavailable container image! Exiting..."; exit 1;;
esac

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

_logger "Starting base sys-disk installation"
cat <<-EOF > /tmp/ANSWERFILE
	KEYMAPOPTS=none
	HOSTNAMEOPTS=home-assistant
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
cat <<-EOF1 >/tmp/setup_homeassistant.sh
	#!/bin/sh

	echo "$MY_USER:$MY_PASS" | chpasswd
	passwd -l root

	apk update
	apk upgrade --available

	# Pi specific tweaks
	if grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
		# Reclaim ~48MB more RAM for CPU (GPU minimal)
		# https://wiki.alpinelinux.org/wiki/Raspberry_Pi#Customize_config.txt_and_usercfg.txt
		apk add raspberrypi-bootloader-cutdown
		echo "gpu_mem=16" >> /boot/config.txt
		# brcmfmac options for improved wifi stability
		# https://wiki.alpinelinux.org/wiki/Raspberry_Pi#Wireless_drivers
		echo "options brcmfmac roamoff=1 feature_disable=0x282000" > /etc/modprobe.d/brcmfmac.conf
	fi

	power2() { echo "x=l(\$1)/l(2); scale=0; 2^((x+0.5)/1)" | bc -l; } # round to nearest power of 2
	RAM="\$(free -m | awk '/Mem:/ {print \$2}')"
	RAM="\$(power2 \$RAM)"
	# 64-bit devices with usable RAM up to 1Gb: enable zram
	if [ "\$RAM" -le 1024 ] && uname -m | grep -q 64; then
		# see https://wiki.alpinelinux.org/wiki/Zram
		apk add zram-init
		cat <<-EOF2 >/etc/conf.d/zram-init
			# settings for \${RAM}M zram
			load_on_start=yes
			unload_on_stop=yes
			num_devices=1
			type0=swap
			size0=\$RAM
			algo0=zstd
			EOF2
		cat <<-EOF2 >/etc/sysctl.d/99-vm-zram-parameters.conf
			# Optimized settings for zram
			# https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
			vm.swappiness = 180
			vm.watermark_boost_factor = 0
			vm.watermark_scale_factor = 125
			vm.page-cluster = 0
			EOF2
		rc-update add zram-init boot
	fi

	apk add bluez
	rc-update add bluetooth default

	apk add docker docker-compose
	# TBD rootless config: https://wiki.alpinelinux.org/wiki/Docker#Docker_rootless
#	adduser -G docker $MY_USER
#	apk add docker-rootless-extras shadow-subids
#	echo "# Sets config for Docker rootless >> /etc/rc.conf
#	echo "rc_cgroup_mode=\"unified\"" >> /etc/rc.conf
#	rc-update add cgroups default
#	echo "$MY_USER:231072:65536" >> /etc/subuid
#	echo "$MY_USER:231072:65536" >> /etc/subgid

	rc-update add docker default

	# admin account has home-assistant docker-related setup and config files
	mkdir -p /home/$MY_USER/homeassistant # home-assistant config directory
	chown $MY_USER /home/$MY_USER/homeassistant
	cat <<-EOF2 >/home/$MY_USER/compose.yaml
		services:
		  homeassistant:
		    image: ghcr.io/home-assistant/home-assistant:$TAG
		    container_name: homeassistant
		    privileged: true
		    restart: unless-stopped
		    network_mode: host
		    environment:
		      - TZ=Europe/Paris
		      - PUID=$(id -u $MY_USER)
		      - PGID=$(id -u $MY_USER)
		      - UMASK=007
		    volumes:
		      - /run/dbus:/run/dbus:ro
		      - /home/$MY_USER/homeassistant:/config
		EOF2
	chown $MY_USER /home/$MY_USER/compose.yaml

	cat <<-EOF2 >/home/$MY_USER/update_container.sh
		#!/bin/sh

		! [ "$(id -u)" -eq 0 ] && { echo "Please run with administrator privileges." >&2; exit 1; }

		echo "This may be (very) long...grab a coffee (or more)!"
		docker-compose pull && \
			docker-compose up -d && \
			docker image prune -af
		EOF2
	chmod +x /home/$MY_USER/update_container.sh
	chown $MY_USER /home/$MY_USER/update_container.sh

	# Optional native add-on components (set install option accordingly)
	if [ "$NATIVE_TAILSCALE" = "true" ]; then
		apk add tailscale
		# do not run as root
		sed -i 's/^#command_user=.*/command_user=\"tailscale:tailscale\"/' /etc/conf.d/tailscale
		rc-update add tailscale default
	fi
	if [ "$NATIVE_MQTT" = "true" ]; then
		apk add mosquitto
		# WARNING unsecured anonymous: add password file & disable anonymous
		cat <<-EOF2 >>/etc/mosquitto/mosquitto.conf
			allow_anonymous true
			listener 1883
			EOF2
		rc-update add mosquitto default
	fi

	EOF1
chmod +x /tmp/setup_homeassistant.sh

_logger "Mounting new system for post-installation"
mkdir -p /mnt/boot /mnt/tmp /mnt/dev /mnt/proc /mnt/sys
mount /dev/$MY_ROOT /mnt
mount /dev/$MY_BOOT /mnt/boot
mount --bind /tmp /mnt/tmp
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys

_logger "Running sys-setup script on disk-based system"
chroot /mnt /tmp/setup_homeassistant.sh
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

