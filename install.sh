#!/bin/bash

# Позаимствовано
# https://github.com/creio/dots/blob/master/.bin/creio.sh
# https://github.com/gjpin/arch-linux
# https://github.com/YurinDoctrine/arch-linux-base-setup/

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
 base base-devel
# linux linux-headers
 linux-zen linux-zen-headers
# linux-lts linux-lts-headers
 linux-firmware
 zsh
 wget
 grub efibootmgr
 intel-ucode
 xdg-user-dirs # Создание пользовательских XDG директории
 ccache # Ускоряет перекомпиляцию за счет кэширования предыдущих компиляций
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
select ENTRY in $(lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd"); do
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

PS3="Выберите окружение: "
select ENTRY in "plasma" "gnome" "i3wm"; do
	export DESKTOP_ENVIRONMENT=$ENTRY
	echo "Выбран ${DESKTOP_ENVIRONMENT}."
	break
done

read -p "Gaming (y/n): " GAMING
export GAMING

# Обнаружение часового пояса
export time_zone=$(curl -s https://ipinfo.io/timezone)

# Обнаружение виртуалки
export hypervisor=$(systemd-detect-virt)

# Удаляем старую схему разделов и перечитываем таблицу разделов
sgdisk --zap-all --clear $DISK # Удаляет (уничтожает) структуры данных GPT и MBR
wipefs --all --force $DISK # Стирает все доступные сигнатуры
partprobe $DISK

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

	# При обнаружении добавляется в список для pacstrap
	PKGS+=(e2fsprogs)
elif [ ${FS} = 'btrfs' ]; then
	mkfs.btrfs -L ArchLinux -f $DISK_MNT
	mount -v $DISK_MNT /mnt

	# Создание подтомов BTRFS
	btrfs su cr /mnt/@
	btrfs su cr /mnt/@home
	btrfs su cr /mnt/@snapshots
	btrfs su cr /mnt/@var_log
	btrfs su cr /mnt/@var_lib_machines
	btrfs su cr /mnt/@var_lib_libvirt_images

	if [[ ${DESKTOP_ENVIRONMENT} = 'gnome' ]]; then
		btrfs su cr /mnt/@var_lib_AccountsService
		btrfs su cr /mnt/@var_lib_gdm
	fi

	umount -v /mnt

	# BTRFS сам обнаруживает SSD при монтировании
	mount -v -o noatime,compress=zstd:2,space_cache=v2 $DISK_MNT /mnt
	mkdir -pv /mnt/{home,.snapshots,var/log,var/lib/libvirt/images,var/lib/machines}
	mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@home $DISK_MNT /mnt/home
	mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@snapshots $DISK_MNT /mnt/.snapshots
	mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_log $DISK_MNT /mnt/var/log
	mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_lib_machines $DISK_MNT /mnt/var/lib/machines
	mount -v -o noatime,nodatacow,compress=zstd:2,space_cache=v2,subvol=@var_lib_libvirt_images $DISK_MNT /mnt/var/lib/libvirt/images

	if [[ ${DESKTOP_ENVIRONMENT} = 'gnome' ]]; then
		mkdir -pv /mnt/{var/lib/AccountsService,var/lib/gdm}
		mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_lib_AccountsService $DISK_MNT /mnt/var/lib/AccountsService
		mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_lib_gdm $DISK_MNT /mnt/var/lib/gdm
	fi

	# При обнаружении добавляется в список для pacstrap
	PKGS+=(btrfs-progs snapper)
else
	echo "FS type"
	exit 1
fi

# Форматирование и монтирование загрузочного раздела
yes | mkfs.fat -F32 -n BOOT $DISK_EFI
mount -v --mkdir $DISK_EFI /mnt/boot/efi

sed -i "/#Color/a ILoveCandy" /etc/pacman.conf # Делаем pacman красивее
sed -i "s/#Color/Color/g" /etc/pacman.conf # Добавляем цвета в pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 8/g" /etc/pacman.conf # Увеличение паралельных загрузок с 5 на 8
sed -i "s/#VerbosePkgLists/VerbosePkgLists/g" /etc/pacman.conf # Более удобный просмотр лист пакетов

# Оптимизация зеркал с помощью Reflector
reflector --verbose -c ru -p http,https -l 12 --sort rate --save /etc/pacman.d/mirrorlist

# Синхронизация базы пакетов
pacman -Sy

# Установка базовых пакетов в /mnt
pacstrap -K /mnt "${PKGS[@]}"

# Генерирую fstab
genfstab -U /mnt >>/mnt/etc/fstab
# Make /tmp a ramdisk
echo "
tmpfs 	/tmp	tmpfs		rw,nodev,nosuid,noatime,size=8G,mode=1777	 0 0" >>/mnt/etc/fstab

# Настройка и chroot
cp -r /root/scriptinstall /mnt/
arch-chroot /mnt /bin/bash /scriptinstall/chroot.sh

# Действия после chroot
if read -re -p "arch-chroot /mnt? [y/N]: " ans && [[ $ans == 'y' || $ans == 'Y' ]]; then
	arch-chroot /mnt
else
	umount -a # (-a) - безопасно размонтировать всё
fi
