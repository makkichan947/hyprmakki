#!/bin/bash

// Needed Softwares
yay -S --needed firefox-developer-deition firefox-developer-edition-i18n-zh-cn tmplayer gnome-disk-utility baobab loupe btop vim starship gitui grim tty-clock nwg-look vim-airline vim-airline-themes wlogout glow vscodium snappy-switcher papers kitty rofi bluez blueman bluetui gdu fastfetch powerprofilesctl git wev figlet cmatrix yazi mpv file-roller base-devel sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg
// Needed WM
yay -S --needed libnotify xdg-desktop-portal-hyprland hyprpolkitagent qt5-wayland qt6-wayland hyprlang hyprlock hyprpaper hyprtoolkit hyprwire hyprland-guiutils hyprgraphics aquamarine hyprland

// Momoisay
git clone https://github.com/Mon4sm/Momoisay.git
cd Momoisay
sudo sh ./install/linux.sh
cd ..
rm -rvf Momoisay

// Sddm
cd silent
./install.sh && cd ..
rm -rvf silent
