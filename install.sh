#!/bin/bash

// Needed Softwares
yay -S --needed tmplayer btop vim starship gitui tty-clock vim-airline vim-airline-themes wlogout vscodium-bin snappy-switcher papers kitty rofi bluez blueman bluetui gdu fastfetch powerprofilesctl git wev figlet cmatrix yazi mpv file-roller base-devel sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg ttt

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