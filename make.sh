#!/bin/busybox sh

# SPDX-FileCopyrightText: Copyright 2022-2023, macmpi
# SPDX-License-Identifier: MIT

# script meant to be run on Alpine (busybox) or on Ubuntu
# verify busybox build options if eventually using other platforms
command -v doas > /dev/null || alias doas="/usr/bin/sudo"

build_path="$(mktemp -d)"
if [ -n "$build_path" ]; then
	# prefer timestamp option for touch as it works on directories too
	t_stamp="$( TZ=UTC date +%Y%m%d0000.00 )"
	cp -a overlay "$build_path"/.
	find "$build_path"/overlay/ -exec sh -c 'TZ=UTC touch -chm -t "$0" "$1"' "$t_stamp" {} \;
	# setting modes and owner/groups for runtime (won't affect mtime)
	find "$build_path"/overlay/etc -type d -exec chmod 755 {} \;
	chmod 755 "$build_path"/overlay/etc/init.d/*
	chmod 755 "$build_path"/overlay/etc/runlevels/default/*
	chmod 777 "$build_path"/overlay/tmp
	chmod 700 "$build_path"/overlay/tmp/.trash
	chmod -R 600 "$build_path"/overlay/tmp/.trash/ssh_host_*_key
	find "$build_path"/overlay/usr -type d -exec chmod 755 {} \;
	chmod 755 "$build_path"/overlay/usr/local/bin/*
	doas chown -Rh 0:0 "$build_path"/overlay/*

	# busybox config on Alpine & Ubuntu has FEATURE_TAR_GNU_EXTENSIONS
	# (will preserve user/group/modes & mtime) and FEATURE_TAR_LONG_OPTIONS
	# shellcheck disable=SC2046   # we want word splitting as result of find
	doas tar cv -C "$build_path"/overlay --no-recursion \
		$(doas find "$build_path"/overlay/ | sed "s|$build_path/overlay/||" | sort | xargs ) | \
			gzip -c9n > headless.apkovl.tar.gz
	TZ=UTC touch -cm -t "$t_stamp" headless.apkovl.tar.gz
	doas rm -rf "$build_path"
fi

