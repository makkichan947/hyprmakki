#!/bin/zsh
# =================================================
# Arch Linux 配置脚本 (chroot 后)
# 在 arch-chroot /mnt 环境中以 root 身份运行
# =================================================

set -euo pipefail  # 遇到错误立即退出，管道错误也传播

# ================= 用户配置 =================
HOSTNAME="archintosh"
USERNAME="yakumakki"
TIMEZONE="Asia/Shanghai"
LOCALE="zh_CN.UTF-8"
# ============================================

echo ">>> 1. 设置时区..."
ln -sf /usr/share/zoneinfo/"${TIMEZONE}" /etc/localtime && hwclock --systohc

echo ">>> 2. 配置本地化 (locale)..."
sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf

echo ">>> 3. 设置键盘布局..."
echo "KEYMAP=us" > /etc/vconsole.conf

echo ">>> 4. 设置主机名..."
echo "${HOSTNAME}" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

echo ">>> 5. 设置 root 密码..."
passwd

echo ">>> 6. 创建用户 ${USERNAME}..."
useradd -m -G wheel -s /bin/zsh "${USERNAME}"
echo "请设置用户 ${USERNAME} 的密码："
passwd "${USERNAME}"
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# ---------- 7. 扩展官方仓库中国镜像源 ----------
echo ">>> 7. 配置官方仓库中国镜像源..."
cat > /etc/pacman.d/mirrorlist <<'MIRRORLIST'
## China mirrors (sorted by priority)
Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch
Server = https://mirrors.nju.edu.cn/archlinux/$repo/os/$arch
Server = https://mirror.sjtu.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.hust.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.hit.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.jlu.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.xjtu.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.wsyu.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.qlu.edu.cn/archlinux/$repo/os/$arch
Server = https://repo.huaweicloud.com/archlinux/$repo/os/$arch
MIRRORLIST

echo ">>> 8. 配置 mkinitcpio (LUKS + GPD 屏幕旋转)..."
cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# ---------- 9. archlinuxcn 仓库 + 镜像列表 ----------
echo ">>> 9. 配置 archlinuxcn 仓库..."
# 创建 archlinuxcn 镜像列表
mkdir -p /etc/pacman.d
cat > /etc/pacman.d/archlinuxcn-mirrorlist <<'CNMIRROR'
## Arch Linux CN community repository mirrorlist
Server = https://mirrors.bfsu.edu.cn/archlinuxcn/$arch
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
Server = https://mirrors.aliyun.com/archlinuxcn/$arch
Server = https://mirror.sjtu.edu.cn/archlinux-cn/$arch
Server = https://mirrors.nju.edu.cn/archlinuxcn/$arch
Server = https://mirrors.hust.edu.cn/archlinuxcn/$arch
Server = https://mirrors.hit.edu.cn/archlinuxcn/$arch
Server = https://mirrors.jlu.edu.cn/archlinuxcn/$arch
Server = https://mirrors.xjtu.edu.cn/archlinuxcn/$arch
Server = https://mirrors.wsyu.edu.cn/archlinuxcn/$arch
Server = https://repo.huaweicloud.com/archlinuxcn/$arch
Server = https://mirrors.163.com/archlinux-cn/$arch
CNMIRROR

# 在 pacman.conf 中添加 archlinuxcn 仓库（引用镜像列表）
cat >> /etc/pacman.conf <<'EOF'

[archlinuxcn]
Include = /etc/pacman.d/archlinuxcn-mirrorlist
EOF

# 导入 archlinuxcn GPG 密钥
pacman -Sy --noconfirm archlinuxcn-keyring

# ---------- 10. blackarch 仓库 + 镜像列表 ----------
echo ">>> 10. 配置 blackarch 仓库..."
cat > /etc/pacman.d/blackarch-mirrorlist <<'BAMIRROR'
## BlackArch mirrorlist - China
Server = https://mirrors.bfsu.edu.cn/blackarch/$repo/os/$arch
Server = https://mirrors.ustc.edu.cn/blackarch/$repo/os/$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/blackarch/$repo/os/$arch
Server = https://mirrors.aliyun.com/blackarch/$repo/os/$arch
Server = https://mirror.sjtu.edu.cn/blackarch/$repo/os/$arch
Server = https://mirrors.nju.edu.cn/blackarch/$repo/os/$arch
Server = https://mirrors.hust.edu.cn/blackarch/$repo/os/$arch
Server = https://mirrors.xjtu.edu.cn/blackarch/$repo/os/$arch
BAMIRROR

cat >> /etc/pacman.conf <<'EOF'

[blackarch]
Include = /etc/pacman.d/blackarch-mirrorlist
EOF

# 启用 multilib (BlackArch 部分软件依赖 32 位库)
sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf

# 导入 BlackArch GPG 密钥
pacman-key --recv-keys 7533BAFE69A25079
pacman-key --finger 7533BAFE69A25079
pacman-key --lsign-key 7533BAFE69A25079
pacman -Sy --noconfirm blackarch-keyring

# ---------- 11. 安装 yay (AUR Helper) ----------
echo ">>> 11. 安装 yay..."
# 确保 base-devel 和 git 已安装（chroot 前脚本应已包含，此处作保险）
pacman -S --noconfirm --needed base-devel git

# 以普通用户身份编译安装 yay（AUR 包不能在 root 下 makepkg）
YAY_BUILD_DIR="/tmp/yay-build"
rm -rf "${YAY_BUILD_DIR}"
git clone https://aur.archlinux.org/yay.git "${YAY_BUILD_DIR}"
chown -R "${USERNAME}:${USERNAME}" "${YAY_BUILD_DIR}"

# 切换到用户执行 makepkg
sudo -u "${USERNAME}" bash -c "
    cd ${YAY_BUILD_DIR}
    makepkg -si --noconfirm
"

# 清理构建目录
rm -rf "${YAY_BUILD_DIR}"

# 验证 yay 可用
if command -v yay &>/dev/null; then
    echo "  ✓ yay 安装成功: $(yay --version | head -1)"
else
    echo "  ✗ yay 安装失败，请手动检查。"
fi

# ---------- 12. 启用必要服务 ----------
echo ">>> 12. 启用必要服务..."
systemctl enable NetworkManager

# ---------- 13. GRUB 引导配置提示 ----------
echo ">>> 13. GRUB 引导配置 (请自行完成)..."
echo "  提示：需要编辑 /etc/default/grub 并设置 cryptdevice 参数。"
echo "  示例："
echo "    GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=<你的根分区UUID>:cryptroot root=/dev/mapper/cryptroot\""
echo "    GRUB_ENABLE_CRYPTODISK=y"
echo "  然后执行: grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB"
echo "  最后执行: grub-mkconfig -o /boot/grub/grub.cfg"

# ---------- 14. reflector 自动更新 ----------
echo ">>> 14. 配置 reflector 自动更新..."
mkdir -p /etc/xdg/reflector
cat > /etc/xdg/reflector/reflector.conf <<'EOF'
--country China
--latest 20
--protocol https
--age 12
--sort rate
--save /etc/pacman.d/mirrorlist
EOF

systemctl enable reflector.timer

echo ">>> 15. 执行次安装程序..."
chmod +x ./install.sh
./install.sh

echo ""
echo ">>> chroot 后阶段完成。"
echo "    退出 chroot: exit"
echo "    卸载并重启: umount -R /mnt && reboot"