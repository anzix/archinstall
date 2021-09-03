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
yay -Syyu --noconfirm stow i3-gaps rofi xorg xorg-xinit xorg-xrandr dunst polybar picom autotiling nitrogen htop neofetch timeshift timeshift-autosnap lxappearance clipit flameshot librewolf polkit-gnome man-pages-ru kotatogram-desktop-bin qbittorrent youtube-dl mpv spotify songrec bleachbit betterlockscreen terminus-font ttf-font-awesome ttf-opensans ttf-sazanami ttf-droid ttf-liberation ttf-dejavu nerd-fonts-hack powerline powerline-fonts lsd materia-gtk-theme capitaine-cursors paper-icon-theme-git python-pillow exfat-utils ntfs-3g --noconfirm

#ttf-kochi-substitute otf-ipafont
#ly-git
#noto-fonts
#i3status
#ttf-ubuntu-font-family
#nerd-fonts-ubuntu-mono
# Для VmWare (Закоментируйте если не надо)
yay -S --noconfirm open-vm-tools xf86-video-vmware xf86-input-vmmouse xf86-video-vesa --noconfirm



# Русская раскладка 
sudo localectl set-x11-keymap --no-convert us,ru pc105 "" grp:alt_shift_toggle

# Включение дм и другие штуки
#sudo usermod -aG libvirt anzix
sudo systemctl enable vmtoolsd
sudo systemctl start vmtoolsd
sudo systemctl enable ly.service





# AutoStartX DM (не запрашивает логин и пароль)
touch .zprofile
echo '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> .zprofile

cp /etc/X11/xinit/xinitrc /home/anzix/.xinitrc
chmod +x /home/anzix/.xinitrc
sed -i 52,55d /home/anzix/.xinitrc
echo "exec i3 " >> /home/anzix/.xinitrc

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo touch /etc/systemd/system/getty@tty1.service.d/override.conf
sudo bash -c 'echo "[Service]" > /etc/systemd/system/getty@tty1.service.d/override.conf'
sudo bash -c 'echo "ExecStart=" >> /etc/systemd/system/getty@tty1.service.d/override.conf'
sudo bash -c 'echo "ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin anzix --noclear %I $TERM" >> /etc/systemd/system/getty@tty1.service.d/override.conf'

# Установка oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Установка темы powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Plugin Autosuggestions (Очень сильно экономит время) автозавершения команд на основе истории
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Plugin Syntax-highlighting (для подсветки синтаксиса команд в терминале)
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Установка моего dotfiles
git clone https://gitlab.com/anzix/dotfiles.git
cd dotfiles
mv README.md ~/Downloads

cp .p10k.zsh ~
cp .vimrc ~
cp .xinitrc ~
cd dotfiles
stow --adopt -vt ~ *

#sudo tee -a /etc/systemd/system/getty@tty1.service.d/override.conf << END
#[Service]
#ExecStart=
#ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin anzix --noclear %I $TERM
#END



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

