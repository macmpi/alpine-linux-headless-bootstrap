#!/bin/sh

# SPDX-FileCopyrightText: Copyright 2022-2026, macmpi
# SPDX-License-Identifier: MIT

## collection of few code snippets as sample unnatteded actions some may find usefull

## will run encapusated within headless_unattended OpenRC service

# To prevent headless bootstrap script from starting sshd
# only keep a single starting # on the line below
##NO_SSH

# Uncomment to redirect stdout and errors to logfile as service won't show messages
# exec 1>>/tmp/alhb.log 2>&1

# shellcheck disable=SC2142  # known special case
alias _logger='logger -st "${0##*/}"'


## This snippet removes apkovl file on volume after initial boot
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

# also works in case volume is mounted read-only
grep -q "${ovlpath}.*[[:space:]]ro[[:space:],]" /proc/mounts; is_ro=$?
_is_ro() { return "$is_ro"; }
_is_ro && mount -o remount,rw "${ovlpath}"
rm -f "${ovl}"
_is_ro && mount -o remount,ro "${ovlpath}"

_logger "Finished unattended script"

