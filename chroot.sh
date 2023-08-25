#!/bin/bash

# Руссифицируемся
sed -i "s/#\(en_US\.UTF-8\)/\1/; s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen
locale-gen
tee /etc/locale.conf > /dev/null << EOF
LANG=ru_RU.UTF-8
LC_COLLATE=C
EOF

# Смена раскладки клавиатуры в tty
# TODO: ru-mab — кодировка UTF-8 переключение на Ctrl+Shift
if [ "${XKB_LAYOUT}" = 'Alt+Shift' ]; then
  echo "KEYMAP=ruwin_alt_sh-UTF-8" > /etc/vconsole.conf
elif [ "${XKB_LAYOUT}" = 'Caps Lock' ]; then
  echo "KEYMAP=ruwin_cplk-UTF-8" > /etc/vconsole.conf
fi
echo "FONT=ter-v22b" >> /etc/vconsole.conf

# Часовой пояс и апаратные часы
ln -sf /usr/share/zoneinfo/"${time_zone}" /etc/localtime
hwclock --systohc # Эта команда предполагает, что аппаратные часы настроены в формате UTC.

# Имя хоста
echo "${HOST_NAME}" > /etc/hostname
tee /etc/hosts > /dev/null << EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOST_NAME.localdomain $HOST_NAME
EOF

# Настройка граф. планшета Xp-Pen G640 для работы OpenTabletDriver
tee -a /etc/modprobe.d/blacklist.conf > /dev/null << EOF
blacklist hid_uclogic
EOF

# Отключение системного звукового сигнала
tee -a /etc/modprobe.d/nobeep.conf > /dev/null << EOF
blacklist pcspkr
EOF

# Установка универсального host файла от StevenBlack (убирает рекламу и вредоносы из WEB'а)
# Обновление host файла выполняется командой: $ uphosts
wget -qO- https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts \
 | grep '^0\.0\.0\.0' \
 | grep -v '^0\.0\.0\.0 [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$' \
 | sed '1s/^/\n/' \
 | tee --append /etc/hosts >/dev/null

# Пароль root пользователя
echo "root:${USER_PASSWORD}" | chpasswd

# Инициализировать связку ключей Pacman
pacman-key --init
pacman-key --populate archlinux

# Добавления юзера и присваивание групп к юзеру
useradd -m -G wheel,audio,video,input,optical,users,uucp,games -s /bin/zsh "${USER_NAME}"

# Пароль пользователя
echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd

# Привелегии sudo
if [ "${SUDO_PRIV}" = 'y' ]; then
  # Привилегии sudo с запросом пароля
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL\.*/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
elif [ "${SUDO_PRIV}" = 'n' ]; then
  # Привилегии sudo без запроса пароля
  sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL\.*/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
fi

# Создание пользовательских XDG директорий
# Используются английские названия для простоты работы с терминала
LC_ALL=C sudo -u "${USER_NAME}" xdg-user-dirs-update --force

# Настройка pacman
sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Делаем pacman красивее
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Добавляем цвета в pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 8/g" /etc/pacman.conf  # Увеличение паралельных загрузок с 5 на 8
sed -i "s/#VerbosePkgLists/VerbosePkgLists/g" /etc/pacman.conf # Более удобный просмотр лист пакетов
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf # Включение multilib репо для запуска 32bit приложений

# Оптимизация makepkg
sed -i -e 's|CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt -fexceptions|CFLAGS="-march=native -mtune=native -O2 -pipe -fno-plt -fexceptions|g' \
 -i -e 's|#MAKEFLAGS=.*|MAKEFLAGS="-j$(expr $(nproc) - 1)"|' \
 -i -e 's|#RUSTFLAGS=.*|RUSTFLAGS="-C opt-level=2 -C target-cpu=native"|' \
 -i -e 's|^BUILDENV.*|BUILDENV=(!distcc color ccache check !sign)|g' \
 -i -e 's|#BUILDDIR.*|BUILDDIR=/tmp/makepkg|g' \
 -i -e 's|xz.*|xz -c -z -q - --threads=$(nproc))|;s|^#COMPRESSXZ|COMPRESSXZ|' \
 -i -e 's|zstd.*|zstd -c -z -q - --threads=$(nproc))|;s|^#COMPRESSZST|COMPRESSZST|' \
 -i -e 's|lz4.*|lz4 -q --best)|;s|^#COMPRESSLZ4|COMPRESSLZ4|' \
 -i -e "s|PKGEXT.*|PKGEXT='.pkg.tar.lz4'|g" /etc/makepkg.conf



# Синхронизация базы пакетов
pacman -Syy

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
 'alsa-utils' # Утилиты ALSA, в числе которых alsamixer
 'noise-suppression-for-voice' # (Pipewire only) Плагин подавления шума микрофона в реальном времени

 'gstreamer'
 'gst-libav'
 'gst-plugins-base' 'lib32-gst-plugins-base'
 'gst-plugins-good' 'lib32-gst-plugins-good'
 'gst-plugins-bad' # Библеотеки для воспроизведения мультимедия (для запуска старья)
 'gst-plugins-ugly' # Библеотеки для воспроизведения мультимедия (для запуска старья)
 'gstreamer-vaapi' # Эффективный плагин кодировщик для RDNA1 AMDGPU (для использования нужен AUR пакет obs-gstreamer)

# --- СЕТЬ

 'networkmanager'  # Менеджер сети
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

 'git' # Система управление версиями
 'openssh' # SSH соединение
 'neovim' # Текстовый редактор
 'stow' # Менеджер sim-link'ов (для менеджмента dotfiles)
 'pacman-contrib' # Скрипты и инструменты для Pacman
 'expac' # Утилита извлечения данных alpm (базы данных pacman)
 'rebuild-detector' # Показывает лист AUR пакетов которые были собраны на старых версиях зависимостей, для их дальнейшей пересборки
 'archlinux-wallpaper' # Arch Linux обои
 'reflector' # Инструмент для оптимизации зеркал Pacman
 'zram-generator' # Подкачка
 'rsync' # Быстрый и универсальный инструмент для копирования удаленных и локальных файлов
 'wget' # Для скачивания файлов
 'plocate' # Более быстрая альтернатива locate
 'dbus-broker' # Оптимизированная система шины сообщений
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
 'e2fsprogs' # Поддержка файловой системы ext4
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
 'iptables-nft' # Средство управления сетью пакетами данных ядра Linux используя интерфейс nft
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

 'terminus-font' # Шрифты разных размеров с кириллицей для tty
 'ttf-jetbrains-mono-nerd' # Шрифты для иконок в терминале
 'ttf-font-awesome' # Для появления монотонных значков и иконок
 'ttf-opensans' # Шрифт для Телеграмма
 'ttf-droid' # Android'ский шрифт не имеющий нуля с прорезью, поэтому 0 и O не различимы
 'ttf-liberation' # Начальный набор шрифтов
 'ttf-dejavu' # Начальный набор шрифтов
 'noto-fonts-cjk' # Набор Азиатских шрифтов, много весят
 'noto-fonts-emoji' # Смайлы в терминал
 'noto-fonts' # Необходимые шрифты, разные иероглифы и т.д

# --- ПРОГРАММЫ

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
 # sudo -u ${USER_NAME} systemctl enable vboxservice.service
fi

pacman -S "${PKGS[@]}" --noconfirm --needed

# Установка Yay (AUR помощник)
git clone https://aur.archlinux.org/yay-bin.git
chown -v -R ${USER_NAME}:${USER_NAME} yay-bin
cd yay-bin
sudo -u ${USER_NAME} makepkg -si --noconfirm
cd ..
rm -rf yay-bin

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

# Настройка snapper и btrfs в случае обнаружения
if [ "${FS}" = 'btrfs' ]; then

  # Unmount .snapshots
  umount -v /.snapshots
  rm -rfv /.snapshots

  # Create Snapper config
  snapper --no-dbus -c root create-config /

  # Информация о размере снапшота btrfs
  #btrfs quota enable /

  # Удаляем подтом .snapshots Snapper'а
  btrfs subvolume delete /.snapshots

  # Пересоздаём и переподключаем /.snapshots
  mkdir -v /.snapshots
  mount -v -a

  # Меняем права доступа для легкой замены снимка @ в любое время без потери снимков snapper.
  chmod -v 750 /.snapshots

  # Доступ к снимкам для non-root пользователям
  chown -R :wheel /.snapshots

  # Настройка Snapper
  # Позволять группе wheel использовать snapper ls non-root пользователю
  # Установка лимата снимков
  sed -i "s|^ALLOW_GROUPS=.*|ALLOW_GROUPS=\"wheel\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_HOURLY=.*|TIMELINE_LIMIT_HOURLY=\"3\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_DAILY=.*|TIMELINE_LIMIT_DAILY=\"6\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_WEEKLY=.*|TIMELINE_LIMIT_WEEKLY=\"0\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_MONTHLY=.*|TIMELINE_LIMIT_MONTHLY=\"0\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_YEARLY=.*|TIMELINE_LIMIT_YEARLY=\"0\"|g" /etc/snapper/configs/root

  # Включение Snapper сервисов
  sudo -u ${USER_NAME} systemctl enable \
	  snapper-timeline.timer \
      snapper-cleanup.timer

  # Btrfs твики
  sudo -u ${USER_NAME} systemctl enable \
	  btrfs-scrub@home.timer \
      btrfs-scrub@-.timer

  # Пропускать снапшоты для locate (Предотвращает замедление моментальных снимков)
  sed -i '/^PRUNENAMES/s/"\(.*\)"/"\1 .snapshots"/' /etc/updatedb.conf

  # Правка mkinitcpio.conf
  sed -i 's/^MODULES.*/MODULES=(btrfs amdgpu)/' /etc/mkinitcpio.conf

  # Add the btrfs binary in order to do maintenence on system without mounting it
  sed -i 's/^BINARIES=.*$/BINARIES=(btrfs)/' /etc/mkinitcpio.conf
  sed -i "s/^HOOKS.*/HOOKS=(base consolefont udev autodetect modconf block filesystems keyboard keymap)/g" /etc/mkinitcpio.conf

else
  sed -i 's/^MODULES.*/MODULES=(amdgpu)/' /etc/mkinitcpio.conf
  sed -i "s/^HOOKS.*/HOOKS=(base consolefont udev autodetect modconf block filesystems keyboard keymap fsck)/g" /etc/mkinitcpio.conf
fi
mkinitcpio -P

# Правка конфига reflector
sed -i "s/^--protocol.*/--protocol http,https/" /etc/xdg/reflector/reflector.conf
sed -i "s/# --country.*/--country ru,by/" /etc/xdg/reflector/reflector.conf
sed -i "s/^--latest.*/--latest 12/" /etc/xdg/reflector/reflector.conf
sed -i "s/^--sort.*/--sort rate/" /etc/xdg/reflector/reflector.conf

mkdir /etc/pacman.d/hooks

# Создаю Reflector хук
tee /etc/pacman.d/hooks/mirrorupgrade.hook > /dev/null << EOF
[Trigger]
Operation = Upgrade
Type = Package
Target = pacman-mirrorlist

[Action]
Description = Updating pacman-mirrorlist with reflector and removing pacnew...
When = PostTransaction
Depends = reflector
Exec = /bin/sh -c "systemctl start reflector.service; if [ -f /etc/pacman.d/mirrorlist.pacnew ]; then rm /etc/pacman.d/mirrorlist.pacnew; fi"
EOF

# Чистка кэша Pacman хук
tee /etc/pacman.d/hooks/clean_package_cache.hook > /dev/null << EOF
[Trigger]
Type = Package
Operation = Upgrade
Operation = Install
Operation = Remove
Target = *

[Action]
Description = Очистка устаревших кэшированных пакетов (с сохранением двух последних)...
When = PostTransaction
Exec = /usr/bin/paccache -rk2
EOF

# Хук GRUB обновления (для стабильности)
tee /etc/pacman.d/hooks/92-grub-upgrade.hook > /dev/null << EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = grub

[Action]
Description = Upgrading GRUB...
When = PostTransaction
Exec = /usr/bin/sh -c "grub-install --efi-directory=/boot/efi; grub-mkconfig -o /boot/grub/grub.cfg"
EOF

# Хук для предотвращения создания Wine ассоциации файлов
tee /etc/pacman.d/hooks/stop-wine-associations.hook > /dev/null << EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Path
Target = usr/share/wine/wine.inf

[Action]
Description = Остановливаю Wine от перехвата ассоциаций файлов...
When = PostTransaction
Exec = /bin/sh -c '/usr/bin/grep -q "HKCU,\"Software\\\Wine\\\FileOpenAssociations\",\"Enable\",2,\"N\"" /usr/share/wine/wine.inf || /usr/bin/sed -i "s/\[Services\]/\[Services\]\nHKCU,\"Software\\\Wine\\\FileOpenAssociations\",\"Enable\",2,\"N\"/g" /usr/share/wine/wine.inf'
EOF

# Размер Zram
tee /etc/systemd/zram-generator.conf > /dev/null << EOF
[zram0]
zram-size = min(min(ram, 4096) + max(ram - 4096, 0) / 2, 32 * 1024)
compression-algorithm = zstd
EOF

if [ "$(systemd-detect-virt)" = "none" ]; then
# Sysctl оптимизации
# https://ventureo.codeberg.page/source/generic-system-acceleration.html#swap
# https://wiki.archlinux.org/title/Sysctl#Improving_performance

tee /etc/sysctl.d/99-sysctl.conf > /dev/null << EOF
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# Исправляет различные проблемы связанные с играми используя SteamPlay (Proton)
vm.max_map_count=1048576

# Увеличение длины очереди входящих пакетов.
# После получения пакетов из кольцевого буфера сетевой карты они помещаются в специальную очередь в ядре.
# При использовании высокоскоростных сетевых карт увеличение размера очереди может помочь предотвратить потерю пакетов:
net.core.netdev_max_backlog = 16384

# Увеличение максимального числа ожидающих соединений
# Максимальное число входящих соединений, ожидающих приёма (accept) программой, на одном сокете: (default 4096):
net.core.somaxconn = 8192

# Скрывает любые сообщения ядра с консоли.
kernel.printk = 3 3 3 3

# TCP Fast Open — это расширение протокола управления передачей (TCP), которое помогает уменьшить задержки в сети,
# позволяя начать передачу данных сразу при отправке клиентом первого TCP SYN [3].
# Значение 3 вместо стандартного 1 включит TCP Fast Open как для входящих, так и для исходящих соединений:
net.ipv4.tcp_fastopen = 3

# Включение BBR
# Алгоритм управления перегрузками BBR может помочь достичь более высокой пропускной способности и более низких задержек для интернет-трафика.
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr

# Защита от tcp time-wait assassination hazards, отбрасывание RST-пакетов для сокетов в состоянии time-wait.
# За пределами Linux поддерживается не очень широко, но соответствует RFC:
net.ipv4.tcp_rfc1337 = 1

# При включении reverse path filtering ядро будет проверять источник пакетов, полученных со всех интерфейсов машины.
# Это может защитить от злоумышленников, которые используют методы подмены IP-адресов для нанесения вреда.
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1

# Отключение перенаправлений ICMP
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# To use the new FQ-PIE Queue Discipline (>= Linux 5.6) in systems with systemd (>= 217), will need to replace the default fq_codel.
net.core.default_qdisc = fq_pie
EOF

# Экспорт fancontrol конфиг для управления вертиляторов (только AMD RX580)
tee /etc/fancontrol > /dev/null << EOF
# Configuration file generated by pwmconfig, changes will be lost
INTERVAL=5
DEVPATH=hwmon0=devices/pci0000:00/0000:00:03.0/0000:03:00.0
DEVNAME=hwmon0=amdgpu
FCTEMPS=hwmon0/pwm1=hwmon0/temp1_input
FCFANS= hwmon0/pwm1=
MINTEMP=hwmon0/pwm1=30
MAXTEMP=hwmon0/pwm1=79
MINSTART=hwmon0/pwm1=150
MINSTOP=hwmon0/pwm1=75
EOF
fi

# Добавление глобальных переменных системы
tee -a /etc/environment << EOF

# Принудительно включаю icd RADV драйвер (если установлен)
AMD_VULKAN_ICD=RADV
EOF

# Добавления моих опций ядра grub
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 mitigations=off pcie_aspm=off intel_iommu=on iommu=pt audit=0 nowatchdog amdgpu.ppfeaturemask=0xffffffff cpufreq.default_governor=performance intel_pstate=passive zswap.enabled=0"/g' /etc/default/grub

# Установка и настройка Grub
#sed -i -e 's/#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /etc/default/grub # Обнаруживать другие ОС и добавлять их в grub (нужен пакет os-prober)
grub-install --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg


# Врубаю сервисы
# joycond: Для активации Virtual Pro Controller нажать одновременно - +
sudo -u ${USER_NAME} systemctl enable \
 NetworkManager.service \
 sshd.service \
 fstrim.timer \
 plocate-updatedb.timer \
 systemd-oomd.service \
 dbus-broker.service \
 fancontrol.service \
 grub-btrfsd \
 bluetooth.service \
 joycond

sudo -u ${USER_NAME} systemctl --user enable \
 mpd-mpris \
 mpd \
 opentabletdriver.service
# cdemu-daemon.service
