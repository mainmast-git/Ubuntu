#!/bin/bash

echo "Starting Ubuntu Post-Installation Setup..."

# Check if the script is run as root
check_user() {
    if [ "$EUID" -eq 0 ]; then
      echo "This script must not be run as root. Please run it as a regular user."
      exit 1
    fi
}

# Function to update and upgrade system
update_system() {
    git clone https://github.com/ramin-samadi/Ubuntu /tmp/Ubuntu || { echo "Failed to clone Ubuntu repo"; exit 1; }
    echo "Updating and upgrading the system..."
    sleep 5
    sudo apt update -y && sudo apt upgrade -y || { echo "System update failed"; exit 1; }
    clear
}

# Function to add PPAs
add_ppas() {
    echo "Adding PPAs..."
    sleep 5
    sudo add-apt-repository -y ppa:gns3/ppa
    sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
    sudo add-apt-repository -y ppa:papirus/papirus
    sudo apt update -y || { echo "PPA update failed"; exit 1; }
    clear
}

# Function to install APT packages
install_apt_packages() {
    echo "Installing required packages..."
    sleep 5
    xargs -a /tmp/Ubuntu/packages/apt sudo apt install -y || { echo "APT package installation failed"; exit 1; } # Install apt packages
    clear
}

# Function to setup QT5 theme
setup_qt5_theme() {
    echo "Setting up theme (Fusion + GTK3 + darker) for KDE..."
    sleep 5
    qt5ct
    sudo qt5ct
    clear
}

# Function to add i386 architecture and install GNS3 IOU
install_gns3_iou() {
    echo "Adding i386 architecture and installing GNS3 IOU..."
    sleep 5
    sudo dpkg --add-architecture i386
    sudo apt update -y
    sudo apt install -y gns3-iou || { echo "GNS3 IOU installation failed"; exit 1; }
    clear
}

# Function to install .deb packages
install_deb_packages() {
    echo "Downloading and installing Google Chrome & TeamViewer..."
    sleep 5
    while read -r url; do
        wget -q -O /tmp/$(basename "$url") "$url" # Install deb packages
        sudo dpkg -i /tmp/$(basename "$url") || sudo apt install -f -y || { echo "DEB package installation failed"; exit 1; }
    done < /tmp/Ubuntu/packages/deb
    clear
}

# Function to setup Flatpak
setup_flatpak() {
    echo "Setting up Flatpak and installing apps..."
    sleep 5
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    xargs -a /tmp/Ubuntu/packages/flatpak flatpak install -y flathub || { echo "Flatpak app installation failed"; exit 1; } # Install flatpaks
    flatpak install --user -y https://sober.vinegarhq.org/sober.flatpakref || { echo "Sober Flatpak installation failed"; exit 1; }
    clear
}

# Function to configure GNOME
configure_gnome() {
    echo "Configuring GNOME theme..."
    sleep 5
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/]$/, 'google-chrome.desktop']/")"
    gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/]$/, 'com.spotify.Client.desktop']/")"
    gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/]$/, 'gns3.desktop']/")"
    gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'firefox_firefox.desktop'//" | sed "s/'firefox_firefox.desktop', //")"
    gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'libreoffice-writer.desktop'//" | sed "s/'libreoffice-writer.desktop', //")"
    gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'snap-store_snap-store.desktop'//" | sed "s/'snap-store_snap-store.desktop', //")"
    gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'thunderbird_thunderbird.desktop'//" | sed "s/'thunderbird_thunderbird.desktop', //")"
    gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'yelp.desktop'//" | sed "s/'yelp.desktop', //")"
    gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'org.gnome.Rhythmbox3.desktop'//" | sed "s/'org.gnome.Rhythmbox3.desktop', //")"
    gnome-extensions disable ubuntu-dock@ubuntu.com
    clear
}

# Function to remove unwanted apps
remove_unwanted_apps() {
    echo "Removing unwanted apps..."
    sleep 5
    sudo snap remove thunderbird firefox || echo "Some snaps were not installed, continuing..."
    sudo apt autoremove -y
    clear
}

# Function to clone repositories
clone_repositories() {
    echo "Cloning configuration repositories..."
    sleep 5
    git clone https://github.com/orangci/walls-catppuccin-mocha.git ~/Wallpapers || { echo "Failed to clone Wallpapers repo"; exit 1; }
    sudo mv /tmp/Ubuntu/usr/local/bin/change_wallpaper.sh /usr/local/bin/ || { echo "Failed to move change_wallpaper.sh"; exit 1; }
    clear
}

# Function to copy configuration files
copy_config_files() {
    echo "Deploying user configurations..."
    sleep 5
    sudo mv -f /tmp/Ubuntu/home/.config/* "$HOME/.config/" || { echo "Failed to move config files"; exit 1; }
    sudo mv -f /tmp/Ubuntu/home/.vimrc "$HOME/" || { echo "Failed to move .vimrc"; exit 1; }
    clear
}

# Function to enable firewall and Fail2Ban
enable_firewall_fail2ban() {
    echo "Enabling firewall and Fail2Ban..."
    sleep 5
    sudo ufw enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo systemctl enable --now fail2ban || { echo "Failed to enable Fail2Ban"; exit 1; }
    clear
}

# Function to add custom configurations to .bashrc
add_custom_bashrc() {
    echo "Adding custom configurations to .bashrc..."
    sleep 5
    git clone --depth=1 https://github.com/ChrisTitusTech/mybash.git ~/mybash
    chmod +x ~/mybash/setup.sh
    ~/mybash/setup.sh
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
    make -C ble.sh install PREFIX=~/.local
    echo 'source ~/.local/share/blesh/ble.sh' >> ~/.bashrc
    cat /tmp/Ubuntu/home/.bashrc >> ~/.bashrc
    clear
}

# Function to set the theme
set_theme() {
    echo "Setting catppuccin mocha theme..."
    sleep 5
    # gnome-terminal
    curl -L https://raw.githubusercontent.com/catppuccin/gnome-terminal/v1.0.0/install.py | python3 -
    gsettings set org.gnome.Terminal.ProfilesList default '95894cfd-82f7-430d-af6e-84d168bc34f5'
    gsettings set org.gnome.desktop.interface monospace-font-name 'MesloLGS Nerd Font 12'
    # batcat
    mkdir -p "$(batcat --config-dir)/themes"
    wget -P "$(batcat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Latte.tmTheme
    wget -P "$(batcat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Frappe.tmTheme
    wget -P "$(batcat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Macchiato.tmTheme
    wget -P "$(batcat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
    batcat cache --build
    # Papirus icons
    git clone https://github.com/catppuccin/papirus-folders.git
    cd papirus-folders
    sudo cp -r src/* /usr/share/icons/Papirus
    curl -LO https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders && chmod +x ./papirus-folders
    ./papirus-folders -C cat-mocha-lavender --theme Papirus-Dark
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    # GTK 3/4 theming
    cd $HOME
    curl -LsSO "https://raw.githubusercontent.com/catppuccin/gtk/v1.0.3/install.py"
    python3 install.py mocha lavender
    gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-lavender-standard+default'
    clear
}

setup_custom_keyboard_shortcuts() {
    echo "Setting up keyboard shortcuts..."
    sleep 5
    # Custom Keyboard Shortcuts -> Mission Center (ctrl + shift + esc)
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom0/']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom0/ name 'Aktivitetshanteraren'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom0/ command 'flatpak run io.missioncenter.MissionCenter'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom0/ binding '<Control><Shift>Escape'

    # Pre-defined Keyboard Shortcuts
    gsettings set org.gnome.settings-daemon.plugins.media-keys www "['<Super>w']" # Open default browser (super + w)
    gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>t']" # Open gnome-terminal (super + t)
    gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']" # Open default file manager (super + e)
    gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>a']" # Toggle message tray (super + a)
    gsettings set org.gnome.shell.keybindings toggle-quick-settings "['<Super>x']" # Toggle quick settings (super + x)
    gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "['<Super>r']" # Run dialog (super + r)
    gsettings set org.gnome.settings-daemon.plugins.media-keys control-center "['<Super>i']" # Open settings (super + i)
    gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']" # Close programs (super + q)
    
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']" # Switch to workspace 1 (super + 1)
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']" # Switch to workspace 2 (super + 2)
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']" # Switch to workspace 3 (super + 3)
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']" # Switch to workspace 4 (super + 4)
    
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Super>1']" # Move window and switch to workspace 1 (super + shift + 1)
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Super>2']" # Move window and switch to workspace 2 (super + shift + 2)
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Super>3']" # Move window and switch to workspace 3 (super + shift + 3)
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Super>4']" # Move window and switch to workspace 4 (super + shift + 4)
    clear
}

# Function to clean up
clean_up() {
    echo "Cleaning up..."
    sleep 5
    rm -rf /tmp/Ubuntu /tmp/google-chrome.deb /tmp/teamviewer.deb
    clear
}

# Function to add user to required groups
add_user_to_groups() {
    echo "Adding $USER to required groups..."
    sleep 5
    sudo usermod -aG ubridge,libvirt,kvm,wireshark $(whoami) || { echo "Failed to add user to groups"; exit 1; }
    clear
}

# Function to reboot system
reboot_system() {
    echo "Post-installation setup complete!"
    sleep 5
    reboot
}

# Main execution flow
check_user
update_system
add_ppas
install_apt_packages
setup_qt5_theme
install_gns3_iou
install_deb_packages
setup_flatpak
configure_gnome
remove_unwanted_apps
clone_repositories
copy_config_files
enable_firewall_fail2ban
add_custom_bashrc
set_theme
source ~/.bashrc
setup_custom_keyboard_shortcuts
clean_up
add_user_to_groups
reboot_system
