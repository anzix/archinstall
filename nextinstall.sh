#Установка Yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

#Создания английских папок
LC_ALL=C xdg-user-dirs-update --force
#Удаляем рус папки (Не удаляются, надо как-то это решить)_
rm -r Видео Документы Загрузки Изображения Музыка Общедоступные Рабочий\ стол/ Шаблоны

#Установка i3 (Не устанваливаются aur пакеты, надо тоже что-то с этим сделать)
yay -S --noconfirm i3-gaps rofi xorg xorg-xinit xorg-xrandr dunst i3status picom autotiling timeshift timeshift-autosnap lxappearance clipit firefox polkit-gnome man-pages-ru kotatogram-desktop-bin bleachbit ttf-font-awesome ttf-opensans ttf-kochi-substitute otf-ipafont noto-fonts ttf-droid ttf-liberation ttf-dejavu ttf-ubuntu-font-family nerd-fonts-ubuntu-mono powerline powerline-fonts ly-git open-vm-tools xf86-video-vmware xf86-input-vmmouse xf86-video-vesa --noconfirm

#Русская раскладка 
localectl set-x11-keymap --no-convert us,ru pc105 "" grp:alt_shift_toggle

systemctl enable vmtoolsd
systemctl start vmtoolsd
systemctl enable ly.service


#sudo pacman -Syu
#sudo pacman -S wget --noconfirm
#wget git.io/yay-install.sh && sh yay-install.sh --noconfirm
