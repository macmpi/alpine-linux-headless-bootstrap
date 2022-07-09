#!/bin/sh

chmod +x overlay/etc/local.d/headless.start
tar czvf headless.apkovl.tar.gz -C overlay etc --owner=0 --group=0
