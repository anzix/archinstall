#!/bin/bash

# Позаимствовано
# https://github.com/arkenfox/user.js/blob/master/user.js
# https://github.com/farag2/Mozilla-Firefox/blob/master/user.js
# https://github.com/gjpin/arch-linux/blob/main/setup.sh

# раскомментируйте, чтобы просмотреть информацию об отладке
#set -xe

echo "==> Вытягиваю из моего dotfiles основные конфиги"
git clone --recurse-submodules https://github.com/anzix/dotfiles ~/.dotfiles
pushd ~/.dotfiles/base && stow -vt ~ */

# Переменные при активной сессии Xorg или Wayland
# Некоторые DM экспортируют только ~/.profile независимо от используемого $SHELL'а, измените если необходимо
ln -siv $HOME/.dotfiles/base/zsh/.config/zsh/profile.zsh ~/.zprofile
popd

# Выполняю ~/.zprofile для использования переменных (спецификаций каталогов XDG BASE)
source ~/.zprofile

# Установка Yay (AUR помощник)
git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
pushd /tmp/yay-bin && makepkg -si --noconfirm
popd

# Настройка yay
# --nodiffmenu - Не спрашивать об показе изменений (diff)
# --batchinstall - Ставит каждый собранный пакеты в очередь для установки (легче мониторить что происходит)
yay --save --nodiffmenu --batchinstall

echo "==> Установка дополнительных пакетов, моих программ и шрифтов [Pacman+AUR]"
yay -S --noconfirm --nobatchinstall --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/{additional,fonts,programs,aur} | column -t)

# Проверяю наличие браузера Firefox
if pacman -Qs firefox > /dev/null; then

echo "==> Настройка и экспорт настроек Firefox"
# Временно открыть Firefox, чтобы создать папку профиля.
timeout 5 firefox --headless

# Устанавливаю путь к профилю Firefox
FIREFOX_PROFILE_PATH=$(realpath "${HOME}/.mozilla/firefox/"*.default-release)

# Создание каталога расширений
mkdir -p "${FIREFOX_PROFILE_PATH}/extensions"

# Список расширений (25)
EXTENSIONS=(
 "3913593/matte_black_red-latest.xpi:{a7589411-c5f6-41cf-8bdc-f66527d9d930}" # Тема браузера
 "4050539/violentmonkey-latest.xpi:{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" # Violentmonkey
 "4011167/traduzir_paginas_web-latest.xpi:{036a55b4-5e72-4d05-a06c-cba2dfcc134a}" # TWP - Translate Web Pages
 "4003969/ublock_origin-latest.xpi:uBlock0@raymondhill.net" # UBlock Origin
 "4045009/auto_tab_discard-latest.xpi:{c2c003ee-bd69-42a2-b0e9-6f34222cb046}" # Auto Tab Discard (Усыпление вкладок)
 "3983730/tse_torrents_search_engine-latest.xpi:tse@example.com" # TSE - Torrents Search Engine
 "3898765/ff2mpv-latest.xpi:ff2mpv@yossarian.net" # ff2mpv
 "3009842/enhanced_h264ify-latest.xpi:{9a41dee2-b924-4161-a971-7fb35c053a4a}" # Enchanced h264ify
 "3865240/2668061-latest.xpi:{290ce447-2abb-4d96-8384-7256dd4a1c43}" # Обход блокировок Рунета
 "4043870/browsec-latest.xpi:browsec@browsec.com" # Browsec VPN (Временный vpn)
 "4021899/darkreader-latest.xpi:addon@darkreader.org" # Dark Reader
 "4005382/return_youtube_dislikes-latest.xpi:{762f9885-5a13-4abd-9c77-433dcd38b8fd}" # Return Youtube Dislikes
 "4023682/keepassxc_browser-latest.xpi:keepassxc-browser@keepassxc.org" # Keepassxc Browser
 "4026759/sponsorblock-latest.xpi:sponsorBlocker@ajay.app" # SponsorBlock
 "4026911/steam_database-latest.xpi:firefox-extension@steamdb.info" # SteamDB
 "3900368/cute_save_button-latest.xpi:ochecuteextension@plaza.ink" # Cute Save Button
 "3983650/downthemall-latest.xpi:{DDC359D1-844A-42a7-9AA1-88A850A938A8}" # DownloadThemAll!
 "3971429/cookie_autodelete-latest.xpi:CookieAutoDelete@kennydo.com" # Cookie AutoDelete
 "4027739/dollchan_extension-latest.xpi:dollchan_extension@dscript.me" # Dollchan Extension Tools
 "1051594/switchyomega-latest.xpi:switchyomega@feliscatus.addons.mozilla.org" # Proxy SwitchyOmega
 "3452835/cookies_txt_one_click-latest.xpi:{520a19d3-2d3c-47ee-ba15-cd66aae65db2}" # cookies-txt-one-click
 "3988430/bookmark_dupes-latest.xpi:bookmarkdupes@martin-vaeth.org" # Bookmark Dupes
 "1705492/fixed_zoom-latest.xpi:{a655a6b2-69a5-40de-a3b8-3f7f200c95a7}" # Fixed Zoom
 "3782841/enforce_browser_fonts-latest.xpi:{83e08b00-32de-44e7-97bb-1bab84d1350f}" # Enforce Browser Fonts - полезно особенно для Linux
 "3941342/dont_accept_webp-latest.xpi:dont-accept-webp@jeffersonscher.com" # Don't "Accept" image/webp

# "3988775/7tv-latest.xpi:{7ef0f00c-2ebe-4626-8ed7-3185847fcfad}" # 7TV (Twitch) - Удалён
# "3998783/floccus-latest.xpi:floccus@handmadeideas.org.xpi"
# "3932862/multi_account_containers-latest.xpi:@testpilot-containers.xpi"
)

# Загрузка и установка расширений
for EXTENSION in "${EXTENSIONS[@]}"; do
  PARTIAL_URL=$(echo "$EXTENSION" | cut -d ':' -f 1)
  ID=$(echo "$EXTENSION" | cut -d ':' -f 2)
  URL="https://addons.mozilla.org/firefox/downloads/file/${PARTIAL_URL}"
  FILENAME="$ID.xpi"
  wget -q --show-progress --hsts-file=~/.cache/wget-hsts -O "${FIREFOX_PROFILE_PATH}/extensions/$FILENAME" "$URL"
done

# Импорт Firefox конфига
cp -v ~/.dotfiles/user.js "${FIREFOX_PROFILE_PATH}"
fi

# Установка и настройка окружения
PS3="Выберите окружение: "
select ENTRY in "plasma" "gnome" "i3wm" "sway"; do
    export DESKTOP_ENVIRONMENT=$ENTRY && echo "Выбран ${DESKTOP_ENVIRONMENT}."

    if [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
        $HOME/scriptinstall/plasma.sh
    elif [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
        $HOME/scriptinstall/gnome.sh
    elif [ ${DESKTOP_ENVIRONMENT} = "i3wm" ]; then
        $HOME/scriptinstall/i3wm.sh
    elif [ ${DESKTOP_ENVIRONMENT} = "sway" ]; then
        $HOME/scriptinstall/sway.sh
    fi

    break
done

# Установка игровых пакетов и настройка
if read -re -p "Хотите играть в игры? (y/n): " ans && [[ $ans == 'y' || $ans == 'Y' ]]; then
	$HOME/scriptinstall/gaming.sh
fi

# Установка пакетов для виртуализации и настройка
if read -re -p "Хотите виртуализацию? (y/n): " ans && [[ $ans == 'y' || $ans == 'Y' ]]; then
	$HOME/scriptinstall/vm_support.sh
fi

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

# Включение мониторинга списков снимков grub
sudo systemctl enable grub-btrfsd

# Востановление прав доступа по требованию пакетов
sudo chmod -v 775 /var/lib/AccountsService/
sudo chmod -v 1770 /var/lib/gdm/
fi


# Скрыть приложения из меню запуска
APPLICATIONS=('assistant' 'avahi-discover' 'designer' 'electron' 'electron22' 'electron23' 'electron24' 'electron25' 'htop' 'linguist' 'lstopo' 'vim' 'nvim' 'org.kde.kuserfeedback-console' 'qdbusviewer' 'qt5ct' 'qv4l2' 'qvidcap' 'bssh' 'bvnc' 'mpv' 'uxterm' 'xterm' 'btop' 'scrcpy' 'scrcpy-console' 'rofi' 'rofi-theme-selector' 'picom')
# 'jconsole-java-openjdk' 'jshell-java-openjdk'
for APPLICATION in "${APPLICATIONS[@]}"
do
    # Создаём локальную копию ярлыков в пользовательскую директорию для применение свойств
	mkdir -v ${HOME}/.local/share/applications
    cp -v /usr/share/applications/${APPLICATION}.desktop ${HOME}/.local/share/applications/${APPLICATION}.desktop 2>/dev/null || :

    if test -f "${HOME}/.local/share/applications/${APPLICATION}.desktop"; then
        echo "NoDisplay=true" >> ${HOME}/.local/share/applications/${APPLICATION}.desktop
        echo "NotShowIn=GNOME;Xfce;KDE;" >> ${HOME}/.local/share/applications/${APPLICATION}.desktop
    fi
done

# Отключить мониторный режим микрофона Samson C01U Pro при старте системы
amixer sset -c 3 Mic mute

# Включение сервисов
systemctl --user enable \
 mpd \
 mpd-mpris \
 opentabletdriver.service

# Чистка
sudo pacman -R --noconfirm $(/bin/pacman -Qtdq)
