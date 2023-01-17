#!/bin/bash
# Русские шрифты
setfont cyr-sun16
sed -i "s/#\(en_US\.UTF-8\)/\1/; s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen
locale-gen
export LANG=ru_RU.UTF-8

clear

# Синхронизация системных часов
timedatectl set-ntp true

# --- Переменные

DISK=/dev/sda
DISK_EFI=/dev/sda1
DISK_MNT=/dev/sda2

# Базовые пакеты в /mnt
PKGS=(
  base base-devel reflector pacman-contrib openssh
#  linux linux-headers
  linux-zen linux-zen-headers
#  linux-lts linux-lts-headers
  linux-firmware
  zsh git wget vim neovim
  ntfs-3g exfat-utils dosfstools mtools # Поддержка NTFS, exFAT, vFAT, MS-DOS дисков
#  os-prober # Для Dual-Boot
  grub efibootmgr
  iptables-nft nftables
  networkmanager modemmanager netctl # Для подключения к wifi с ноута: sudo nmtui
#  wpa_supplicant wireless_tools # Пакеты для ноутбуков
#  dhcpcd
  intel-ucode
  xdg-user-dirs # Создание пользовательских XDG директории
  terminus-font # Шрифты разных размеров с кириллицей для tty
  ccache
  zram-generator
  dbus-broker # Оптимизированная система шины сообщений
)

read -p "Имя хоста (hostname): " HOST_NAME
export HOST_NAME

read -p "Имя пользователя (Может быть только в нижнем регистре и без знаков): " USER_NAME
export USER_NAME

read -p "Пароль пользователя: " USER_PASSWORD
export USER_PASSWORD

read -p "Sudo с запросом пароля? [y/n]: " SUDO_PRIV
export SUDO_PRIV

read -p "Тип смены раскладки клавиатуры
1 - Alt+Shift, 2 - Caps Lock: " XKB_LAYOUT
export XKB_LAYOUT

read -p "Файловая система
1 - ext4, 2 - btrfs: " FS
export FS

# Обнаружение часового пояса
export time_zone=$(curl -s https://ipinfo.io/timezone)

# --- Разметка файловая система

# Удаляем старую схему разделов и перечитываем таблицу разделов
sgdisk --zap-all --clear $DISK  # Удаляет (уничтожает) структуры данных GPT и MBR
wipefs --all --force $DISK # Стирает все доступные сигнатуры
partprobe $DISK # Информировать ОС об изменениях в таблице разделов

# Разметка диска и перечитываем таблицу разделов
sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:boot $DISK
sgdisk -n 0:0:0 -t 0:8300 -c 0:root $DISK
partprobe $DISK # Информировать ОС об изменениях в таблице разделов


# Файловая система
if [ ${FS} = '1' ]; then
  yes | mkfs.ext4 -L ArchLinux $DISK_MNT
  # yes | mkfs.ext4 -L home $H_DISK
  mount -v $DISK_MNT /mnt
  # mkdir /mnt/home
  # mount $H_DISK /mnt/home

  # При обнаружении приплюсовывается в список для pacstrap
  PKGS+=(e2fsprogs)
elif [ ${FS} = '2' ]; then
  mkfs.btrfs -L ArchLinux -f $DISK_MNT
  mount -v $DISK_MNT /mnt
  
  # Создание подтомов BTRFS
  btrfs su cr /mnt/@
  btrfs su cr /mnt/@home
  btrfs su cr /mnt/@snapshots
  btrfs su cr /mnt/@var_log
  btrfs su cr /mnt/@libvirt
  umount -v /mnt

  # BTRFS сам обнаруживает SSD при монтировании
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@ $DISK_MNT /mnt
  mkdir -pv /mnt/{home,.snapshots,var/log,var/lib/libvirt}
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@home $DISK_MNT /mnt/home
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@snapshots $DISK_MNT /mnt/.snapshots
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_log $DISK_MNT /mnt/var/log
  mount -v -o noatime,nodatacow,compress=zstd:2,space_cache=v2,subvol=@libvirt $DISK_MNT /mnt/var/lib/libvirt

  # При обнаружении приплюсовывается в список для pacstrap
  PKGS+=(btrfs-progs)
else
  echo "FS type"; exit 1
fi

# --- Форматирование и монтирование EFI/boot раздела
yes | mkfs.fat -F32 -n BOOT $DISK_EFI
mount -v --mkdir $DISK_EFI /mnt/boot/efi


sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Делаем pacman красивее
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Добавляем цвета в pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 10/g" /etc/pacman.conf  # Увеличение паралельных загрузок с 5 на 10
sed -i "s/#VerbosePkgLists/VerbosePkgLists/g" /etc/pacman.conf # Более удобный просмотр лист пакетов

# Оптимизация зеркал с помощью Reflector
reflector --verbose -c ru -p http,https -l 12 --sort rate --save /etc/pacman.d/mirrorlist
#echo "Server = https://mirror.yandex.ru/archlinux/\$repo/os/\$arch
#Server = http://mirror.yandex.ru/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

# Синхронизация базы пакетов
pacman -Syy

# Установка базовых пакетов в /mnt
pacstrap /mnt "${PKGS[@]}"

# Генерирую fstab
genfstab -U /mnt >> /mnt/etc/fstab
# Make /tmp a ramdisk
echo "
tmpfs 	/tmp	tmpfs		rw,nodev,nosuid,noatime,size=8G,mode=1777	 0 0" >> /mnt/etc/fstab

# Обнаружение виртуалки
export hypervisor=$(systemd-detect-virt)

# --- Chroot'имся
curl -o /mnt/chroot.sh https://raw.githubusercontent.com/anzix/scriptinstall/main/chroot.sh
chmod +x /mnt/chroot.sh
arch-chroot /mnt /bin/bash /chroot.sh

# Действия после chroot
if read -re -p "arch-chroot /mnt? [y/N]: " ans && [[ $ans == 'y' || $ans == 'Y' ]]; then
  arch-chroot /mnt
else
  umount -a # (-a) - безопасно размонтировать всё
fi
