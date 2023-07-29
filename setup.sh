#!/bin/bash

# Позаимствовано
# https://github.com/YurinDoctrine/arch-linux-base-setup/blob/main/arch-linux-base-setup.sh

clear >$(tty)

read -p "Desktop environment (plasma / gnome / i3wm): " DESKTOP_ENVIRONMENT
export DESKTOP_ENVIRONMENT

echo "==> Оптимизация makepkg"
# Выставляю архитектуру
sudo sed -i 's|CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt -fexceptions|CFLAGS="-march=native -mtune=native -O2 -pipe -fno-plt -fexceptions|g' /etc/makepkg.conf
# Использовать все потоки ядер при компиляции
sudo sed -i -e 's/-j.*/-j$(expr $(nproc) - 1) -l$(nproc)"/;s/^#MAKEFLAGS/MAKEFLAGS/;s/.*#RUSTFLAGS=.*/RUSTFLAGS="-C opt-level=2 -C target-cpu=native"/' /etc/makepkg.conf
# Выставляю BUILDENV (включаю ccache)
sudo sed -i -e 's|BUILDENV.*|BUILDENV=(!distcc color ccache check !sign)|g' /etc/makepkg.conf
# Сборка файлов в памяти
sudo sed -i -e "s|#BUILDDIR.*|BUILDDIR=/tmp/makepkg|g" /etc/makepkg.conf
# Использовать все ядра для сжатия
sudo sed -i -e "s/xz.*/xz -c -z -q - --threads=$(nproc))/;s/^#COMPRESSXZ/COMPRESSXZ/;s/zstd.*/zstd -c -z -q - --threads=$(nproc))/;s/^#COMPRESSZST/COMPRESSZST/;s/lz4.*/lz4 -q --best)/;s/^#COMPRESSLZ4/COMPRESSLZ4/" /etc/makepkg.conf
# Использовать другой алгоритм сжатия
sudo sed -i -e "s/PKGEXT.*/PKGEXT='.pkg.tar.lz4'/g" /etc/makepkg.conf


echo "==> Установка Yay (AUR помощник)"
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin && makepkg -si --noconfirm
cd ~ && rm -rf yay-bin

# Настройка yay
# --nodiffmenu - Не спрашивать об показе изменений (diff)
# --nocleanmenu - Не спрашивать о пакетах для которых требуется очистить кэш сборки
# --removemake - Всегда удалять зависимости для сборки (make) после установки
# --batchinstall - Ставит каждый собранный пакеты в очередь для установки (легче мониторить что происходит)
yay --save --nodiffmenu --nocleanmenu --removemake --batchinstall

echo "==> Установка основных пакетов Pacman"
PKGS=(

# --- XORG / Graphics driver / Hardware encoding
	
 'xterm' # Терминал для TTY
 'xorg-server' # XOrg сервер
 'xorg-xinit' # XOrg инициализация
 'xorg-xrandr' # Менять разрешение
 'xorg-xinput' # Для работы граф.планшета XP-PEN G640 + OpenTabletDriver
 'xorg-xgamma' # Позволяет менять и исправлять гамму для игр используя Lutris
 'xf86-video-amdgpu' # Открытые драйвера AMDGPU

 'mesa' # Open source version of OpenGL
 'libva-mesa-driver' 'lib32-libva-mesa-driver' # VA-API драйвер

 'mesa-vdpau' 'lib32-mesa-vdpau' # VDPAU Драйвер
 'glu' # Библеотеки утилит Mesa OpenGL (необходимо для запуска Goverlay)
 'vulkan-tools' # Инструменты vulkan (vulkaninfo)
 'vulkan-radeon' 'lib32-vulkan-radeon' # Реализация vulkan драйвера от Mesa
 'vulkan-mesa-layers' 'lib32-vulkan-mesa-layers'
 'libva-vdpau-driver' 'lib32-libva-vdpau-driver' # A VDPAU-based backend for VA-API
 'libvdpau-va-gl' # VDPAU driver with OpenGL/VAAPI backend. H.264 only

# --- AUDIO [3 Варианта]
        
# 1) Pipewire

 'pipewire' 'lib32-pipewire'
 'wireplumber' # Modular session / policy manager for PipeWire
 'pipewire-pulse'
 'pipewire-alsa'
 'pipewire-v4l2' # Для правильной работы вебки в OBS
 'jack2' 'lib32-jack2'
 'jack2-dbus' # Для dbus интеграции
 'gst-plugin-pipewire'
 'qpwgraph' # Графический интерфейс PipeWire Graph Qt

# 2) PulseAudio

# 'pulseaudio' # PulseAudio sound components
# 'pulseaudio-alsa' # ALSA configuration for pulse audio

# 3) Только Alsa

# 'alsa'
# 'alsa-firmware'
# 'alsa-card-profiles'

# --- AUDIO Разное / Кодеки

 'mpd' # Музыкальный сервер к которому можно конектится
 'mpc' # Контроллер управления музыкой через терминал
 'ncmpcpp' # TUI музыкальный плеер
 'playerctl' # Для работы fn+f6/7/8 и других приколюх
 'mediainfo' # Информация о медиа
 'alsa-utils' # Advanced Linux Sound Architecture (Чтобы убрать через alsamixer прослушивание себя через микро)
 'alsa-plugins' # ALSA plugins
 'pavucontrol' # GTK PulseAudio volume control

 'gstreamer'
 'gst-libav'
 'gst-plugins-base' 'lib32-gst-plugins-base'
 'gst-plugins-good' 'lib32-gst-plugins-good'
 'gst-plugins-bad' # Библеотеки для воспроизведения мультимедия (для запуска старья)
 'gst-plugins-ugly' # Библеотеки для воспроизведения мультимедия (для запуска старья)
 'gstreamer-vaapi' # Эффективный плагин кодировщик для RDNA1 AMDGPU (для использования нужен AUR пакет obs-gstreamer)

# --- BLUETOOTH

'bluez' # Daemons for the bluetooth protocol stack
'bluez-utils' # Bluetooth development and debugging utilities. Содержит bluetoothctl

# --- GAMING and EMULATION

 'steam'
 'mangohud' 'lib32-mangohud' # Мониторинг для игр
 'lutris' # GUI обвёртка Wine
 'wine-staging' 'wine-gecko' 'wine-mono' 
 'winetricks' # Протаскивать библиотеки/dll'ки в префикс Wine
 'gamemode' 'lib32-gamemode' # Игровой режим для игр
 'zerotier-one' # Создание и подключение к виртуальным сетям (для игр с друзьями)
# 'gameconqueror' # (Не)Альтернатива Cheat Engine
# 'pcsx2' # PS2 Эмулятор
# 'dolphin-emu' # Gamecube Эмулятор


# --- UTILITIES AND STUFF

 'stow' # Менеджер sim-link'ов (для менеджмента dotfiles)
 'pacman-contrib' # Скрипты и инструменты для Pacman
 'expac'# Утилита извлечения данных alpm (базы данных pacman)
 'rebuild-detector' # Показывает лист AUR пакетов которые были собраны на старых версиях зависимостей, для их дальнейшей пересборки
 'archlinux-wallpaper' # Arch Linux обои
 'reflector' # Инструмент для оптимизации зеркал Pacman
 'rsync' # Быстрый и универсальный инструмент для копирования удаленных и локальных файлов
 'radeontop' # Мониторинг AMD GPU        
 'xdg-utils' # Command line tools that assist applications with a variety of desktop integration tasks
 'htop' # Простой консольный диспетчер задач
 'btop' # TUI Диспетчер задач
 'neofetch' # Чтобы выпендриватся
 'inxi' # Системная информация PC
 'exfat-utils' # Поддержка файловой системы exFAT (Для sd-карт)
 'ntfs-3g' # Поддержка файловой системы NTFS
 'e2fsprogs' # Поддержка файловой системы ext4
 'dosfstools' # Поддержка файловой системы vFAT
 'f2fs-tools' # Поддержка файловой системы f2fs
 'gvfs-mtp' # MTP backend; Android, media player
 'gvfs' # Подсистема среды рабочего стола GNOME (является trashcan для фм pcmanfm)
 'gtk2'
 'wget' # Для скачивания файлов
 'unzip' # Архивирование и распаковка файлов zip
 'unrar' # Архивирование и распаковка файлов rar
 'p7zip' # Архивирование и распаковка файлов 7z
 'yarn' # Для neovim плагина https://github.com/iamcco/markdown-preview.nvim
 'yt-dlp' # Скачивать видео
 'ffmpeg' # Конвертер/Декодер/Рекордер видео
 'smartmontools' # Для информации и проверки состояния здоровья HDD и SSD
 'fd' # Поиск файлов
 'ripgrep' # Более быстрая альтернатива grep (необходимо для telescope плагин nvim)
 'exa' # Замена ls
 'pkgfile' # Для плагина zsh "command-not-found"
 'libva-utils' # Проверка VA-API дравера командой (vainfo)
 'vdpauinfo' # Проверка VDPAU драйвера командой (vdpauinfo)
 'net-tools' # Для прослушивания портов командой
 'hwinfo' # Системная информация
 'nmap' # Утилита для исследования сети и сканер портов
 'ncdu' # TUI анализатор свободного места
 'zbar' # Сканер QR кодов (для maim)
 'tesseract' # OCR сканер
 'tesseract-data-rus' 'tesseract-data-eng' 'tesseract-data-jpn' # Данные языка
 'jq' # (Необходимо для mpv-webtorrent-hook)
 'testdisk' # Востановления данных
 'aspell-ru' # Русский словарь для проверки орфографии (работает только с UTF8 кодировкой)
 'atool' # Для предпросмотра архивов через lf
 'noise-suppression-for-voice' # (Для pipewire) Плагин подавления шума микрофона в реальном времени в OBS
 'libfaketime' # Подделывать время для программ или пиратских игр (man faketime)
 'flashrom' # Для прошивания чипов программатором ch341a
 'dfu-util' # Для обновления прошивки паяльника Pinecil первой версии
 'hexedit' # TUI HEX-редактор
 'scrcpy' # Демонстрация экрана Android для Linux используя USB ADB
 'translate-shell' # Переводчик в терминале (необходим для скриптов)
 'bat' # Замена cat
# 'tor'
# 'torsocks'
 'i2pd'
# 'system-config-printer' # Менеджер принтеров
# 'cups' # Модульная система печати для принтеров
# 'cups-pdf' # Поддержка печати PDF файлов
 'cdemu-client' # Эмуляция образов
 'transmission-cli' # Для замены passkey в торрент файлах и многое другое
 'mame-tools' # Конвертирование .iso / .cue образов PS2 игр в сжатый .chd образ (chdman)
 'jre-openjdk' # Для работы Minecraft
 'jre-openjdk-headless' 
 'java-runtime-common'
 'lib32-sdl2' # Для работы steamcmd
 'lib32-dbus' # Для работы steamcmd
 'v4l2loopback-dkms' # Для поддержки виртуальной камеры для OBS
 'virt-manager' # Менеджер виртуальных машин
 'qemu-base' # Виртуализация
 'qemu-emulators-full' # Поддержка всех архитектур для виртуализации
 'dnsmasq' 
 'nftables' 
 'iptables-nft'
 'dmidecode' 
 'edk2-ovmf' # Поддержка UEFI для QEMU
 'swtpm' # Поддержка TPM для QEMU

# --- FONTS

 'terminus-font' # Позволяет выбрать более крупный шрифт для небольших экранов HiDPI
 'ttf-hack-nerd' # Шрифты для иконок в терминале
 'ttf-jetbrains-mono-nerd' # Шрифты для иконок в терминале
 'ttf-sourcecodepro-nerd' # Шрифты для иконок в терминале
# 'ttf-roboto' # Шрифт Google
 'ttf-font-awesome' # Для появления значков (Из https://fontawesome.com/v5/cheatsheet) из тем и i3 статус баром появляться
 'ttf-opensans' # Шрифт для Телеграмма
 'ttf-droid' # Android'ский шрифт не имеющий нуля с прорезью, поэтому 0 и O не различимы
 'ttf-liberation' # Начальный набор шрифтов 
 'ttf-dejavu' # Начальный набор шрифтов 
 'noto-fonts-cjk' # Набор Азиатских шрифтов, много весят
 'noto-fonts-emoji' # Смайлы в терминал     
 'noto-fonts' # Необходимые шрифты, разные иероглифы и т.д

# --- APPS

 'firefox' 'firefox-i18n-ru' # Браузер Firefox + Руссификация 
# 'libreoffice-fresh' 'libreoffice-fresh-ru' # Офисный пакет LibreOffice + Руссификация
 'obs-studio' # Запись видео и трансляции
 'mpv' # Лучший видеопроигрыватель
 'songrec' # Распознование аудио композиций
# 'qmmp' # Современный аудиоплеер старой школы (т.е Winamp) с поддержкой скинов
 'audacious' # Аудиоплеер с поддержкой скинов Winamp
 'keepassxc' # Локальный менеджер паролей
 'qbittorrent' # Торрент клиент
 'bleachbit' # Чистильщик для Linux
# 'gimp' # Фоторедактор
# 'audacity' # Продвинутый аудиорекордер
# 'kdenlive' # Видеоредактор
# 'piper' # Настройка мышки Logitech
# 'discord' # Чат для геймеров
 'telegram-desktop' # Мессенджер
)
sudo pacman -S "${PKGS[@]}" --noconfirm --needed


echo "==> Установка AUR пакетов"
PKGS=(

# --- APPS

 'ungoogled-chromium-bin' # Полностью вычещенный от Гуглятины браузер Chromium 
# 'czkawka-gui-bin' # Удобный инструмент для удаления дубликатов
 'opentabletdriver' # Драйвер для граф. планшета XP-PEN G640
 'ventoy-bin' # Создание загрузочной флешки для Win/Linux образов
# 'cpu-x' # CPU-Z для Linux

# --- GAMING

# 'lgogdownloader-qt5' # CLI обвёртка GOG (с рабочим логином)
 'heroic-games-launcher-bin' # Удобный EGS / GOG лаунчер для Linux
 'legacylauncher' # Minecraft лаунчер 
 'dxvk-bin' # Свежий dxvk для ручных префиксов Wine
 'vkd3d-proton' # Свежий vkd3d-proton (форк vkd3d) для ручных префиксов Wine
 'protontricks' # Протаскивать библиотеки/dll'ки в префикс Steam Proton
 'protonup-qt' # Удобная утилитка для скачки runner'ов Wine
# 'goverlay-bin' # GUI настройка оверлея MangoHud
 'vkbasalt' 'lib32-vkbasalt' # Постпроцессинг для игр
 'reshade-shaders-git' # Набор шейдеров необходимых для VkBasalt
# 'rpcs3-bin' # PS3 Эмулятор
# 'cemu' # Wii U Эмулятор
 'game-devices-udev' # Udev правила для работы контроллеров 8BitDo в эмуляторов Cemu и других
 'joycond-git' # Альтернатива BetterJoy
 'joycond-cemuhook-git' # Для работы по UDP Switch контроллера (8BitDo Pro 2) в режиме гироскопа
# 'flashplayer-standalone' # (Устаревшее) Запуск локальных .swf (Flash) файлов
# 'ruffle-nightly-bin' # Современный эмулятор Flash плеера для запуска .swf файлов

# --- FONTS
    
 'otf-monocraft' # Пиксельный шрифт для Mangohud
	
# --- UTILITIES

 'radeon-profile-git' # Графическое ПО управление питанием и вентиляторами AMDGPU
 'radeon-profile-daemon-git' # Демон для управление питанием и вентиляторами AMDGPU
 'obfs4proxy' # Обфускация трафика тор
 'webtorrent-cli' # Просмотр онлайн торренты (Необходимо для mpv-webtorrent-hook) 
 'xidel' # (Необходимо для mpv-webtorrent-hook)
 'obs-gstreamer' # Более эффективный плагин кодировщик для OBS (Для RDNA 1)
 'obs-vkcapture-git' 'lib32-obs-vkcapture-git' # OBS плагин для захвата напрямую через API OpenGL/Vulkan (минимизирует затраты)
 'amd-vulkan-prefixes' # Быстрое переключение icd драйверов AMD используя переменные (vk_radv, vk_amdvlk, vk_pro)
# 'android-apktool' # Декомпиляция apk файлов
# 'gallery-dl' # Скачивать с различных платформ (deviantart, pixiv и т.д) без регистрации и смс
	
# --- THEMES
# --- OTHER

 'chromium-widevine' # Плагин для работы DRM контента в браузере ungoogled-chromium
 'mpd-mpris' # MPRIS поддержка для MPD
# 'kyocera-print-driver' # Драйвер для Kyocera FS-1060DN

)
yay -S "${PKGS[@]}" --noconfirm --needed


echo "==> Установка моего dotfiles"
cd ~
git clone --recurse-submodules https://gitlab.com/anzix/dotfiles.git
cd dotfiles/base
# Вытягиваю только необходимые конфиги
stow -vt ~ zsh gtk \
	mpd ncmpcpp nvim pipewire wireplumber mpv `# Media & Sound` \
	mangohud vkBasalt otd `# Gaming` \
	npm browser-flags wget
# Переменные при активной сессии Xorg или Wayland
# Некоторые ДМ экспортируют только ~/.profile независимо от используемого $SHELL'а, измените если необходимо
ln -siv $HOME/dotfiles/base/zsh/.config/zsh/profile.zsh ~/.zprofile


# Дать возможность gamemode выставлять приоритет процесса игры (renice)
# https://wiki.archlinux.org/title/Gamemode#Renicing
sudo usermod -aG gamemode $(whoami)

# Настройка Firefox
./dotfiles/firefox_setup


mkdir -p ~/Pictures/{Screenshots/mpv,Gif}
mkdir -p ~/Documents/Backup
mkdir ~/.config/mpd/playlists

# Для функции "aurstore" в ~/.config/zsh/aliases.zsh
sudo pacman -Fy


echo "==> Настройка граф. планшета Xp-Pen G640 для работы OpenTabletDriver"
echo "blacklist hid_uclogic" | sudo tee -a /etc/modprobe.d/blacklist.conf >/dev/null
sudo rmmod hid_uclogic

# Отключение системного звукового сигнала
echo "blacklist pcspkr" | sudo tee -a /etc/modprobe.d/nobeep.conf
sudo rmmod pcspkr

sudo mkinitcpio -P

echo "==> Оптимизация записи на диск"
sudo sed -i -e s"/\Storage=.*/Storage=none/"g /etc/systemd/coredump.conf
sudo sed -i -e s"/\Storage=.*/Storage=none/"g /etc/systemd/journald.conf
sudo systemctl daemon-reload

echo "==> Настройка оформления GTK к root окружению"
#GTK 2.0
sudo rm -r /usr/share/gtk-2.0/gtkrc
sudo ln -sv ~/.config/gtk-2.0/gtkrc-2.0 /usr/share/gtk-2.0/gtkrc
#GTK 3.0
sudo rm -r /usr/share/gtk-3.0/settings.ini
sudo ln -sv ~/.config/gtk-3.0/settings.ini /usr/share/gtk-3.0/settings.ini


echo "==> Применение универсального host файла"
cp /etc/hosts ~/Documents/Backup/hosts.bak
wget -qO- https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts | sudo tee --append /etc/hosts >/dev/null


# Добавление доп. разделов
echo "
UUID=F46C28716C2830B2   /media/Distrib  ntfs-3g        rw,nofail,errors=remount-ro,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0       0
UUID=CA8C4EB58C4E9BB7   /media/Other    ntfs-3g        rw,nofail,errors=remount-ro,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0       0
UUID=A81C9E2F1C9DF890   /media/Media    ntfs-3g        rw,nofail,errors=remount-ro,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0       0
UUID=30C4C35EC4C32546   /media/Games    ntfs-3g        rw,nofail,errors=remount-ro,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0       0" | sudo tee -a /etc/fstab >/dev/null

# Обнаружение виртуалки
if [ "$(systemd-detect-virt)" = "none" ]; then
echo "==> Настройка libvirt/QEMU/KVM для виртуализции"
sudo cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.bak
sudo sed -i 's|^#unix_sock_group|unix_sock_group|' /etc/libvirt/libvirtd.conf
sudo sed -i 's|^#unix_sock_rw_perms|unix_sock_rw_perms|' /etc/libvirt/libvirtd.conf
sudo cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.bak
sudo sed -i 's|#user = .*|user = "'$(id -un)'"|g' /etc/libvirt/qemu.conf
sudo sed -i 's|^#group = .*|group = "'wheel'"|g' /etc/libvirt/qemu.conf
sudo usermod -aG libvirt,kvm $(whoami)
# Убираю конфликтующие строки с hosts для правильной работы dnsmasq
sudo sed -i '/fe80::1%lo0 localhost/d;/0.0.0.0 27--01bbcpolice.powercoremedia.com/d;/0.0.0.0 www.27--01bbcpolice.powercoremedia.com/d' /etc/hosts
# Запускаем сервис
sudo systemctl enable libvirtd

read -p "Дефолтная сеть или мост для VM?
1 - Default, 2 - Bridge: " NETWORK_VM
export NETWORK_VM
if [ ${NETWORK_VM} = '1' ]; then
  # Автозапуск вирт. сети [default] при запуске системы 
  sudo virsh net-autostart default
  # Включить [default] вирт. сеть
  sudo virsh net-start default
elif [ ${NETWORK_VM} = '2' ]; then
  echo "==> Создане моста и настройка сети на ваших виртуальных машинах"
  touch ~/.config/br10.xml
  tee -a ~/.config/br10.xml > /dev/null << END
<network>
<name>br10</name>
<forward mode='nat'>
<nat>
    <port start='1024' end='65535'/>
</nat>
</forward>
<bridge name='br10' stp='on' delay='0'/>
<ip address='192.168.30.1' netmask='255.255.255.0'>
<dhcp>
    <range start='192.168.30.50' end='192.168.30.200'/>
</dhcp>
</ip>
</network>
END
  echo "==> Добавление и автозапуск моста"
  sudo virsh net-define ~/.config/br10.xml
  sudo virsh net-autostart --network br10
  sudo virsh net-autostart --network default
fi
fi

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


# Обнаружение файловой системы
if hash snapper 2>/dev/null; then
PKGS=(
 'snap-pac' # делает снапшоты после каждой установки/обновления/удаления пакетов Pacman
 'grub-btrfs' # добавляет grub меню снимков созданных snapper чтобы в них загружаться
 'inotify-tools' # необходимая зависимость для grub-btrfs
 'snap-pac-grub' # дополнительно обновляет записи GRUB для grub-btrfs после того, как snap-pac сделал снимки
 'snp' # заворачивает любую shell команду и создаёт снимок до выполнения этой команды (snp sudo pacman -Syu)
 'btrfs-assistant' # Gui программа обслуживания файловой системы Btrfs и для создания снимков
)
  gpg --recv-keys 56C3E775E72B0C8B1C0C1BD0B5DB77409B11B601
  yay -S "${PKGS[@]}" --noconfirm --needed

  # Enable GRUB-BTRFS service
  #sudo systemctl enable grub-btrfsd.service

  # Configure initramfs to boot into snapshots using overlayfs (read-only mode)
  # Source: https://github.com/Antynea/grub-btrfs/blob/master/initramfs/readme.md
  sudo sed -i "s|keymap)|keymap grub-btrfs-overlayfs)|g" /etc/mkinitcpio.conf

  # Пересоздаём initramfs
  sudo mkinitcpio -P
  
  # Пересоздаём grub.cfg для включения под-меню grub
  sudo grub-mkconfig -o /boot/grub/grub.cfg

else
yay -S timeshift-bin --noconfirm --needed
fi

# Усиление защиты
sudo sed -ri -e "s/^#PermitRootLogin.*/PermitRootLogin\ no/g" /etc/ssh/sshd_config

# Отключить мониторный режим микрофона Samson C01U Pro при старте окружения
amixer sset -c 3 Mic mute

# Врубаю сервисы
sudo systemctl enable bluetooth.service
sudo systemctl enable --now radeon-profile-daemon
#sudo systemctl enable --now joycond # Для активации Virtual Pro Controller нажать одновременно - +
#sudo systemctl enable --now zerotier-one.service
systemctl --user enable --now mpd-mpris
systemctl --user enable --now mpd
#systemctl --user enable --now cdemu-daemon.service
systemctl --user enable opentabletdriver.service


# Чистка
sudo pacman -Qtdq &&
    sudo pacman -Rns --noconfirm $(/bin/pacman -Qttdq)
# Очистить заархивированный журнал
sudo journalctl --rotate --vacuum-time=0.1

echo -e "\e[1;32m----------Установка системы завершена! Выполните ребут----------\e[0m"
