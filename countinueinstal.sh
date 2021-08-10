#Установка Yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

#Создания английских папок
LC_ALL=C xdg-user-dirs-update --force

#Установка i3
yay -S --noconfirm i3-gaps rofi xorg xorg-xinit xorg-xrandr dunst i3status picom-git firefox nerd-fonts-ubuntu-mono ly-git

systemctl enable ly.service

echo reboot

#sudo pacman -Syu
#sudo pacman -S wget --noconfirm
#wget git.io/yay-install.sh && sh yay-install.sh --noconfirm
