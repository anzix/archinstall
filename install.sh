#!/bin/bash

#loadkeys ru
#setfont cyr-sun16

#pacstrap /mnt base base-devel linux-firmware linux-zen linux-zen-headers btrfs-progs grub efibootmgr zsh git nano vim



#genfstab -U /mnt >> /mnt/etc/fstab

#arch-chroot /mnt
ln -sf /usr/share/zoneinfo/Asia/Yekaterinburg /etc/localtime


timedatectl set-ntp true
hwclock --systohc --utc 

echo "anzix" > /etc/hostname


echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 anzix.localdomain anzix" >> /etc/hosts


echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen 
locale-gen
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf
echo 'KEYMAP=ru' >> /etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /etc/vconsole.conf

pacman-key --init
pacman-key --populate archlinux


#echo 'Color' >> /etc/pacman.conf
#echo '[multilib]' >> /etc/pacman.conf
#echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf

sh -c "sed -i '/\Color/,/[multilib\]/,/Include/s/^[ ]*#//' /etc/pacman.conf"


#Надо проверить строчку hooks
echo -e "MODULES=(btrfs)\nHOOKS=(keymap)\"" > /etc/mkinitcpio.conf
mkinitcpio -P

echo root:anz | chpasswd

useradd -m -g users -G wheel -s /bin/zsh anzix

echo "anzix:anz" | chpasswd

sh -c "sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers"

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

