#!/bin/bash
# Русские шрифты
setfont cyr-sun16
sed -i "s/#\(en_US\.UTF-8\)/\1/; s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen
locale-gen
export LANG=ru_RU.UTF-8

clear

# Синхронизация часов материнской платы
timedatectl set-ntp true

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

read -p "Имя хоста (пустое поле - arch): " HOST_NAME
export HOST_NAME=${HOST_NAME:-arch}

read -p "Имя пользователя (Может быть только в нижнем регистре и без знаков, пустое поле - user): " USER_NAME
export USER_NAME=${USER_NAME:-user}

read -p "Пароль пользователя: " USER_PASSWORD
export USER_PASSWORD

read -p "Sudo с запросом пароля? [y/n]: " SUDO_PRIV
export SUDO_PRIV

PS3="Тип смены раскладки клавиатуры: "
select ENTRY in "Alt+Shift" "Caps Lock"; do
	export XKB_LAYOUT=${ENTRY}
	echo "Выбран ${XKB_LAYOUT}"
	break
done

PS3="Выберите диск, на который будет установлен Arch Linux: "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd"); do
	export DISK=$ENTRY
	export DISK_EFI=${DISK}1
	export DISK_MNT=${DISK}2
	echo "Установка Arch Linux на ${DISK}."
	break
done

PS3="Выберите файловую систему: "
select ENTRY in "ext4" "btrfs"; do
	export FS=$ENTRY
	echo "Выбран ${FS}."
	break
done

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
if [ ${FS} = 'ext4' ]; then
  yes | mkfs.ext4 -L ArchLinux $DISK_MNT
  # yes | mkfs.ext4 -L home $H_DISK
  mount -v $DISK_MNT /mnt
  # mkdir /mnt/home
  # mount $H_DISK /mnt/home

  # При обнаружении приплюсовывается в список для pacstrap
  PKGS+=(e2fsprogs)
elif [ ${FS} = 'btrfs' ]; then
  mkfs.btrfs -L ArchLinux -f $DISK_MNT
  mount -v $DISK_MNT /mnt

  # Создание подтомов BTRFS
  btrfs su cr /mnt/@
  btrfs su cr /mnt/@home
  btrfs su cr /mnt/@snapshots
  mkdir -pv /mnt/@snapshots/1
  btrfs su cr /mnt/@snapshots/1/snapshot
  btrfs su cr /mnt/@root
  btrfs su cr /mnt/@srv
  btrfs su cr /mnt/@var_log
  btrfs su cr /mnt/@var_log_journal
  btrfs su cr /mnt/@var_crash
  btrfs su cr /mnt/@var_cache
  btrfs su cr /mnt/@var_tmp
  btrfs su cr /mnt/@var_spool
  btrfs su cr /mnt/@var_lib_machines
  btrfs su cr /mnt/@var_lib_libvirt_images
  btrfs su cr /mnt/@var_lib_AccountsService
  btrfs su cr /mnt/@var_lib_gdm

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
  mount -v -o noatime,compress=zstd:2,space_cache=v2 $DISK_MNT /mnt
  mkdir -pv /mnt/{home,root,.snapshots,srv,tmp,var/log,var/log/journal,var/crash,var/cache,var/tmp,var/spool,var/lib/libvirt/images,var/lib/machines,var/lib/AccountsService,var/lib/gdm}
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@home $DISK_MNT /mnt/home
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@snapshots $DISK_MNT /mnt/.snapshots
  mount -v -o noatime,compress=zstd:2,space_cache=v2,nodev,nosuid,subvol=@root $DISK_MNT /mnt/root
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@srv $DISK_MNT /mnt/srv
  mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_log_journal $DISK_MNT /mnt/var/log/journal
  mount -v -o noatime,compress=zstd:2,space_cache=v2,nodev,nosuid,noexec,subvol=@var_crash $DISK_MNT /mnt/var/crash
  mount -v -o noatime,compress=zstd:2,space_cache=v2,nodev,nosuid,noexec,subvol=@var_cache $DISK_MNT /mnt/var/cache
  mount -v -o noatime,compress=zstd:2,space_cache=v2,nodev,nosuid,subvol=@var_tmp $DISK_MNT /mnt/var/tmp
  mount -v -o noatime,compress=zstd:2,space_cache=v2,nodev,nosuid,noexec,subvol=@var_spool $DISK_MNT /mnt/var/spool
  mount -v -o noatime,compress=zstd:2,space_cache=v2,nodev,nosuid,noexec,subvol=@var_log $DISK_MNT /mnt/var/log
  mount -v -o noatime,compress=zstd:2,space_cache=v2,nodev,nosuid,noexec,subvol=@var_lib_machines $DISK_MNT /mnt/var/lib/machines
  mount -v -o noatime,nodatacow,compress=zstd:2,space_cache=v2,nodev,nosuid,noexec,subvol=@var_lib_libvirt_images $DISK_MNT /mnt/var/lib/libvirt/images
  mount -v -o noatime,compress=zstd:2,space_cache=v2,nodev,nosuid,noexec,subvol=@var_lib_AccountsService $DISK_MNT /mnt/var/lib/AccountsService
  mount -v -o noatime,compress=zstd:2,space_cache=v2,nodev,nosuid,noexec,subvol=@var_lib_gdm $DISK_MNT /mnt/var/lib/gdm

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

# Синхронизация базы пакетов
pacman -Sy

# Установка базовых пакетов в /mnt
pacstrap -K /mnt "${PKGS[@]}"

# Генерирую fstab
genfstab -U /mnt >> /mnt/etc/fstab
# Make /tmp a ramdisk
echo "
tmpfs 	/tmp	tmpfs		rw,nodev,nosuid,noatime,size=8G,mode=1777	 0 0" >> /mnt/etc/fstab

sed -i 's/rootflags=subvol=${rootsubvol} //g' /mnt/etc/grub.d/10_linux /mnt/etc/grub.d/20_linux_xen

# Обнаружение виртуалки
export hypervisor=$(systemd-detect-virt)

# Настройка и chroot
cp -r /root/scriptinstall /mnt/
arch-chroot /mnt /bin/bash /scriptinstall/chroot.sh

# Действия после chroot
if read -re -p "arch-chroot /mnt? [y/N]: " ans && [[ $ans == 'y' || $ans == 'Y' ]]; then
  arch-chroot /mnt
else
  umount -R /mnt # (-a) - безопасно размонтировать всё
fi
