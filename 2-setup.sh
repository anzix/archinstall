#!/bin/bash

# Позаимствовано
# https://github.com/arkenfox/user.js/blob/master/user.js
# https://github.com/farag2/Mozilla-Firefox/blob/master/user.js
# https://github.com/gjpin/arch-linux/blob/main/setup.sh

# раскомментируйте, чтобы просмотреть информацию об отладке
#set -xe

# Диалог о начале настройки
if read -re -p "Начать настройку? [y/N]: " ans && [[ $ans == 'y' || $ans == 'Y' ]]; then

# Установка Yay (AUR помощник)
git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
pushd /tmp/yay-bin && makepkg -si --noconfirm
popd

# Настройка yay
# --combinedupgrade=false - Не комбинировать списки обновлений
# = --nocleanmenu - Не спрашивать о пакетах для которых требуется очистить кэш сборки
# --removemake - Всегда удалять зависимости для сборки (make) после установки
# --diffmenu=false - Не спрашивать об показе изменений (diff)
# --batchinstall=true - Ставит каждый собранный пакеты в очередь для установки (легче мониторить что происходит)
yay --save --combinedupgrade=false --diffmenu=false --batchinstall=true

# Включение снимков и настройка отката системы
if hash snapper 2>/dev/null; then
PKGS+=(
 'snap-pac' # Создаёт снапшоты после каждой установки/обновления/удаления пакетов Pacman
 'grub-btrfs' # Добавляет grub меню снимков созданных snapper чтобы в них загружаться + демон grub-btrfsd
 'inotify-tools' # Необходимая зависимость для демона grub-btrfsd авто-обновляющий записи grub

 'snp' # Заворачивает любую shell команду и создаёт снимок до выполнения этой команды (snp sudo pacman -Syu)
 'snapper-rollback' # Скрипт для отката системы который соответствует схеме разметки Arch Linux
)

yay -S "${PKGS[@]}" --noconfirm --needed

# Редактирую конфигурационный файл snapper-rollback что точка монтирования /.btrfsroot
sudo sed -i "s|^mountpoint.*|mountpoint = /.btrfsroot|" /etc/snapper-rollback.conf

# Пересоздаю конфиг grub для создания меток восстановления
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Включение мониторинга списков снимков grub
sudo systemctl enable grub-btrfsd

# Запрещаю snap-pac выполнять pre и post снапшоты на текущий момент
# FIXME: Не работает с yay и возможно paru, только c pacman
export SNAP_PAC_SKIP=y

# Создаю снимок / и /home
sudo snapper -c root create -d "***System Installed***"
sudo snapper -c home create -d "***System Installed***"
fi

echo "==> Вытягиваю из моего dotfiles основные конфиги"
git clone --recurse-submodules https://github.com/anzix/dotfiles ~/.dotfiles
pushd ~/.dotfiles/base && stow -vt ~ */
popd

# Выполняю profile.zsh для использования пользовательских переменных (спецификаций каталогов XDG BASE)
source ~/.dotfiles/base/zsh/.config/zsh/profile.zsh

# Обновление зеркал
sudo pacman -Sy

# FIXME необходимо как-то разделить aur пакеты с основными
echo "==> Установка дополнительных пакетов, моих программ и шрифтов [Pacman+AUR]"
sudo SNAP_PAC_SKIP=y pacman -S --noconfirm --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/{additional,fonts,programs} | column -t)
yay -S --noconfirm --batchinstall=false --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/aur | column -t)

# Установка и настройка окружения
PS3="Выберите окружение/WM: "
select ENTRY in "plasma" "gnome" "i3wm" "sway" "Пропуск"; do
    if [ "$ENTRY" = "Пропуск" ]; then
        echo "Установка пропущена."
        break
    fi

    export DESKTOP_ENVIRONMENT=$ENTRY && echo "Выбран ${DESKTOP_ENVIRONMENT}."

    if [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
        $HOME/archinstall/plasma.sh
    elif [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
        $HOME/archinstall/gnome.sh
    elif [ ${DESKTOP_ENVIRONMENT} = "i3wm" ]; then
        $HOME/archinstall/i3wm.sh
    elif [ ${DESKTOP_ENVIRONMENT} = "sway" ]; then
        $HOME/archinstall/sway.sh
    fi

    break
done

# Установка игровых пакетов и настройка
if read -re -p "Хотите играть в игры? (y/n): " ans && [[ $ans == 'y' || $ans == 'Y' ]]; then
	$HOME/archinstall/gaming.sh
fi

# Установка пакетов для виртуализации и настройка
if read -re -p "Хотите виртуализацию? (y/n): " ans && [[ $ans == 'y' || $ans == 'Y' ]]; then
	$HOME/archinstall/vm_support.sh
fi

# Скрыть приложения из меню запуска для Arch и Debian
APPLICATIONS=('assistant' 'avahi-discover' 'designer' 'electron' 'electron22' 'electron23' 'electron24' 'electron25' 'htop' 'linguist' 'lstopo' 'vim' 'nvim' \
	'org.kde.kuserfeedback-console' 'qdbusviewer' 'qt5ct' 'qt6ct' 'qv4l2' 'qvidcap' 'bssh' 'bvnc' 'uxterm' 'xterm' 'debian-uxterm' 'debian-xterm' 'btop' \
	'scrcpy' 'scrcpy-console' 'rofi' 'rofi-theme-selector' 'picom' 'ncmpcpp' 'display-im6.q16')
# 'mpv' 'jconsole-java-openjdk' 'jshell-java-openjdk'
mkdir -v ${HOME}/.local/share/applications
for APPLICATION in "${APPLICATIONS[@]}"
do
    # Создаём локальную копию ярлыков в пользовательскую директорию для применение свойств
    cp -v /usr/share/applications/${APPLICATION}.desktop ${HOME}/.local/share/applications/${APPLICATION}.desktop 2>/dev/null || :

    if test -f "${HOME}/.local/share/applications/${APPLICATION}.desktop"; then
        echo "NoDisplay=true" >> ${HOME}/.local/share/applications/${APPLICATION}.desktop
        echo "NotShowIn=GNOME;Xfce;KDE;" >> ${HOME}/.local/share/applications/${APPLICATION}.desktop
    fi
done

# Создание других каталогов
mkdir -pv $HOME/Pictures/{Screenshots,Gif}

# Отключить мониторный режим микрофона Samson C01U Pro при старте системы
amixer sset -c 3 Mic mute

# Включение сервисов
sudo systemctl enable pkgfile-update.timer
systemctl --user enable mpd
systemctl --user enable mpd-mpris
systemctl --user enable opentabletdriver.service

# Чистка
sudo pacman -R --noconfirm $(/bin/pacman -Qtdq)
unset -v SNAP_PAC_SKIP
fi
