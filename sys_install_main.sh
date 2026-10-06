#!/bin/bash
# =================================================
# Arch Linux 安装脚本 (chroot 前)
# 在 Arch ISO 环境中以 root 身份运行
# =================================================

set -e  # 遇到错误立即退出

echo ">>> 1. 检查 UEFI 启动模式..."
ls /sys/firmware/efi >/dev/null 2>&1 || {
    echo "错误：请在 UEFI 模式下启动安装介质。"
    exit 1
}

echo ">>> 2. 检查网络连接..."
ping -c 2 archlinux.org >/dev/null 2>&1 || {
    echo "错误：无网络连接。请先连接网络。"
    exit 1
}

echo ">>> 3. 使用 reflector 优化镜像列表 (官方仓库)..."
# 安装 reflector 和 rsync (如尚未安装)
pacman -S --noconfirm --needed reflector rsync curl

# 使用 reflector 筛选最新、最快的 HTTPS 镜像
reflector --verbose \
    --latest 20 \
    --protocol https \
    --age 12 \
    --sort rate \
    --save /etc/pacman.d/mirrorlist

echo ">>> 4. 安装基础系统 (使用 linux-zen 内核)..."
# 刷新密钥环
pacman -Sy --noconfirm archlinux-keyring

# 安装基础系统 + 必要工具
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware \
    vim networkmanager grub efibootmgr \
    libnotify xdg-desktop-portal-hyprland hyprpolkitagent qt5-wayland qt6-wayland \
    hyprlang hyprlock hyprpaper hyprland aquamarine rofi sddm qt6-svg \
    qt6-virtualkeyboard qt6-multimedia-ffmpeg ffmpeg fastfetch cmatrix lolcat \
    zsh zsh-doc zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search zsh-autocomplete zshdb git-zsh-completion zoxide \
    starship bluez blueman yazi figlet \
    gnome-disk-utility baobab loupe btop grim nwg-look nautilus kitty dms-shell-hyprland

echo ">>> 6. 生成 fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo ">>> chroot 前阶段完成。现在可以执行: arch-chroot /mnt"