#!/bin/sh

# Copyright 2022 - 2023, macmpi
# SPDX-License-Identifier: MIT

chmod 600 overlay/etc/ssh/ssh_host_*_key
chmod +x overlay/etc/local.d/headless.start
tar czvf headless.apkovl.tar.gz -C overlay etc --owner=0 --group=0
