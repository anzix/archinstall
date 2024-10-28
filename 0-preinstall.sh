#!/bin/bash

# Позаимствовано
# https://github.com/creio/dots/blob/master/.bin/creio.sh
# https://github.com/gjpin/arch-linux
# https://github.com/YurinDoctrine/arch-linux-base-setup/
# https://github.com/TommyTran732/Arch-Setup-Script
# https://github.com/classy-giraffe/easy-arch/blob/main/easy-arch.sh

# раскомментируйте, чтобы просмотреть информацию об отладке
#set -xe

# Русские шрифты
setfont cyr-sun16
sed -i "s/#\(en_US\.UTF-8\)/\1/; s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen
locale-gen
export LANG=ru_RU.UTF-8

clear

# Синхронизация часов материнской платы
timedatectl set-ntp true

read -p "Имя хоста (пустое поле - arch): " HOST_NAME
export HOST_NAME=${HOST_NAME:-arch}

read -p "Имя пользователя (Может быть только в нижнем регистре и без знаков, пустое поле - user): " USER_NAME
export USER_NAME=${USER_NAME:-user}

read -p "Пароль пользователя (поле ввода видимое): " USER_PASSWORD
export USER_PASSWORD

read -p "Sudo с запросом пароля? [y/n]: " SUDO_PRIV
export SUDO_PRIV

PS3="На каком языке будет система?: "
select ENTRY in "ru_RU" "en_US"; do
	export LOCALE=${ENTRY}
	echo "Выбран ${LOCALE}"
	break
done

PS3="Тип смены раскладки клавиатуры: "
select ENTRY in "Alt+Shift" "Caps Lock"; do
	export XKB_LAYOUT=${ENTRY}
	echo "Выбран ${XKB_LAYOUT}"
	break
done

PS3="Выберите диск, на который будет установлен Arch Linux: "
select ENTRY in $(lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd"); do
	export DISK=$ENTRY
	echo "Arch Linux будет установлен на ${DISK}."
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

# Предупредить пользователя об удалении старой схемы разделов.
echo "СОДЕРЖИМОЕ ДИСКА ${DISK} БУДЕТ СТЁРТО!"
read -p "Вы уверены что готовы начать установку? [y/N]: "
if ! [[ ${REPLY} =~ ^(yes|y)$ ]]; then
    echo "Выход.."
    exit
fi

# Удаляем старую схему разделов и перечитываем таблицу разделов
sgdisk --zap-all --clear $DISK # Удаляет (уничтожает) структуры данных GPT и MBR
partprobe $DISK # Информировать ОС об изменениях в таблице разделов

# Разметка диска и перечитываем таблицу разделов
sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:boot $DISK
sgdisk -n 0:0:0 -t 0:8300 -c 0:root $DISK
partprobe $DISK

# Переменные для указывания созданных разделов
export DISK_EFI="/dev/disk/by-partlabel/boot"
export DISK_MNT="/dev/disk/by-partlabel/root"
# export DISK_HOME="/dev/disk/by-partlabel/home"

# Файловая система
if [ ${FS} = 'ext4' ]; then
	yes | mkfs.ext4 -L ArchLinux $DISK_MNT
	# Отдельный раздел под /home
	# yes | mkfs.ext4 -L home $DISK_HOME
	mount -v $DISK_MNT /mnt
	# mkdir /mnt/home
	# mount $DISK_HOME /mnt/home

	# При обнаружении добавляется в список для pacstrap
	echo "e2fsprogs" >> packages/base
elif [ ${FS} = 'btrfs' ]; then
	mkfs.btrfs -L ArchLinux -f $DISK_MNT
	mount -v $DISK_MNT /mnt

	# Создание подтомов BTRFS
	btrfs su cr /mnt/@
	btrfs su cr /mnt/@home
	btrfs su cr /mnt/@snapshots
	btrfs su cr /mnt/@home_snapshots
	btrfs su cr /mnt/@var_log
	btrfs su cr /mnt/@var_lib_containers
	btrfs su cr /mnt/@var_lib_docker
	btrfs su cr /mnt/@var_lib_machines
	btrfs su cr /mnt/@var_lib_portables
	btrfs su cr /mnt/@var_lib_libvirt_images
	btrfs su cr /mnt/@var_lib_AccountsService
	btrfs su cr /mnt/@var_lib_gdm

	umount -v /mnt

   # Небольшой обзор опций:
   #
   # noatime: нет времени доступа. Повышает производительность за счет отсутствия времени записи при обращении к файлу.
   # compress: активация сжатия для определённых типов файлов и выбор алгоритма сжатия
   # compress-force: активация принудительного сжатия для любого типа файлов и выбор алгоритма сжатия.
   # discard=async: освобождает неиспользуемый блок с SSD-накопителя, поддерживающего команду.
   #   При использовании параметра discard=async освобожденные экстенты не удаляются немедленно, а
   #   группируются вместе и позже обрезаются отдельным рабочим потоком, что снижает задержку commit.
   #   Вы можете отказаться от этого, если используете жесткий диск.
   #
   #   INFO: BTRFS с версией ядра 6.2 по умолчанию включена опция "discard=async"
   #
   # space_cache: позволяет ядру знать, где на диске находится блок свободного места, чтобы
   #   оно могло записывать данные сразу после создания файла.
   #
   # subvol: выбор вложенного тома для монтирования.
   #
   # INFO: BTRFS сам обнаруживает и добавляет опцию "ssd" при монтировании
	mount -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@ $DISK_MNT /mnt
	mount --mkdir -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@home $DISK_MNT /mnt/home
	mount --mkdir -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@snapshots $DISK_MNT /mnt/.snapshots
	mount --mkdir -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@home_snapshots $DISK_MNT /mnt/home/.snapshots
	mount --mkdir -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_log $DISK_MNT /mnt/var/log
	mount --mkdir -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_lib_containers $DISK_MNT /mnt/var/lib/containers
	mount --mkdir -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_lib_docker $DISK_MNT /mnt/var/lib/docker
	mount --mkdir -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_lib_machines $DISK_MNT /mnt/var/lib/machines
	mount --mkdir -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_lib_portables $DISK_MNT /mnt/var/lib/portables
	mount --mkdir -v -o noatime,nodatacow,compress=zstd:2,space_cache=v2,subvol=@var_lib_libvirt_images $DISK_MNT /mnt/var/lib/libvirt/images
	mount --mkdir -v -o noatime,compress=zstd:2,space_cache=v2,subvolid=5 $DISK_MNT /mnt/.btrfsroot
	mount --mkdir -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_lib_AccountsService $DISK_MNT /mnt/var/lib/AccountsService
	mount --mkdir -v -o noatime,compress=zstd:2,space_cache=v2,subvol=@var_lib_gdm $DISK_MNT /mnt/var/lib/gdm

	# Востановление прав доступа по требованию пакетов
	chmod -v 775 /mnt/var/lib/AccountsService/
	chmod -v 1770 /mnt/var/lib/gdm/

	# При обнаружении добавляется в список для pacstrap
	echo "snapper btrfs-progs" >> packages/base
else
	echo "FS type"
	exit 1
fi

# Форматирование и монтирование загрузочного раздела
# TODO: Изменить точку монтирования на /mnt/boot для стандартизации, также
# незабыть проделать изменения в других местах
yes | mkfs.fat -F32 -n BOOT $DISK_EFI
mount -v --mkdir $DISK_EFI /mnt/boot/efi

sed -i "/#Color/a ILoveCandy" /etc/pacman.conf # Делаем pacman красивее
sed -i "s/#Color/Color/g" /etc/pacman.conf # Добавляем цвета в pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 8/g" /etc/pacman.conf # Увеличение паралельных загрузок с 5 на 8
sed -i "s/#VerbosePkgLists/VerbosePkgLists/g" /etc/pacman.conf # Более удобный просмотр лист пакетов
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf # Включение multilib репо для запуска 32bit приложений

# Оптимизация зеркал с помощью Reflector
reflector --verbose -c ru,by -p http,https -l 12 --sort rate --save /etc/pacman.d/mirrorlist

# Синхронизация базы пакетов
pacman -Syy

# Установка из обработанного выхлопа списка базовых пакетов в /mnt
# 1. Удалить строки начинающиеся с #
# 2. Убрать все коментарии
# 3. Убрать все одиночные кавычки с названий пакетов
# 4. Убрать все пустые пробелы
# 5. Разделить строки по отдельности
# 6. Выровнять список в виде списка
pacstrap -K /mnt $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/base | column -t)

# Генерирую fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Добавление дополнительных разделов
# INFO: убрал nofail для Media по причине бага systemd, потому-что при выключении
# ПК /media/Media не размонтируется правильно (происходит при включении музыки mpd + Mpris)
tee -a /mnt/etc/fstab >/dev/null << EOF
# CDROM
/dev/sr0                /media/cdrom0   udf,iso9660     user,noauto  0 0

# tmpfs
# Чтобы не изнашивать SSD во время сборки используя makepkg
tmpfs                   /tmp            tmpfs           rw,nosuid,nodev,noatime,size=8G,mode=1777,inode64   0 0

# /dev/sdb
# Мои дополнительные разделы HDD диска
UUID=F46C28716C2830B2   /media/Distrib  ntfs-3g         rw,nofail,errors=remount-ro,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0 0
UUID=CA8C4EB58C4E9BB7   /media/Other    ntfs-3g         rw,nofail,errors=remount-ro,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0 0
UUID=A81C9E2F1C9DF890   /media/Media    ntfs-3g         rw,errors=remount-ro,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0 0
UUID=30C4C35EC4C32546   /media/Games    ntfs-3g         rw,nofail,errors=remount-ro,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0 0
EOF

# Копирование папки установочных скриптов
cp -r /root/archinstall /mnt

# Chroot'имся
arch-chroot /mnt /bin/bash /archinstall/1-chroot.sh

# Действия после chroot
if read -re -p "Желаете ли выполнить arch-chroot /mnt? [y/N]: " ans && [[ $ans == 'y' || $ans == 'Y' ]]; then
	arch-chroot /mnt ; echo "Не забудьте самостоятельно размонтировать /mnt перед reboot!"
else
	umount -R /mnt
fi
