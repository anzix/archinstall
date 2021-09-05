#!/bin/bash

loadkeys ru
setfont cyr-sun16

sed -i "s/#\(en_US\.UTF-8\)/\1/" /etc/locale.gen
sed -i "s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen

locale-gen

export LANG=ru_RU.UTF-8

# Схема разметки диска в gpt используя gdisk
#sda1 - efi 100m
#sda2 - boot 300m
#sda3 - btrfs - остальное

sgdisk --zap-all /dev/sda  # Delete tables
printf "n\n1\n\n+100M\nef00\nn\n\n2\n\n+300M\nef02\nn\n\n3\n\n\n\nw\ny\n" | gdisk /dev/sda


mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.btrfs -L Arch /dev/sda3

mount /dev/sda3 /mnt

cd /mnt

# Создание subvolume'мов
btrfs su cr @
btrfs su cr @home
cd
umount /mnt

# Доп настройки для оптимизации дисков
mount -o noatime,compress=zstd:2,space_cache=v2,discard=async,subvol=@ /dev/sda3 /mnt
mkdir /mnt/{boot,home}
mount -o noatime,compress=zstd:2,space_cache=v2,discard=async,subvol=@home /dev/sda3 /mnt/home
mount /dev/sda2 /mnt/boot

# Правка конфига pacman
sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Делаем pacman красивее
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Добавляем цвета в pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 10/g" /etc/pacman.conf  # Увеличение паралельных загрузок с 5 на 10
sed -i "s/#VerbosePkgLists/VerbosePkgLists/g" /etc/pacman.conf # Более удобный просмотр лист пакетов
sed -i "94,95s/^#//" /etc/pacman.conf # Раскоментирование строчки (В данном случае они именуются цифрами) multilib для запуска 32bit приложений

#sed -i "s/#[multilib]/[multilib]/g; s/#Include/Include/g" /etc/pacman.conf
#sed -i "/[multilib\]/,/Include/s/^[ ]#//" /etc/pacman.conf

# Оптимизация зеркал с помощью Reflector
pacman -Sy --noconfirm reflector rsync
reflector --verbose -c ru,by,ua,pl -p https,http -l 15 --sort rate --save /etc/pacman.d/mirrorlist

# Обновление пакетов
pacman -Syy

# Установка базовых пакетов
pacstrap /mnt base base-devel linux-firmware linux-zen linux-zen-headers btrfs-progs grub efibootmgr zsh git nano vim terminus-font
# Созлание genfstab
genfstab -U /mnt >> /mnt/etc/fstab

# Вход в root
arch-chroot /mnt /bin/bash << EOF

# Добавление ключей PGP
pacman-key --init
pacman-key --populate archlinux

# Локализация на Русский
sed -i "s/#\(en_US\.UTF-8\)/\1/" /etc/locale.gen
sed -i "s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen

#sed -i "/^#\en_SG ISO/{N;s/\n#/\n/}" /etc/locale.gen

#sed -i "/ru_RU.UTF-8/s/^#//g" /etc/locale.gen

locale-gen

echo 'LANG=ru_RU.UTF-8' > /etc/locale.conf
echo 'LC_COLLATE=C' >> /etc/locale.conf

echo 'KEYMAP=ru' >> /etc/vconsole.conf

echo 'FONT=cyr-sun16' >> /etc/vconsole.conf

# Время и дата
ln -sf /usr/share/zoneinfo/Asia/Yekaterinburg /etc/localtime
timedatectl set-ntp true # Синхронизировать часы материнской платы
hwclock --systohc --utc 

# Имя нашего ПК
echo "anzix" > /etc/hostname

#Добавление строк в файл хост
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 anzix.localdomain anzix" >> /etc/hosts

# Добавление в mkinitcpio модуль btrfs и правка hooks
sed -i "s/^HOOKS.*/HOOKS=(base udev autodetect modconf block filesystems keyboard keymap)/g" /etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=(btrfs)/' /etc/mkinitcpio.conf

# Создание образа ранней загрузки
mkinitcpio -P linux-zen

# Пароль для Root
echo root:anz | chpasswd

# Добавления нашего юзера
useradd -m -g users -G wheel -s /bin/zsh anzix

# Добавления пароля юзера
echo "anzix:anz" | chpasswd

# Sudo с запросом пароля
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# Правка конфига pacman
sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Делаем pacman красивее
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Добавляем цвета в pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 7/g" /etc/pacman.conf  # Увеличение паралельных загрузок 
sed -i "94,95s/^#//" /etc/pacman.conf # Раскоментирование строчки (В данном случае они именуются цифрами) multilib для запуска 32bit приложений

# Обноваление и установка необходимых пакетов (для установки i3 окружения)
pacman -Syu
pacman -S --noconfirm xorg-xinit xorg-server xorg-xrandr xdg-utils xdg-user-dirs links wget kitty ranger pcmanfm-gtk3 gvfs file-roller unzip unrar pulseaudio alsa alsa-utils pulseaudio-alsa intel-ucode dhcpcd pavucontrol terminus-font

# Установка Grub
mkdir /boot/efi
mount /dev/sda1 /boot/efi
grub-install --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

# Включение dhcpcd
systemctl enable dhcpcd.service

EOF

# Готово!
umount -R /mnt

