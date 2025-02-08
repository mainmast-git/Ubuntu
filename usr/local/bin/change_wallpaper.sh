#!/bin/bash

# Get a random wallpaper from /usr/share/backgrounds
WALLPAPER=$(find $HOME/Wallpapers -type f | shuf -n 1)

# Set the wallpaper using gsettings
gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER"
