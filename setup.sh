#!/bin/bash




echo "==> Установка моего dotfiles"
cd ~
git clone --recurse-submodules https://gitlab.com/anzix/dotfiles.git && cd dotfiles/base
# Вытягиваю только необходимые конфиги
stow -vt ~ zsh \
 mpd ncmpcpp nvim pipewire wireplumber mpv `# Media & Sound` \
 otd npm browser-flags wget
# Переменные при активной сессии Xorg или Wayland
# Некоторые ДМ экспортируют только ~/.profile независимо от используемого $SHELL'а, измените если необходимо
ln -siv $HOME/dotfiles/base/zsh/.config/zsh/profile.zsh ~/.zprofile

mkdir -p ~/Pictures/{Screenshots/mpv,Gif}
mkdir -p ~/Documents/Backup
mkdir ~/.config/mpd/playlists

# Для функции "aurstore" в ~/.config/zsh/aliases.zsh
sudo pacman -Fy




sudo mkinitcpio -P


echo "==> Оптимизация записи на диск"
sudo sed -i -e s"/\Storage=.*/Storage=none/"g /etc/systemd/coredump.conf
sudo sed -i -e s"/\Storage=.*/Storage=none/"g /etc/systemd/journald.conf
sudo systemctl daemon-reload

# Добавление доп. разделов
echo "
UUID=F46C28716C2830B2   /media/Distrib  ntfs-3g        rw,nofail,errors=remount-ro,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0       0
UUID=CA8C4EB58C4E9BB7   /media/Other    ntfs-3g        rw,nofail,errors=remount-ro,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0       0
UUID=A81C9E2F1C9DF890   /media/Media    ntfs-3g        rw,nofail,errors=remount-ro,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0       0
UUID=30C4C35EC4C32546   /media/Games    ntfs-3g        rw,nofail,errors=remount-ro,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0       0" | sudo tee -a /etc/fstab >/dev/null


# Установка и настройка окружения
# TODO: Необходимо доделать
if [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
    curl -o ~/plasma_setup.sh https://raw.githubusercontent.com/anzix/scriptinstall/main/plasma_setup.sh
    chmod +x ~/plasma_setup.sh
    ~/plasma_install.sh
elif [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
    curl -o ~/gnome_setup.sh https://raw.githubusercontent.com/anzix/scriptinstall/main/gnome_setup.sh
    chmod +x ~/gnome_setup.sh
    ~/gnome_install.sh
elif [ ${DESKTOP_ENVIRONMENT} = "i3wm" ]; then
    curl -o ~/i3_setup.sh https://raw.githubusercontent.com/anzix/scriptinstall/main/i3_setup.sh
    chmod +x ~/i3_setup.sh
    ~/i3wm_install.sh
fi



# Усиление защиты
sudo sed -ri -e "s/^#PermitRootLogin.*/PermitRootLogin\ no/g" /etc/ssh/sshd_config

# Отключить мониторный режим микрофона Samson C01U Pro при старте системы
amixer sset -c 3 Mic mute



# Чистка
sudo pacman -Qtdq &&
    sudo pacman -Rns --noconfirm $(/bin/pacman -Qttdq)
# Очистить заархивированный журнал
sudo journalctl --rotate --vacuum-time=0.1

echo -e "\e[1;32m----------Установка системы завершена! Выполните ребут----------\e[0m"
