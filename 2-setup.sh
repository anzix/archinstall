#!/bin/bash

# Позаимствовано
# https://github.com/arkenfox/user.js/blob/master/user.js
# https://github.com/farag2/Mozilla-Firefox/blob/master/user.js
# https://github.com/gjpin/arch-linux/blob/main/setup.sh

# раскомментируйте, чтобы просмотреть информацию об отладке
#set -xeuo pipefail

PS3="Выберите окружение: "
select ENTRY in "plasma" "gnome" "i3wm" "sway"; do
	export DESKTOP_ENVIRONMENT=$ENTRY
	echo "Выбран ${DESKTOP_ENVIRONMENT}."
	break
done

read -p "Хотите играть в игры? (y/n): " GAMING
export GAMING

read -p "Хотите виртуализацию? (y/n): " VM_SETUP
export VM_SETUP

echo "==> Установка дополнительных пакетов, моих программ и шрифтов [Pacman]"
sudo pacman -S --noconfirm --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/{additional,fonts,programs} | column -t)

# Обнаружение виртуалки
if [[ "$(systemd-detect-virt)" == "kvm" ]]; then
 PKGS+=(qemu-guest-agent spice-vdagent)
 # В оконных менеджерах (WM) для активации Shared Clipboard в терминале надо ввести spice-vdagent
elif [[ "$(systemd-detect-virt)" == "oracle" ]]; then
 PKGS+=(virtualbox-guest-utils xf86-video-vmware)
 usermod -a -G vboxsf "${USER_NAME}"
 # sudo systemctl enable vboxservice.service
fi

# Установка Yay (AUR помощник)
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin && makepkg -si --noconfirm
cd .. && rm -rf yay-bin

# Настройка yay
# --nodiffmenu - Не спрашивать об показе изменений (diff)
# --nocleanmenu - Не спрашивать о пакетах для которых требуется очистить кэш сборки
# (Мешает при использовании grub-btrfs или snap-pac-grub) --removemake - Всегда удалять зависимости для сборки (make) после установки
# --batchinstall - Ставит каждый собранный пакеты в очередь для установки (легче мониторить что происходит)
yay --save --nodiffmenu --nocleanmenu --batchinstall

echo "==> Установка AUR пакетов"
yay -S $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/aur | column -t)

if hash snapper 2>/dev/null; then
PKGS+=(
 'snap-pac' # Создаёт снапшоты после каждой установки/обновления/удаления пакетов Pacman
 'grub-btrfs' # Добавляет grub меню снимков созданных snapper чтобы в них загружаться + демон grub-btrfsd
 'inotify-tools' # Необходимая зависимость для демона grub-btrfsd авто-обновляющий записи grub

 'snp' # Заворачивает любую shell команду и создаёт снимок до выполнения этой команды (snp sudo pacman -Syu)
 'snapper-rollback' # Скрипт для отката системы который соответствует схеме разметки Arch Linux
)
else
	PKGS+=(timeshift)
fi

yay -S "${PKGS[@]}" --noconfirm --needed

echo "==> Вытягиваю из моего dotfiles основные конфиги"
git clone --recurse-submodules https://github.com/anzix/dotfiles
cd ~/dotfiles/base
stow -vt ~ */
# Переменные при активной сессии Xorg или Wayland
# Некоторые DM экспортируют только ~/.profile независимо от используемого $SHELL'а, измените если необходимо
ln -siv $HOME/dotfiles/base/zsh/.config/zsh/profile.zsh ~/.zprofile


# Проверяю наличие браузера Firefox
if pacman -Qs firefox > /dev/null; then

echo "==> Настройка и экспорт моих настроек Firefox"

# Временно открыть Firefox, чтобы создать папку профиля.
timeout 5 firefox --headless

# Устанавливаю путь к профилю Firefox
FIREFOX_PROFILE_PATH=$(realpath /${HOME}/.mozilla/firefox/*.default-release)

# Импорт расширений
mkdir -p ${FIREFOX_PROFILE_PATH}/extensions
# Тема браузера
curl https://addons.mozilla.org/firefox/downloads/file/3913593/matte_black_red-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{a7589411-c5f6-41cf-8bdc-f66527d9d930}.xpi
# Violentmonkey
curl https://addons.mozilla.org/firefox/downloads/file/4050539/violentmonkey-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{aecec67f-0d10-4fa7-b7c7-609a2db280cf}.xpi
# TWP - Translate Web Pages
curl https://addons.mozilla.org/firefox/downloads/file/4011167/traduzir_paginas_web-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{036a55b4-5e72-4d05-a06c-cba2dfcc134a}.xpi
# UBlock Origin
curl https://addons.mozilla.org/firefox/downloads/file/4003969/ublock_origin-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/uBlock0@raymondhill.net.xpi
# Auto Tab Discard (Усыпление вкладок)
curl https://addons.mozilla.org/firefox/downloads/file/4045009/auto_tab_discard-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{c2c003ee-bd69-42a2-b0e9-6f34222cb046}.xpi
# TSE - Torrents Search Engine
curl https://addons.mozilla.org/firefox/downloads/file/3983730/tse_torrents_search_engine-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/tse@example.com.xpi
# 7TV (Twitch)
curl https://addons.mozilla.org/firefox/downloads/file/3988775/7tv-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{7ef0f00c-2ebe-4626-8ed7-3185847fcfad}.xpi
# ff2mpv
curl https://addons.mozilla.org/firefox/downloads/file/3898765/ff2mpv-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/ff2mpv@yossarian.net.xpi
# Enchanced h264ify
curl https://addons.mozilla.org/firefox/downloads/file/3009842/enhanced_h264ify-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{9a41dee2-b924-4161-a971-7fb35c053a4a}.xpi
# Обход блокировок Рунета
curl https://addons.mozilla.org/firefox/downloads/file/3865240/2668061-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{290ce447-2abb-4d96-8384-7256dd4a1c43}.xpi
# Browsec VPN (Временный vpn)
curl https://addons.mozilla.org/firefox/downloads/file/4043870/browsec-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/browsec@browsec.com.xpi
# Dark Reader
curl https://addons.mozilla.org/firefox/downloads/file/4021899/darkreader-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/addon@darkreader.org.xpi
# Return Youtube Dislikes
curl https://addons.mozilla.org/firefox/downloads/file/4005382/return_youtube_dislikes-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{762f9885-5a13-4abd-9c77-433dcd38b8fd}.xpi
# Keepassxc Browser
curl https://addons.mozilla.org/firefox/downloads/file/4023682/keepassxc_browser-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/keepassxc-browser@keepassxc.org.xpi
# SponsorBlock
curl https://addons.mozilla.org/firefox/downloads/file/4026759/sponsorblock-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/sponsorBlocker@ajay.app.xpi
# SteamDB
curl https://addons.mozilla.org/firefox/downloads/file/4026911/steam_database-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/firefox-extension@steamdb.info.xpi
# Cute Save Button
curl https://addons.mozilla.org/firefox/downloads/file/3900368/cute_save_button-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/ochecuteextension@plaza.ink.xpi
# DownloadThemAll!
curl https://addons.mozilla.org/firefox/downloads/file/3983650/downthemall-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{DDC359D1-844A-42a7-9AA1-88A850A938A8}.xpi
# Cookie AutoDelete
curl https://addons.mozilla.org/firefox/downloads/file/3971429/cookie_autodelete-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/CookieAutoDelete@kennydo.com.xpi
# Dollchan Extension Tools
curl https://addons.mozilla.org/firefox/downloads/file/4027739/dollchan_extension-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/dollchan_extension@dscript.me.xpi
# Proxy SwitchyOmega
curl https://addons.mozilla.org/firefox/downloads/file/1056777/switchyomega-latest.xpi
# cookies-txt-one-click
curl https://addons.mozilla.org/firefox/downloads/file/3452835/cookies_txt_one_click-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{520a19d3-2d3c-47ee-ba15-cd66aae65db2}.xpi
# Bookmark Dupes
curl https://addons.mozilla.org/firefox/downloads/file/3988430/bookmark_dupes-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/bookmarkdupes@martin-vaeth.org.xpi
# Fixed Zoom
curl https://addons.mozilla.org/firefox/downloads/file/1705492/fixed_zoom-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{a655a6b2-69a5-40de-a3b8-3f7f200c95a7}.xpi
# Enforce Browser Fonts - полезно особенно для Linux
curl https://addons.mozilla.org/firefox/downloads/file/3782841/enforce_browser_fonts-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{83e08b00-32de-44e7-97bb-1bab84d1350f}.xpi
# Don't "Accept" image/webp
curl https://addons.mozilla.org/firefox/downloads/file/3941342/dont_accept_webp-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/dont-accept-webp@jeffersonscher.com.xpi

# curl https://addons.mozilla.org/firefox/downloads/file/3998783/floccus-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/floccus@handmadeideas.org.xpi
# curl https://addons.mozilla.org/firefox/downloads/file/3932862/multi_account_containers-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/@testpilot-containers.xpi

# Импорт Firefox конфига
cp -v ~/dotfiles/user.js ${FIREFOX_PROFILE_PATH}
fi


mkdir -p ~/Pictures/{Screenshots/mpv,Gif}
mkdir -p ~/Documents/Backup
mkdir ~/.config/mpd/playlists

# Для функции "aurstore" в ~/.config/zsh/aliases.zsh
sudo pacman -Fy

# Установка и настройка окружения
if [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
	$HOME/scriptinstall/plasma.sh
elif [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
	$HOME/scriptinstall/gnome.sh
elif [ ${DESKTOP_ENVIRONMENT} = "i3wm" ]; then
	$HOME/scriptinstall/i3wm.sh
elif [ ${DESKTOP_ENVIRONMENT} = "sway" ]; then
	$HOME/scriptinstall/sway.sh
fi

# Установка игровых пакетов и настройка
if [ ${GAMING} = "y" ]; then
	$HOME/scriptinstall/gaming.sh
fi

# Установка пакетов для виртуализации и настройка
if [ ${VM_SETUP} = "y" ]; then
	$HOME/scriptinstall/vm_support.sh
fi


# Скрыть приложения из меню
APPLICATIONS=('assistant' 'avahi-discover' 'designer' 'electron' 'electron21' 'htop' 'linguist' 'lstopo' 'nvim' 'org.kde.kuserfeedback-console' 'qdbusviewer' 'qt5ct' 'qv4l2' 'qvidcap' 'bssh' 'bvnc' 'mpv' 'uxterm' 'xterm' 'btop' 'scrcpy' 'scrcpy-console')
for APPLICATION in "${APPLICATIONS[@]}"
do
    # Создаём локальную копию ярлыков в пользовательскую директорию для применение свойств
    cp /usr/share/applications/${APPLICATION}.desktop /home/${USERNAME}/.local/share/applications/${APPLICATION}.desktop 2>/dev/null || :

    if test -f "/home/${USERNAME}/.local/share/applications/${APPLICATION}.desktop"; then
        echo "NoDisplay=true" >> /home/${USERNAME}/.local/share/applications/${APPLICATION}.desktop
        echo "Hidden=true" >> /home/${USERNAME}/.local/share/applications/${APPLICATION}.desktop
        echo "NotShowIn=KDE;GNOME;" >> /home/${USERNAME}/.local/share/applications/${APPLICATION}.desktop
    fi
done

# Усиление защиты
sudo sed -ri -e "s/^#PermitRootLogin.*/PermitRootLogin\ no/g" /etc/ssh/sshd_config

# Отключить мониторный режим микрофона Samson C01U Pro при старте системы
amixer sset -c 3 Mic mute

# Врубаю сервисы
sudo systemctl enable grub-btrfsd

systemctl --user enable \
 mpd \
 mpd-mpris \
 opentabletdriver.service
# cdemu-daemon.service

# Чистка
sudo pacman -R --noconfirm $(/bin/pacman -Qtdq)

echo -e "\e[1;32m----------Установка системы завершена! Выполните ребут----------\e[0m"
