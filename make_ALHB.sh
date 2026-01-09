#!/bin/busybox sh

# SPDX-FileCopyrightText: Copyright 2022-2026, macmpi
# SPDX-License-Identifier: MIT

# Script meant to be run on Alpine (busybox) or on Ubuntu.
# Check busybox version & options if eventually using other platforms.

# Ubuntu LTS busybox 1.30.1 tar does NOT support setting owner/group/mtime
# probably available after busybox 1.31.1, following 2019-08-01 change:
# https://git.busybox.net/busybox/commit/?id=e6a87e74837ba5f2f2207a75cd825acf8cf28afb
# This limitation requires copying files and setting owner/group/mtime before archiving.

command -v doas > /dev/null || alias doas="/usr/bin/sudo"

build_path="$(mktemp -d)"
if [ -n "$build_path" ]; then
	# prefer timestamp option for touch as it works on directories too
	t_stamp="$( TZ=UTC date +%Y%m%d0000.00 )"
	cp -a overlay "$build_path"/.
	cp -a LICENSE "$build_path"/overlay/tmp/ALHB_LICENSE
	cp -a xg_multi/xg_multi "$build_path"/overlay/tmp/.ALHB/.
	find "$build_path"/overlay/ -exec sh -c 'TZ=UTC touch -chm -t "$0" "$1"' "$t_stamp" {} \;
	# setting modes and owner/groups for runtime (won't affect mtime)
	find "$build_path"/overlay/etc -type d -exec chmod 755 {} \;
	chmod 755 "$build_path"/overlay/etc/init.d/*
	chmod 755 "$build_path"/overlay/etc/runlevels/default/*
	chmod 777 "$build_path"/overlay/tmp
	chmod 644 "$build_path"/overlay/tmp/ALHB_LICENSE
	chmod 700 "$build_path"/overlay/tmp/.ALHB
	chmod 755 "$build_path"/overlay/tmp/.ALHB/*
	chmod 600 "$build_path"/overlay/tmp/.ALHB/ssh_host_*_key
	chmod 644 "$build_path"/overlay/tmp/.ALHB/ssh_host_*_key.pub
	doas chown -Rh 0:0 "$build_path"/overlay/*

	# busybox config on Alpine & Ubuntu has FEATURE_TAR_GNU_EXTENSIONS
	# (will preserve user/group/modes & mtime) and FEATURE_TAR_LONG_OPTIONS
	# shellcheck disable=SC2046   # we want word splitting as result of find
	doas tar cv -C "$build_path"/overlay --no-recursion \
		$(doas find "$build_path"/overlay/ | sed "s|$build_path/overlay/||" | sort | xargs ) | \
			gzip -c9n > headless.apkovl.tar.gz
	sha512sum headless.apkovl.tar.gz > headless.apkovl.tar.gz.sha512
	TZ=UTC touch -cm -t "$t_stamp" headless.apkovl.tar.gz*
	doas rm -rf "$build_path"
fi

