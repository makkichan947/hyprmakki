#!/bin/bash
# =================================================
# Arch Linux 分区脚本 (chroot 前, 带 TUI)
# 方案: UEFI + LUKS(可选) + btrfs 子卷
# 在 Arch ISO 环境中以 root 身份运行
# =================================================

set -uo pipefail

# ================= 全局变量 =================
CRYPT_NAME="cryptroot"
DISK=""
EFI_PART=""
ROOT_PART=""
ROOT_DEV=""
USE_LUKS=1
SUCCESS=0

# ================= 清理函数 =================
cleanup() {
    local exit_code=$?
    if [[ $SUCCESS -eq 1 ]]; then
        return
    fi
    echo ""
    echo ">>> 检测到异常退出，正在清理..."
    umount -R /mnt 2>/dev/null || true
    cryptsetup close "${CRYPT_NAME}" 2>/dev/null || true
    echo ">>> 清理完成。"
    exit $exit_code
}
trap cleanup EXIT INT TERM

# ================= 工具函数 =================
# 根据磁盘名推断分区名（处理 nvme/sda/mmcblk 差异）
get_part_name() {
    local disk="$1" num="$2"
    if [[ "$disk" =~ [0-9]$ ]]; then
        echo "${disk}p${num}"
    else
        echo "${disk}${num}"
    fi
}

# 检查依赖
check_deps() {
    local missing=()
    for cmd in dialog sgdisk cryptsetup mkfs.fat mkfs.btrfs lsblk partprobe findmnt; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "缺少依赖: ${missing[*]}"
        pacman -S --noconfirm dialog gptfdisk cryptsetup btrfs-progs dosfstools"
        exit 1
    fi
}

# ================= 1. 选择磁盘 =================
select_disk() {
    local -a disk_items=()
    while IFS= read -r line; do
        local dev size model
        dev=$(awk '{print $1}' <<<"$line")
        size=$(awk '{print $2}' <<<"$line")
        model=$(awk '{$1="";$2="";print}' <<<"$line" | xargs)
        disk_items+=("$dev" "${size}  ${model}")
    done < <(lsblk -dpno NAME,SIZE,MODEL | grep -vE 'loop|rom|zram')

    if [[ ${#disk_items[@]} -eq 0 ]]; then
        dialog --msgbox "未检测到可用磁盘！" 6 40
        exit 1
    fi

    DISK=$(dialog --stdout --title "选择目标磁盘" \
        --menu "请选择要安装 Arch Linux 的磁盘:\n\n⚠️  警告: 该磁盘上的所有数据将被擦除!" \
        20 70 10 "${disk_items[@]}")

    [[ -z "$DISK" ]] && { echo "未选择磁盘，退出。"; exit 0; }
}

# ================= 2. 二次确认 =================
confirm_wipe() {
    dialog --title "⚠️  警告" --yesno \
        "即将擦除磁盘 ${DISK} 上的所有数据！\n\n是否继续？" 10 60 \
        || { echo "用户取消。"; exit 0; }

    local typed
    typed=$(dialog --stdout --title "确认操作" \
        --inputbox "请输入 YES (全大写) 以确认擦除 ${DISK}:" 10 60)
    [[ "$typed" != "YES" ]] && { echo "确认失败，退出。"; exit 0; }
}

# ================= 3. 选择加密 =================
select_encryption() {
    if dialog --title "LUKS 加密" --yesno \
        "是否为根分区启用 LUKS2 加密？\n\n建议 GPD 等便携设备启用。" 10 60; then
        USE_LUKS=1
    else
        USE_LUKS=0
    fi
}

# ================= 4. 分区 =================
partition_disk() {
    echo ">>> 正在分区 ${DISK} ..."
    wipefs -af "$DISK" &>/dev/null || true
    sgdisk --zap-all "$DISK" &>/dev/null

    # p1: EFI 512M, p2: 剩余空间
    sgdisk --new=1:0:+512M --typecode=1:ef00 --change-name=1:EFI  "$DISK"
    sgdisk --new=2:0:0     --typecode=2:8300 --change-name=2:ROOT "$DISK"

    partprobe "$DISK"
    udevadm settle 2>/dev/null || sleep 2

    EFI_PART=$(get_part_name "$DISK" 1)
    ROOT_PART=$(get_part_name "$DISK" 2)

    echo ">>> EFI 分区: $EFI_PART"
    echo ">>> 根分区:   $ROOT_PART"
}

# ================= 5. 格式化 =================
format_partitions() {
    echo ">>> 格式化 EFI 分区为 FAT32..."
    mkfs.fat -F32 -n EFI "$EFI_PART"

    if [[ $USE_LUKS -eq 1 ]]; then
        echo ">>> 设置 LUKS 加密..."
        local pass1 pass2
        while true; do
            pass1=$(dialog --stdout --insecure --passwordbox "设置 LUKS 加密密码:" 10 60)
            [[ -z "$pass1" ]] && { dialog --msgbox "密码不能为空！" 6 40; continue; }
            pass2=$(dialog --stdout --insecure --passwordbox "再次输入密码确认:" 10 60)
            [[ "$pass1" == "$pass2" ]] && break
            dialog --msgbox "两次密码不一致，请重试。" 6 40
        done

        echo -n "$pass1" | cryptsetup luksFormat --type luks2 \
            -s 512 -c aes-xts-plain64 "$ROOT_PART" -
        echo -n "$pass1" | cryptsetup open "$ROOT_PART" "$CRYPT_NAME" -
        unset pass1 pass2

        ROOT_DEV="/dev/mapper/${CRYPT_NAME}"
    else
        ROOT_DEV="$ROOT_PART"
    fi

    echo ">>> 格式化根分区为 btrfs..."
    mkfs.btrfs -f -L "arch" "$ROOT_DEV"
}

# ================= 6. 创建子卷并挂载 =================
mount_filesystems() {
    local btrfs_opts="noatime,compress=zstd:3"

    echo ">>> 创建 btrfs 子卷..."
    mount "$ROOT_DEV" /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    btrfs subvolume create /mnt/@var_log
    btrfs subvolume create /mnt/@var_cache_pacman
    btrfs subvolume create /mnt/@devel
    umount /mnt

    echo ">>> 挂载 btrfs 子卷..."
    mount -o "${btrfs_opts},subvol=@" "$ROOT_DEV" /mnt
    mkdir -p /mnt/{home,.snapshots,boot}
    mkdir -p /mnt/home/yakumakki/Devel
    mkdir -p /mnt/var/{log,cache/pacman/pkg,lib/libvirt,lib/docker}

    mount -o "${btrfs_opts},subvol=@home"              "$ROOT_DEV" /mnt/home
    mount -o "${btrfs_opts},subvol=@snapshots"         "$ROOT_DEV" /mnt/.snapshots
    mount -o "${btrfs_opts},subvol=@var_log"           "$ROOT_DEV" /mnt/var/log
    mount -o "${btrfs_opts},subvol=@var_cache_pacman"  "$ROOT_DEV" /mnt/var/cache/pacman/pkg
    mount -o "${btrfs_opts},subvol=@devel"    "$ROOT_DEV" /mnt/home/yakumakki/Devel

    echo ">>> 挂载 EFI 分区..."
    mount "$EFI_PART" /mnt/boot

    echo ""
    echo ">>> 当前挂载状态:"
    findmnt -R /mnt
}

# ================= 主流程 =================
main() {
    [[ $EUID -ne 0 ]] && { echo "请以 root 身份运行此脚本。"; exit 1; }
    check_deps

    select_disk
    confirm_wipe
    select_encryption

    partition_disk
    format_partitions
    mount_filesystems

    SUCCESS=1

    dialog --title "✅ 分区完成" --msgbox \
"分区、格式化与挂载完成！

EFI 分区:   ${EFI_PART}  ->  /mnt/boot
根分区:     ${ROOT_PART}
LUKS:       $([[ $USE_LUKS -eq 1 ]] && echo '已启用' || echo '未启用')
映射设备:   ${ROOT_DEV}

btrfs 子卷:
  @                ->  /
  @home            ->  /home
  @snapshots       ->  /.snapshots
  @var_log         ->  /var/log
  @var_cache_pacman->  /var/cache/pacman/pkg

接下来可以执行 pacstrap 安装基础系统。" 22 70

    echo ""
    echo ">>> 分区脚本执行完毕，/mnt 已挂载就绪。"
    echo ">>> 下一步可执行主安装程序。"
}

main "$@"