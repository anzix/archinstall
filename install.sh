#!/bin/bash
# Русские шрифты
setfont cyr-sun16
sed -i "s/#\(en_US\.UTF-8\)/\1/; s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen
locale-gen
export LANG=ru_RU.UTF-8

clear

# Синхронизация часов материнской платы
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
  man-pages man-db # Мануалы
  terminus-font # Шрифты разных размеров с кириллицей для tty
  ccache
  zram-generator
  dbus-broker # Оптимизированная система шины сообщений
  plocate # Более быстрая альтернатива locate
)

read -p "Имя хоста (hostname): " HOST_NAME
export HOST_NAME=${HOST_NAME:-arch}

read -p "Имя пользователя (Может быть только в нижнем регистре и без знаков): " USER_NAME
export USER_NAME=${USER_NAME:-user}

read -p "Пароль пользователя: " USER_PASSWORD
export USER_PASSWORD

read -p "Sudo с запросом пароля? [y/n]: " SUDO_PRIV
export SUDO_PRIV

read -p "Тип смены раскладки клавиатуры
1 - Alt+Shift (по дефолту), 2 - Caps Lock: " XKB_LAYOUT
export XKB_LAYOUT=${XKB_LAYOUT:-1}

read -p "Файловая система
1 - ext4 (по дефолту), 2 - btrfs: " FS
export FS=${FS:-1}

# Обнаружение часового пояса
export time_zone=$(curl -s https://ipinfo.io/timezone)

# --- Разметка файловая система

# Удаляем старую схему разделов и перечитываем таблицу разделов
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
  mkdir -pv /mnt/@snapshots/1
  btrfs su cr /mnt/@snapshots/1/snapshot
  btrfs su cr /mnt/@var_log
  btrfs su cr /mnt/@var_lib_machines
  btrfs su cr /mnt/@var_lib_libvirt_images

  #Set the default BTRFS Subvol to Snapshot 1 before pacstrapping
  btrfs subvolume set-default "$(btrfs subvolume list /mnt | grep "@snapshots/1/snapshot" | grep -oP '(?<=ID )[0-9]+')" /mnt

  DATE=$(date +"%Y-%m-%d %H:%M:%S")
  cat << EOF >> /mnt/@snapshots/1/info.xml
<?xml version="1.0"?>
<snapshot>
  <type>single</type>
  <num>1</num>
  <date>${DATE}</date>
  <description>First Root Filesystem</description>
  <cleanup>number</cleanup>
</snapshot>
EOF

  chmod -v 600 /mnt/@snapshots/1/info.xml


  umount -v /mnt

  # BTRFS сам обнаруживает SSD при монтировании
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@ $DISK_MNT /mnt
  mkdir -pv /mnt/{home,.snapshots,var/log,var/lib/libvirt/images,var/lib/machines}
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@home $DISK_MNT /mnt/home
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@snapshots $DISK_MNT /mnt/.snapshots
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_log $DISK_MNT /mnt/var/log
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_lib_machines $DISK_MNT /mnt/var/lib/machines
  mount -v -o noatime,nodatacow,compress=zstd:2,space_cache=v2,subvol=@var_lib_libvirt_images $DISK_MNT /mnt/var/lib/libvirt/images

  # При обнаружении приплюсовывается в список для pacstrap
  PKGS+=(btrfs-progs snapper)
else
  echo "FS type"; exit 1
fi

# --- Форматирование и монтирование загрузочного раздела
yes | mkfs.fat -F32 -n BOOT $DISK_EFI
mount -v --mkdir $DISK_EFI /mnt/boot/efi


sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Делаем pacman красивее
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Добавляем цвета в pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 8/g" /etc/pacman.conf  # Увеличение паралельных загрузок с 5 на 8
sed -i "s/#VerbosePkgLists/VerbosePkgLists/g" /etc/pacman.conf # Более удобный просмотр лист пакетов

# Оптимизация зеркал с помощью Reflector
reflector --verbose -c ru -p http,https -l 12 --sort rate --save /etc/pacman.d/mirrorlist
#echo "Server = https://mirror.yandex.ru/archlinux/\$repo/os/\$arch
#Server = http://mirror.yandex.ru/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

# Синхронизация базы пакетов
pacman -Sy

# Установка базовых пакетов в /mnt
pacstrap -K /mnt "${PKGS[@]}"

# Генерирую fstab
genfstab -U /mnt >> /mnt/etc/fstab
# Make /tmp a ramdisk
echo "
tmpfs 	/tmp	tmpfs		rw,nodev,nosuid,noatime,size=8G,mode=1777	 0 0" >> /mnt/etc/fstab


echo -e "# Booting with BTRFS subvolume\nGRUB_BTRFS_OVERRIDE_BOOT_PARTITION_DETECTION=true" >> /mnt/etc/default/grub
sed -i 's/rootflags=subvol=${rootsubvol} //g' /mnt/etc/grub.d/10_linux /mnt/etc/grub.d/20_linux_xen

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
