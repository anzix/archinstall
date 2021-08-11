#!/bin/bash

#loadkeys ru
#setfont cyr-sun16


sgdisk --zap-all /dev/sda  # Delete tables
printf "n\n1\n\n+100M\nef00\nn\n2\n\n\n+300m\nef02\nn\n\n3\n\n\n\nw\ny\n" | gdisk /dev/sda

mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.btrfs -L Arch /dev/sda3

mount /dev/sda3 /mnt

cd /mnt

btrfs su cr @
btrfs su cr @home
cd
umount /mnt

mount -o noatime,compress=zstd:2,space_cache=v2,discard=async,subvol=@ /dev/sda3 /mnt

mkdir /mnt/{boot,home}

mount -o noatime,compress=zstd:2,space_cache=v2,discard=async,subvol=@home /dev/sda3 /mnt/home

mount /dev/sda2 /mnt/boot



pacstrap /mnt base base-devel linux-firmware linux-zen linux-zen-headers btrfs-progs grub efibootmgr zsh git nano vim

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

#Время и дата
ln -sf /usr/share/zoneinfo/Asia/Yekaterinburg /etc/localtime
timedatectl set-ntp true # Синхронизировать часы материнской платы
hwclock --systohc --utc 

#Имя нашего ПК
echo "anzix" > /etc/hostname

#Добавление строк в файл хост
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 anzix.localdomain anzix" >> /etc/hosts

#Локализация на Русский
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen 
locale-gen
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf
echo 'KEYMAP=ru' >> /etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /etc/vconsole.conf

#Добавление ключей PGP
pacman-key --init
pacman-key --populate archlinux

#Редактирование файла pacman (добавление multilib и цвета в pacman)
#echo 'Color' >> /etc/pacman.conf
#echo '[multilib]' >> /etc/pacman.conf
#echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf

sh -c "sed -i '/\Color/,/[multilib\]/,/Include/s/^[ ]*#//' /etc/pacman.conf"


#Добавление в mkinitcpio модуль btrfs и правка hooks
echo -e "MODULES=(btrfs)\nHOOKS=(keymap)\"" > /etc/mkinitcpio.conf
#Создание образа ранней загрузки
mkinitcpio -P

#Пароль для Root
echo root:anz | chpasswd

#Добавления нашего юзера
useradd -m -g users -G wheel -s /bin/zsh anzix

#Добавления пароля юзера
echo "anzix:anz" | chpasswd

#Удалить права пароля Sudo
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

pacman -Syu
pacman -S --noconfirm xorg-xinit xorg-server xorg-xrandr xdg-utils xdg-user-dirs links wget alacritty ranger pcmanfm-gtk3 gvfs file-roller unzip unrar pulseaudio alsa alsa-utils pulseaudio-alsa intel-ucode dhcpcd pavucontrol


mkdir /boot/efi
mount /dev/sda1 /boot/efi
grub-install --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg


systemctl enable dhcpcd.service

echo exit
echo umount -R /mnt
echo reboot

