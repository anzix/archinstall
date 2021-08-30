#!/bin/bash

# Установка Yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd
rm -rf yay 

# Создания английских папок
LC_ALL=C xdg-user-dirs-update --force

# Удаляем рус папки
rm -r Видео Документы Загрузки Изображения Музыка Общедоступные Рабочий\ стол/ Шаблоны

# Установка i3
yay -S --noconfirm i3-gaps rofi xorg xorg-xinit xorg-xrandr dunst i3status polybar picom autotiling nitrogen timeshift timeshift-autosnap lxappearance clipit flameshot ungoogled-chromium polkit-gnome man-pages-ru kotatogram-desktop-bin bleachbit ttf-font-awesome ttf-opensans ttf-kochi-substitute otf-ipafont ttf-droid ttf-liberation ttf-dejavu ttf-ubuntu-font-family nerd-fonts-ubuntu-mono powerline powerline-fonts ly-git materia-gtk-theme capitaine-cursors paper-icon-theme-git exfat-utils ntfs-3g --noconfirm

#noto-fonts

# Для VmWare (Закоментируйте если не надо)
yay -S --noconfirm open-vm-tools xf86-video-vmware xf86-input-vmmouse xf86-video-vesa --noconfirm



# Русская раскладка 
sudo localectl set-x11-keymap --no-convert us,ru pc105 "" grp:alt_shift_toggle

# Включение дм и другие штуки
sudo systemctl enable vmtoolsd
sudo systemctl start vmtoolsd
sudo systemctl enable ly.service

# AutoStartX DM (не запрашивает логин и пароль)
sudo touch .zprofile
sudo echo ' [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx ' >> /etc/.zrofile

cp /etc/X11/xinit/xinitrc /home/anzix/.xinitrc
chmod +x /home/anzix/.xinitrc
sed -i 52,55d /home/anzix/.xinitrc
echo "exec i3 " >> /home/anzix/.xinitrc

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo touch /etc/systemd/system/getty@tty1.service.d/override.conf
sudo tee -a /etc/systemd/system/getty@tty1.service.d/override.conf << END
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin anzix --noclear %I $TERM
END

# AutoStarX (Надо затестить)
#cp /etc/X11/xinit/xinitrc /home/$username/.xinitrc
#chown $username:users /home/$username/.xinitrc
#chmod +x /home/$username/.xinitrc
#sed -i 52,55d /home/$username/.xinitrc
#echo "exec i3 " >> /home/$username/.xinitrc
#mkdir /etc/systemd/system/getty@tty1.service.d/
#echo " [Service] " > /etc/systemd/system/getty@tty1.service.d/override.conf
#echo " ExecStart=" >> /etc/systemd/system/getty@tty1.service.d/override.conf
#echo   ExecStart=-/usr/bin/agetty --autologin $username --noclear %I 38400 linux >> /etc/systemd/system/getty@tty1.service.d/override.conf
#echo ' [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx ' >> /etc/profile

# Zsh дополнения
#yay -S zsh-syntax-highlighting zsh-autosuggestions --noconfirm
#echo 'source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /etc/zsh/zshrc
#echo 'source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /etc/zsh/zshrc
#echo 'prompt adam2' >> /etc/zsh/zshrc

