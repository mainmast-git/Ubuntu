#!/bin/bash

# Kontrollera om skriptet körs som root (för att undvika problem med sudo i vissa kommandon)
if [[ $EUID -eq 0 ]]; then
    echo "Fel: Detta skript ska inte köras som root. Kör det som vanlig användare istället."
    exit 1
fi

echo "Startar Ubuntu Post-Installation Setup..."

# Funktion för att visa fel och avsluta
error_exit() {
    echo "Fel: $1"
    exit 1
}

# Funktion för att fråga användaren om bekräftelse
confirm() {
    read -p "$1 (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

### Uppdatera systemet och lägg till PPA:er ###
echo "Uppdaterar systemet och lägger till PPA:er..."

# Samla alla PPA:er och kör apt update en gång efteråt för att undvika redundans
sudo add-apt-repository -y ppa:gns3/ppa || error_exit "Kunde inte lägga till GNS3 PPA"
sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch || error_exit "Kunde inte lägga till fastfetch PPA"
sudo add-apt-repository -y ppa:papirus/papirus || error_exit "Kunde inte lägga till Papirus PPA"
sudo apt update -y || error_exit "Kunde inte uppdatera paketlistor"
sudo apt upgrade -y || error_exit "Kunde inte uppgradera systemet"

### Installera APT-paket ###
echo "Installerar nödvändiga paket..."
sudo apt install -y \
    vim curl git qemu-kvm libvirt-daemon-system libvirt-clients \
    bridge-utils virt-manager flatpak timeshift neovim qdirstat \
    qt5ct qt5-style-kvantum qt5-style-kvantum-themes gns3-gui \
    gns3-server libminizip1 libxcb-xinerama0 tldr fastfetch lsd \
    make gawk trash-cli fzf bash-completion whois bat tree \
    ripgrep gnome-tweaks plocate fail2ban \
    papirus-icon-theme epapirus-icon-theme || error_exit "Misslyckades med att installera paket"

### Aktivera i386-arkitektur för GNS3 IOU ###
echo "Lägger till i386-arkitektur för GNS3 IOU-stöd..."
sudo dpkg --add-architecture i386 || error_exit "Kunde inte lägga till i386-arkitektur"
sudo apt update -y || error_exit "Kunde inte uppdatera efter i386-aktivering"
sudo apt install -y gns3-iou || error_exit "Kunde inte installera gns3-iou"

### Installera .deb-paket ###
echo "Laddar ner och installerar Google Chrome & TeamViewer..."
wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb || error_exit "Kunde inte ladda ner Google Chrome"
wget -O /tmp/teamviewer.deb https://download.teamviewer.com/download/linux/teamviewer_amd64.deb || error_exit "Kunde inte ladda ner TeamViewer"
sudo dpkg -i /tmp/google-chrome.deb /tmp/teamviewer.deb || sudo apt install -f -y || error_exit "Kunde inte installera .deb-paket"

### Konfigurera Flatpak och installera appar ###
echo "Ställer in Flatpak och installerar appar..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || error_exit "Kunde inte lägga till Flathub"
for app in com.rustdesk.RustDesk com.usebottles.bottles com.spotify.Client io.github.shiftey.Desktop io.missioncenter.MissionCenter; do
    flatpak install -y flathub "$app" || echo "Varning: Kunde inte installera $app"
done
flatpak install --user -y https://sober.vinegarhq.org/sober.flatpakref || echo "Varning: Kunde inte installera Vinegar"

### Konfigurera GNOME ###
echo "Konfigurerar GNOME-tema och favoritappar..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
# Lägg till favoritappar om de inte redan finns
current_favs=$(gsettings get org.gnome.shell favorite-apps)
for app in 'google-chrome.desktop' 'com.spotify.Client.desktop' 'gns3.desktop'; do
    if [[ ! $current_favs =~ $app ]]; then
        gsettings set org.gnome.shell favorite-apps "$(echo $current_favs | sed "s/]$/, '$app']/")"
    fi
done
# Ta bort oönskade appar från favoriter
for app in 'firefox_firefox.desktop' 'libreoffice-writer.desktop' 'snap-store_snap-store.desktop' 'thunderbird_thunderbird.desktop' 'yelp.desktop' 'org.gnome.Rhythmbox3.desktop'; do
    gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, '$app'//" | sed "s/'$app', //")"
done

### Ta bort oönskade appar ###
if confirm "Vill du ta bort Thunderbird, Firefox och LibreOffice?"; then
    sudo snap remove thunderbird firefox || echo "Varning: Kunde inte ta bort snap-paket"
    sudo apt remove --purge -y libreoffice* || echo "Varning: Kunde inte ta bort LibreOffice"
    sudo apt autoremove -y || echo "Varning: Kunde inte köra autoremove"
fi

### Klona och distribuera konfigurationsfiler ###
echo "Klonar konfigurationsrepository och distribuerar filer..."
git clone https://github.com/ramin-samadi/Ubuntu /tmp/Ubuntu || error_exit "Kunde inte klona Ubuntu-repo"
git clone https://github.com/orangci/walls-catppuccin-mocha.git ~/Wallpapers || error_exit "Kunde inte klona Wallpapers-repo"
sudo mkdir -p /usr/local/bin || error_exit "Kunde inte skapa /usr/local/bin"
sudo cp -f /tmp/Ubuntu/usr/local/bin/change_wallpaper.sh /usr/local/bin/ || error_exit "Kunde inte kopiera change_wallpaper.sh"
mkdir -p "$HOME/.config" || error_exit "Kunde inte skapa .config-mappen"
cp -r /tmp/Ubuntu/home/.config/* "$HOME/.config/" || error_exit "Kunde inte kopiera .config-filer"
cp -f /tmp/Ubuntu/home/.vimrc "$HOME/" || error_exit "Kunde inte kopiera .vimrc"

### Aktivera brandvägg och Fail2Ban ###
echo "Aktiverar brandvägg och Fail2Ban..."
sudo ufw enable || error_exit "Kunde inte aktivera UFW"
sudo ufw default deny incoming || error_exit "Kunde inte ställa in UFW-regler"
sudo ufw default allow outgoing || error_exit "Kunde inte ställa in UFW-regler"
sudo systemctl enable fail2ban || error_exit "Kunde inte aktivera Fail2Ban"

### Konfigurera .bashrc ###
echo "Konfigurerar .bashrc med anpassningar..."
git clone --depth=1 https://github.com/ChrisTitusTech/mybash.git ~/mybash || error_exit "Kunde inte klona mybash"
chmod +x ~/mybash/setup.sh
~/mybash/setup.sh || error_exit "Kunde inte köra mybash setup"
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git || error_exit "Kunde inte klona ble.sh"
make -C ble.sh install PREFIX=~/.local || error_exit "Kunde inte installera ble.sh"
echo 'source ~/.local/share/blesh/ble.sh' >> ~/.bashrc
cat << 'EOF' >> ~/.bashrc
alias qdirstat='nohup sudo -E qdirstat'
export QT_QPA_PLATFORMTHEME=qt5ct
alias edit='nvim'
alias sedit='sudo nvim'
alias clear='clear; fastfetch'
alias cls='clear'
bind -x '"\C-l": clear'
alias update='sudo apt update -y; sudo apt upgrade -y; flatpak update -y; sudo snap refresh'
alias install='sudo apt install -y'
alias search='apt search'
alias uninstall='sudo apt remove -y'
alias clean='sudo apt autoremove -y && sudo apt autoclean -y'
alias packages='apt list --installed'
alias ping='ping -c 4'
alias ip='ip -c'
alias vi='\vi'
alias ?='tldr'
alias explain='tldr'
alias ~='cd $HOME'
alias -- -="cd -"
alias la='lsd -Alh'
alias ls='lsd -aFh --color=always'
alias lx='lsd -lXBh'
alias lk='lsd -lSrh'
alias lc='lsd -ltcrh'
alias lu='lsd -lturh'
alias lr='lsd -lRh'
alias lt='lsd -ltrh'
alias lm='lsd -alh |more'
alias lw='lsd -xAh'
alias ll='lsd -Fl'
alias labc='lsd -lap'
alias lf="lsd -l | egrep -v '^d'"
alias ldir="lsd -l | egrep '^d'"
alias lla='lsd -Al'
alias las='lsd -A'
alias lls='lsd -l'
EOF

### Sätt Catppuccin Mocha-tema ###
echo "Sätter upp Catppuccin Mocha-tema..."

# gnome-terminal
curl -L https://raw.githubusercontent.com/catppuccin/gnome-terminal/v1.0.0/install.py | python3 - || echo "Varning: Kunde inte sätta terminaltema"
gsettings set org.gnome.Terminal.ProfilesList default '95894cfd-82f7-430d-af6e-84d168bc34f5'
gsettings set org.gnome.desktop.interface monospace-font-name 'MesloLGS Nerd Font 12'

# bat
mkdir -p "$(bat --config-dir)/themes" || error_exit "Kunde inte skapa bat-themes-mapp"
wget -P "$(bat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme || echo "Varning: Kunde inte ladda ner bat-tema"
bat cache --build || echo "Varning: Kunde inte bygga bat-cache"

# Papirus-ikoner
git clone https://github.com/catppuccin/papirus-folders.git || error_exit "Kunde inte klona papirus-folders"
cd papirus-folders
sudo cp -r src/* /usr/share/icons/Papirus || error_exit "Kunde inte kopiera Papirus-filer"
curl -LO https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders && chmod +x ./papirus-folders
./papirus-folders -C cat-mocha-lavender --theme Papirus-Dark || echo "Varning: Kunde inte sätta Papirus-tema"
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
cd ..

# GTK-tema
curl -LsSO "https://raw.githubusercontent.com/catppuccin/gtk/v1.0.3/install.py" || error_exit "Kunde inte ladda ner GTK-tema-skript"
python3 install.py mocha lavender || error_exit "Kunde inte installera GTK-tema"
gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-lavender-standard+default'

### Rensa upp ###
echo "Rensar upp temporära filer..."
rm -rf /tmp/Ubuntu papirus-folders install.py || echo "Varning: Kunde inte rensa alla temporära filer"
rm -f /tmp/google-chrome.deb /tmp/teamviewer.deb

### Lägg till användaren i nödvändiga grupper ###
echo "Lägger till $USER i nödvändiga grupper..."
sudo usermod -aG ubridge,libvirt,kvm,wireshark "$USER" || error_exit "Kunde inte lägga till användaren i grupper"

### Ladda om .bashrc ###
source ~/.bashrc

echo "Post-installationen är klar!"
if confirm "Vill du starta om systemet nu?"; then
    reboot
else
    echo "Starta om manuellt senare med 'reboot' för att tillämpa alla ändringar."
fi
