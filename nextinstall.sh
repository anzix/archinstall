#!/bin/bash

# Установка Yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
rm -rf yay 

# Создания английских папок
LC_ALL=C xdg-user-dirs-update --force
#Удаляем рус папки
rm -r Видео Документы Загрузки Изображения Музыка Общедоступные Рабочий\ стол/ Шаблоны

# Установка i3
yay -S --noconfirm i3-gaps rofi xorg xorg-xinit xorg-xrandr dunst i3status picom autotiling nitrogen timeshift timeshift-autosnap lxappearance clipit firefox polkit-gnome man-pages-ru kotatogram-desktop-bin bleachbit ttf-font-awesome ttf-opensans ttf-kochi-substitute otf-ipafont ttf-droid ttf-liberation ttf-dejavu ttf-ubuntu-font-family nerd-fonts-ubuntu-mono powerline powerline-fonts ly-git --noconfirm

#noto-fonts 

# Для VmWare (Закоментируйте если не надо)
yay -S --noconfirm open-vm-tools xf86-video-vmware xf86-input-vmmouse xf86-video-vesa --noconfirm

# Русская раскладка 
sudo --no-ask-password localectl set-x11-keymap --no-convert us,ru pc105 "" grp:alt_shift_toggle

# Включение дм и другие штуки
sudo --no-ask-password systemctl enable vmtoolsd
sudo --no-ask-password systemctl start vmtoolsd
sudo --no-ask-password systemctl enable ly.service




#sudo pacman -Syu
#sudo pacman -S wget --noconfirm
#wget git.io/yay-install.sh && sh yay-install.sh --noconfirm
