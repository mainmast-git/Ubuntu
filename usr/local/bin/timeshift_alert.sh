#!/bin/bash
LOG_DIR="/var/log/timeshift/"
DEVICE="/dev/mmcblk0"

# Get the current user ID and session D-Bus address
export DISPLAY=:0
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

while true; do
    if sudo timeshift --check 2>&1 | grep -q "Another instance of this application is running"; then
	notify-send -u "critical" "Timeshift Backup" "Backup process is running on $DEVICE" -i "timeshift" -a "Timeshift"
	canberra-gtk-play --id="desktop-login"
    fi
    sleep 10
done
