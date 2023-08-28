#!/bin/bash

# Позаимствовано
# https://github.com/arkenfox/user.js/blob/master/user.js
# https://github.com/farag2/Mozilla-Firefox/blob/master/user.js
# https://github.com/gjpin/arch-linux/blob/main/setup.sh

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


echo "==> Установка моих основных пакетов Pacman"
PKGS=(

# --- XORG

 'xterm' # Терминал для TTY
 'xorg-server' # XOrg сервер
 'xorg-xinit' # XOrg инициализация
 'xorg-xrandr' # Менять разрешение
 'xorg-xinput' # Для работы граф.планшета XP-PEN G640 + OpenTabletDriver
 'xorg-xgamma' # Позволяет менять и исправлять гамму для игр используя Lutris
 'xf86-video-amdgpu' # Открытые драйвера AMDGPU

# --- ДРАЙВЕРА

 'mesa' 'lib32-mesa' # Версия OpenGL с открытым исходным кодом
 'mesa-vdpau' 'lib32-mesa-vdpau' # VDPAU Драйвер
 'libva-mesa-driver' 'lib32-libva-mesa-driver' # VA-API драйвер

 'vulkan-radeon' 'lib32-vulkan-radeon' # Реализация Vulkan драйвера от Mesa
 'vulkan-mesa-layers' 'lib32-vulkan-mesa-layers' # Слои Vulkan в Mesa

# --- АУДИО

 'pipewire'
 'pipewire-pulse'
 'pipewire-alsa'
 'pipewire-jack' 'lib32-pipewire-jack'
 'pipewire-v4l2' # Для правильной работы вебки в OBS
 'wireplumber' # Modular session / policy manager for PipeWire
 'gst-plugin-pipewire' # Плагины gst для поддержки форматов MP3, AAC, FLAC, MPEG
 'qpwgraph' # Графический интерфейс управления узлами PipeWire


# --- АУДИО Разное / Кодеки

 'mpd' # Музыкальный сервер
 'mpc' # Контроллер управления музыкой через терминал
 'ncmpcpp' # TUI музыкальный плеер
 'playerctl' # Для работы fn+f6/7/8 и других приколюх
 'mediainfo' # Информация о медиа
 'alsa-utils' # Утилиты ALSA, в числе которых alsamixer и amixer
 'pulsemixer' # TUI Регулятор громкости PulseAudio.
 'noise-suppression-for-voice' # (Pipewire only) Плагин подавления шума микрофона в реальном времени

 'gstreamer'
 'gst-libav'
 'gst-plugins-base' 'lib32-gst-plugins-base'
 'gst-plugins-good' 'lib32-gst-plugins-good'
 'gst-plugins-bad' # Библеотеки для воспроизведения мультимедия (для запуска старья)
 'gst-plugins-ugly' # Библеотеки для воспроизведения мультимедия (для запуска старья)
 'gstreamer-vaapi' # Эффективный плагин кодировщик для RDNA1 AMDGPU (для использования нужен AUR пакет obs-gstreamer)

# --- СЕТЬ

 'networkmanager-openvpn'
 'openvpn'
 'modemmanager' # Управление модемом
# 'wpa_supplicant' 'wireless_tools' # Пакеты для ноутбуков

# --- BLUETOOTH

 'bluez' # Демон для стека протокола Bluetooth
 'bluez-utils' # CLI менеджер подключений bluetoothctl

# --- Принтеры и печать

# 'system-config-printer' # Менеджер принтеров
# 'cups' # Модульная система печати для принтеров
# 'cups-pdf' # Поддержка печати PDF файлов

# --- TUI/CLI Утилиты и прочее необходимое

 'stow' # Менеджер sim-link'ов (для менеджмента dotfiles)
 'expac' # Утилита извлечения данных alpm (базы данных pacman)
 'rebuild-detector' # Показывает лист AUR пакетов которые были собраны на старых версиях зависимостей, для их дальнейшей пересборки
 'archlinux-wallpaper' # Arch Linux обои
 'rsync' # Быстрый и универсальный инструмент для копирования удаленных и локальных файлов
 'htop' # Простой консольный диспетчер задач
 'btop' # TUI Диспетчер задач
 'hexedit' # TUI HEX-редактор
 'testdisk' # TUI Востановления данных
 'ncdu' # TUI анализатор свободного места
 'radeontop' # TUI мониторинг AMD GPU
 'xdg-utils' # CLI инструменты для решения различных задач с интеграцией рабочего стола
 'neofetch' # Чтобы выпендриватся
 'ripgrep' # Более быстрая альтернатива grep
 'inxi' # Системная информация PC
 'hwinfo' # Системная информация
 'unzip' # Архивирование и распаковка файлов zip/rar/7z
 'unrar' # Архивирование и распаковка файлов rar
 'p7zip' # Архивирование и распаковка файлов 7z
 'exfat-utils' # Поддержка файловой системы exFAT (Для sd-карт)
 'ntfs-3g' # Поддержка файловой системы NTFS
 'dosfstools' # Поддержка файловой системы vFAT
 'f2fs-tools' # Поддержка файловой системы f2fs
 'mtools' # Утилиты для доступа к MS-DOS дискам
 'gvfs-mtp' # MTP передача для Android
 'gvfs' # Поддержка мусорки для файлого менеджера
 'gtk2' # Для устаревших программ
 'yt-dlp' # Скачивать видео
 'ffmpeg' # Конвертер/Декодер/Рекордер видео
 'smartmontools' # Для информации и проверки состояния здоровья HDD и SSD
 'ripgrep' # Более быстрая альтернатива grep
 'fd' # Поиск файлов
 'exa' # Замена ls
 'bat' # Замена cat
 'pkgfile' # Для плагина zsh "command-not-found"
 'netctl' # Управление сетью systemd на основе профилей
 'net-tools' # Для прослушивания портов
 'nmap' # Утилита для исследования сети и сканер портов
 'zbar' # Сканер QR кодов
 'tesseract' # OCR сканер
 'tesseract-data-rus' 'tesseract-data-eng' 'tesseract-data-jpn' # База данных языков
 'man-pages' 'man-db' # Мануалы
 'aspell-ru' # Русский словарь для проверки орфографии (работает только с UTF8 кодировкой)
 'atool' # Для предпросмотра архивов
 'libfaketime' # Подделывать время для программ или пиратских игр (man faketime)
 'flashrom' # Для прошивания чипов программатором ch341a
 'dfu-util' # Для обновления прошивки паяльника Pinecil первой версии
 'scrcpy' # Демонстрация экрана Android для Linux используя USB ADB
 'translate-shell' # Переводчик в терминале (необходим для скриптов)
 'i2pd' # Невидимый интернет протокол
 'cdemu-client' # Эмуляция iso/mds/nrg образов
 'transmission-cli' # Для замены passkey в торрент файлах и многое другое
 'jre-openjdk' # Java библиотеки (для Minecraft)
 'v4l2loopback-dkms' # Для поддержки виртуальной камеры для OBS

 'libva-utils' # Проверка VA-API дравера командой (vainfo)
 'vdpauinfo' # Проверка VDPAU драйвера командой (vdpauinfo)
 'vulkan-tools' # Инструменты vulkan (vulkaninfo)

 'jq' # CLI обработчик JSON (Необходимо для mpv-webtorrent-hook)
 'yarn' # Для neovim плагина https://github.com/iamcco/markdown-preview.nvim
 'tidy' # Инструмент для приведения HTML-кода к чистому стилю

# --- ШРИФТЫ

 'ttf-hack-nerd' # Шрифты для иконок в терминале
 'ttf-jetbrains-mono-nerd' # Шрифты для иконок в терминале
 'ttf-sourcecodepro-nerd' # Шрифты для иконок в терминале
 'ttf-font-awesome' # Для появления монотонных значков и иконок
 'ttf-opensans' # Шрифт для Телеграмма
 'ttf-droid' # Android'ский шрифт не имеющий нуля с прорезью, поэтому 0 и O не различимы
 'ttf-liberation' # Начальный набор шрифтов
 'ttf-dejavu' # Начальный набор шрифтов
 'noto-fonts-cjk' # Набор Азиатских шрифтов, много весят
 'noto-fonts-emoji' # Смайлы в терминал
 'noto-fonts' # Необходимые шрифты, разные иероглифы и т.д

# --- ПРОГРАММЫ

# 'firefox' 'firefox-i18n-ru' # Браузер Firefox + Руссификация
# 'libreoffice-fresh' 'libreoffice-fresh-ru' # Офисный пакет LibreOffice + Руссификация
 'obs-studio' # Запись видео и трансляции
 'mpv' # Лучший видеопроигрыватель
 'songrec' # Распознование аудио композиций
# 'qmmp' # Современный аудиоплеер старой школы (т.е Winamp) с поддержкой скинов
 'audacious' # Аудиоплеер с поддержкой скинов Winamp
 'keepassxc' # Локальный менеджер паролей
 'qbittorrent' # Торрент клиент
# 'bleachbit' # Чистильщик для Linux
# 'gimp' # Фоторедактор
# 'audacity' # Продвинутый аудиорекордер
# 'kdenlive' # Видеоредактор
# 'piper' # Настройка мышки Logitech
# 'discord'
 'telegram-desktop' # Мессенджер
)

# Обнаружение виртуалки
if [[ "$(systemd-detect-virt)" == "kvm" ]]; then
 PKGS+=(qemu-guest-agent spice-vdagent)
 # В оконных менеджерах (WM) для активации Shared Clipboard в терминале надо ввести spice-vdagent
elif [[ "$(systemd-detect-virt)" == "oracle" ]]; then
 PKGS+=(virtualbox-guest-utils xf86-video-vmware)
 usermod -a -G vboxsf "${USER_NAME}"
 # sudo systemctl enable vboxservice.service
fi

sudo pacman -S "${PKGS[@]}" --noconfirm --needed

# Установка Yay (AUR помощник)
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin && makepkg -si --noconfirm
cd .. && rm -rf yay-bin

# Настройка yay
# --nodiffmenu - Не спрашивать об показе изменений (diff)
# --nocleanmenu - Не спрашивать о пакетах для которых требуется очистить кэш сборки
# --removemake - Всегда удалять зависимости для сборки (make) после установки
# --batchinstall - Ставит каждый собранный пакеты в очередь для установки (легче мониторить что происходит)
yay --save --nodiffmenu --nocleanmenu --removemake --batchinstall

echo "==> Установка AUR пакетов"
PKGS=(

# --- ПРОГРАММЫ

 'ungoogled-chromium-bin' # Полностью вычещенный от Гуглятины браузер Chromium
# 'fancontrol-gui' # GUI обвертка fancontrol для управление вентиляторами
# 'czkawka-gui-bin' # Удобный инструмент для удаления дубликатов
 'opentabletdriver' # Драйвер для граф. планшета XP-PEN G640
 'ventoy-bin' # Создание загрузочной флешки для Win/Linux образов
# 'cpu-x' # CPU-Z для Linux

# --- ШРИФТЫ

# 'otf-monocraft' # Пиксельный шрифт для Mangohud

# --- Утилиты и разное

 'chromium-widevine' # Плагин для работы DRM контента в браузере ungoogled-chromium
 'mpd-mpris' # MPRIS поддержка для MPD
 'webtorrent-cli' 'xidel' # Просмотр онлайн торренты (Необходимо для mpv-webtorrent-hook)
 'obs-gstreamer' # Более эффективный плагин кодировщик для OBS (Для RDNA 1)
 'obs-vkcapture-git' 'lib32-obs-vkcapture-git' # OBS плагин для захвата напрямую через API OpenGL/Vulkan (минимизирует затраты)
 'amd-vulkan-prefixes' # Быстрое переключение icd драйверов AMD используя переменные (vk_radv, vk_amdvlk, vk_pro)
# 'android-apktool' # Декомпиляция apk файлов
# 'gallery-dl' # Скачивать с различных платформ (deviantart, pixiv и т.д) без регистрации и смс
# 'kyocera-print-driver' # Драйвер для Kyocera FS-1060DN
)

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
git clone --recurse-submodules https://gitlab.com/anzix/dotfiles.git
cd dotfiles/base
stow -vt ~ */
# Переменные при активной сессии Xorg или Wayland
# Некоторые DM экспортируют только ~/.profile независимо от используемого $SHELL'а, измените если необходимо
ln -siv $HOME/dotfiles/base/zsh/.config/zsh/profile.zsh ~/.zprofile

# Проверяю наличие браузера Firefox
if pacman -Qs firefox > /dev/null; then

echo "==> Настройка и экспорт моих настроек Firefox"

# Временно открыть Firefox, чтобы создать папку профиля.
sudo -u $(whoami) timeout 5 firefox --headless

# Устанавливаю путь к профилю Firefox
FIREFOX_PROFILE_PATH=$(realpath /${HOME}/.mozilla/firefox/*.default-release)

# Импорт темы
curl https://addons.mozilla.org/firefox/downloads/file/3913593/matte_black_red-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{a7589411-c5f6-41cf-8bdc-f66527d9d930}.xpi

# Импорт расширений
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
cp dotfiles/user.js ${FIREFOX_PROFILE_PATH}
fi


mkdir -p ~/Pictures/{Screenshots/mpv,Gif}
mkdir -p ~/Documents/Backup
mkdir ~/.config/mpd/playlists

# Для функции "aurstore" в ~/.config/zsh/aliases.zsh
sudo pacman -Fy

# Установка игровых пакетов и настройка
if [ ${GAMING} = "y" ]; then
	/scriptinstall/gaming.sh
fi

# Установка пакетов для виртуализации и настройка
if [ ${VM_SETUP} = "y" ]; then
	/scriptinstall/vm_support.sh
fi

# Установка и настройка окружения
if [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
	/scriptinstall/plasma.sh
elif [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
    /scriptinstall/gnome.sh
elif [ ${DESKTOP_ENVIRONMENT} = "i3wm" ]; then
    /scriptinstall/i3wm.sh
elif [ ${DESKTOP_ENVIRONMENT} = "sway" ]; then
	/scriptinstall/sway.sh
fi

# Усиление защиты
sudo sed -ri -e "s/^#PermitRootLogin.*/PermitRootLogin\ no/g" /etc/ssh/sshd_config

# Отключить мониторный режим микрофона Samson C01U Pro при старте системы
amixer sset -c 3 Mic mute

# Врубаю сервисы
# joycond: Для активации Virtual Pro Controller нажать одновременно - +
sudo systemctl enable \
 bluetooth.service \
 grub-btrfsd \
# joycond
# zerotier-one.service

sudo systemctl --user enable \
 mpd \
 mpd-mpris \
 opentabletdriver.service
# cdemu-daemon.service

# Чистка
sudo pacman -R --noconfirm $(/bin/pacman -Qtdq)

echo -e "\e[1;32m----------Установка системы завершена! Выполните ребут----------\e[0m"
