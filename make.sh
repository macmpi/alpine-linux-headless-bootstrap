#!/bin/busybox sh

# SPDX-FileCopyrightText: Copyright 2022-2023, macmpi
# SPDX-License-Identifier: MIT


command -v doas > /dev/null || alias doas="/usr/bin/sudo"

build_path="$(mktemp -d)"
if [ -n "$build_path" ]; then
	cp -r overlay "$build_path"/.
	find "$build_path"/overlay/ -exec touch -md "$(date '+%F 00:00:00')" {} \;

	# setting owner/groups for runtime (won't affect mtime)
	find "$build_path"/overlay/etc -type d -exec chmod 755 {} \;
	chmod +x "$build_path"/overlay/etc/init.d/*
	find "$build_path"/overlay/usr -type d -exec chmod 755 {} \;
	chmod +x "$build_path"/overlay/usr/local/bin/*
	chmod 777 "$build_path"/overlay/tmp
	chmod 700 "$build_path"/overlay/tmp/.trash
	chmod 600 "$build_path"/overlay/tmp/.trash/ssh_host_*_key
	doas chown -R 0:0 "$build_path"/overlay/*

	doas tar -cvf "$build_path"/headless.apkovl.tar -C "$build_path"/overlay etc usr tmp
	gzip -nk9 "$build_path"/headless.apkovl.tar && mv "$build_path"/headless.apkovl.tar.gz .
	touch -md "$(date '+%F 00:00:00')" headless.apkovl.tar.gz

	doas rm -rf "$build_path"
fi

