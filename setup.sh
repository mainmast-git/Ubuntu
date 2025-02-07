#!/bin/bash

echo "Starting Ubuntu Post-Installation Setup..."

# Update & Upgrade System
echo "Updating and upgrading the system..."
sudo apt update -y; sudo apt upgrade -y

# Add GNS3 PPA
echo "Adding GNS3 PPA..."
sudo add-apt-repository -y ppa:gns3/ppa
sudo apt update -y

# Add fastfetch PPA needed for CTT "mybash"
echo "Adding fastfetch PPA..."
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt update -y

# Install APT Packages
echo "Installing required packages..."
sudo apt install -y \
    vim curl git qemu-kvm libvirt-daemon-system libvirt-clients \
    bridge-utils virt-manager flatpak timeshift neovim qdirstat \
    qt5ct qt5-style-kvantum qt5-style-kvantum-themes gns3-gui \
    gns3-server libminizip1 libxcb-xinerama0 tldr fastfetch lsd \
    make gawk trash-cli btop

# Setup qt5ct theme for KDE applications
echo "Setting up theme (Fusion + GTK3 + darker) for KDE..."
qt5ct # For user
sudo qt5ct # For super user 
echo "export QT_QPA_PLATFORMTHEME=qt5ct" >> ~/.bashrc
echo "alias qdirstat='nohup sudo -E qdirstat'" >> ~/.bashrc
source ~/.bashrc

# Enable i386 architecture for GNS3 IOU support
echo "Adding i386 architecture and updating packages..."
sudo dpkg --add-architecture i386
sudo apt update -y
sudo apt install -y gns3-iou

# Install .deb Packages
echo "Downloading and installing Google Chrome & TeamViewer..."
wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
wget -O /tmp/teamviewer.deb https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
sudo dpkg -i /tmp/google-chrome.deb /tmp/teamviewer.deb || sudo apt install -f -y

# Install Flatpak and Flathub repository
echo "Setting up Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "Installing Flatpak apps..."
flatpak install -y flathub com.rustdesk.RustDesk com.usebottles.bottles com.spotify.Client
flatpak install --user -y https://sober.vinegarhq.org/sober.flatpakref

# Set Dark Mode in GNOME
echo "Configuring GNOME theme..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Pin favorite apps to the Ubuntu sidebar
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/]$/, 'google-chrome.desktop']/")"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/]$/, 'com.spotify.Client.desktop']/")"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/]$/, 'gns3.desktop']/")"

# Unpin favorite apps from the Ubuntu sidebar
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'firefox_firefox.desktop'//" | sed "s/'firefox_firefox.desktop', //")"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'libreoffice-writer.desktop'//" | sed "s/'libreoffice-writer.desktop', //")"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'snap-store_snap-store.desktop'//" | sed "s/'snap-store_snap-store.desktop', //")"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'thunderbird_thunderbird.desktop'//" | sed "s/'thunderbird_thunderbird.desktop', //")"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'yelp.desktop'//" | sed "s/'yelp.desktop', //")"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'org.gnome.Rhythmbox3.desktop'//" | sed "s/'org.gnome.Rhythmbox3.desktop', //")"

# Remove apps I don't need
sudo snap remove thunderbird firefox
sudo apt remove --purge libreoffice* -y
sudo apt autoremove -y

# Clone your Ubuntu repo
echo "Cloning configuration repository..."
git clone https://github.com/ramin-samadi/Ubuntu /tmp/Ubuntu

# Copy configuration files
echo "Deploying user configurations..."
mv -f /tmp/Ubuntu/home/.config/monitors.xml $HOME/.config/

# Add custom configuration to .bashrc
git clone --depth=1 https://github.com/ChrisTitusTech/mybash.git /tmp/
chmod +x /tmp/mybash/setup.sh
/tmp/mybash/setup.sh

# Reload .bashrc
source ~/.bashrc

# Clean up
echo "Removing cloned repository..."
rm -rf /tmp/Ubuntu

echo "Cleaning up downloaded .deb files..."
rm /tmp/google-chrome.deb /tmp/teamviewer.deb 

# Add user to required groups
echo "Adding $USER to required groups..."
sudo usermod -aG ubridge,libvirt,kvm,wireshark $(whoami)

echo "Post-installation setup complete!"
reboot
