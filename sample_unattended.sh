#/bin/sh

echo hello world !!
sleep 60
logger -st ${0##*/} "Finished unattended script"

