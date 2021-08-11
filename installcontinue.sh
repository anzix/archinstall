#sh -c "sed -i '/\/[multilib\]/,/Include/s/^[ ]*#//' /etc/pacman.conf"
sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Making pacman prettier
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Add color to pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 10/g" /etc/pacman.conf  # Parallel downloads

#Добавление ключей PGP
pacman-key --init
pacman-key --populate archlinux


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

#Редактирование файла pacman (добавление multilib и цвета в pacman)
#echo 'Color' >> /etc/pacman.conf
#echo '[multilib]' >> /etc/pacman.conf
#echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf


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
