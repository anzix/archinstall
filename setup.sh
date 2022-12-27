#!/bin/bash

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

    # --- Graphics driver
        
        'mesa'                    # Open source version of OpenGL
        'libva-mesa-driver'       # VA-API драйвер
        'lib32-libva-mesa-driver' # VA-API драйвер (32bit)
        'mesa-vdpau'              # VDPAU Драйвер
        'lib32-mesa-vdpau'        # VDPAU Драйвер (32bit)
        'glu'                     # Библеотеки утилит Mesa OpenGL (необходимо для запуска Goverlay)
        'vulkan-tools'            # Инструменты vulkan (vulkaninfo)
        'vulkan-radeon'           # Реализация vulkan драйвера от Mesa
        'lib32-vulkan-radeon'     # Реализация vulkan драйвера от Mesa (32bit)

        'vulkan-mesa-layers'
        'lib32-vulkan-mesa-layers'
        
        'libva-vdpau-driver'        # A VDPAU-based backend for VA-API
        'lib32-libva-vdpau-driver'  # A VDPAU-based backend for VA-API (32bit)
        'libvdpau-va-gl'            # VDPAU driver with OpenGL/VAAPI backend. H.264 only

    # --- AUDIO [3 Варианта]
        
        # 1) Pipewire

        'pipewire'
	'lib32-pipewire'
        'wireplumber'       # Modular session / policy manager for PipeWire
        'pipewire-pulse'
        'pipewire-alsa'
        'pipewire-v4l2'     # Для правильной работы вебки в OBS
        'jack2'
	'lib32-jack2'
        'jack2-dbus'        # Для dbus интеграции
        'gst-plugin-pipewire'

        # 2) PulseAudio

#        'pulseaudio'        # PulseAudio sound components
#        'pulseaudio-alsa'   # ALSA configuration for pulse audio

        # 3) Только Alsa

#        'alsa'
#        'alsa-firmware'
#        'alsa-card-profiles'

    # --- AUDIO Other

        'mpd'               # Музыкальный сервер для музыки к которому можно конектится
        'mpc'               # Контроллер управления музыкой через терминал
        'ncmpcpp'           # TUI музыкальный плеер
        'playerctl'         # Для работы fn+f6/7/8 и других приколюх
        'mediainfo'         # Информация о медиа
        'alsa-utils'        # Advanced Linux Sound Architecture (Чтобы убрать через alsamixer прослушивание себя через микро)
        'alsa-tools'        # Advanced tools for certain sound cards
	'alsa-plugins'      # ALSA plugins
        'pavucontrol'       # GTK PulseAudio volume control

        'gstreamer'
        'gst-libav'
        'gst-plugins-base'
        'gst-plugins-good'
        'gst-plugins-bad'   # Библеотеки для воспроизведения мультимедия (для запуска старья)
        'gst-plugins-ugly'  # Библеотеки для воспроизведения мультимедия (для запуска старья)
        'lib32-gst-plugins-good'
        'gstreamer-vaapi'   # Эффективный плагин кодировщик для RDNA1 AMDGPU (для использования нужен AUR пакет obs-gstreamer)

    # --- BLUETOOTH

        'bluez'                 # Daemons for the bluetooth protocol stack
        'bluez-utils'           # Bluetooth development and debugging utilities. Содержит bluetoothctl
        'blueman'               # Bluetooth менеджер

    # --- GAMING and EMULATION

        'steam'
        'lutris'                # GUI обвёртка Wine
        'wine-staging'
        'wine-gecko'
        'wine-mono'
        'winetricks'            # Протаскивать библиотеки/dll'ки в префикс
        'gamemode'              # +FPS для игр
        'lib32-gamemode'
#        'pcsx2'                 # PS2 Эмулятор
#        'dolphin-emu'           # Gamecube Эмулятор

    # --- UTILITIES

        'stow'                       # Manager sim-link а также для менеджмента dotfiles
        'pacman-contrib'             # Скрипты и инструменты для Pacman
        'rebuild-detector'           # Показывает лист AUR пакетов которые были собраны на старых версиях зависимостей, для их дальнейшей пересборки
        'reflector'                  # Инструмент для зеркал Pacman
        'rsync'                      # Необходимо для reflector
        'radeontop'                  # Мониторинг AMD GPU        
        'xdg-utils'                  # Command line tools that assist applications with a variety of desktop integration tasks
        'htop'                       # Простой консольный диспетчер задач
        'btop'                       # TUI Диспетчер задач
        'neofetch'                   # Чтобы выпендриватся
        'man-db'                     # Мануалы
        'man-pages'                  # Мануалы
        'exfat-utils'                # Поддержка файловой системы exFAT (Для sd-карт)
        'ntfs-3g'                    # Поддержка файловой системы NTFS (Для Windows)
        'e2fsprogs'                  # Поддержка файловой системы ext4
        'dosfstools'                 # Поддержка файловой системы vFAT
        'f2fs-tools'                 # Поддержка файловой системы f2fs
        'gvfs-mtp'                   # MTP backend; Android, media player
        'gvfs'                       # Подсистема среды рабочего стола GNOME (является trashcan для фм pcmanfm)
        'wget'                       # Для скачивания файлов
        'unzip'                      # Архивирование и распаковка файлов zip
        'unrar'                      # Архивирование и распаковка файлов rar
        'p7zip'                      # Архивирование и распаковка файлов 7z
        'yarn'                       # Для neovim плагина https://github.com/iamcco/markdown-preview.nvim
        'yt-dlp'                     # Качать видосики с ютуба
        'ffmpeg'                     # Конвертер/Декодер/Рекордер видео
        'python-mutagen'             # Для вывода обложки трека в уведомлении mpd (дополнение к mpDris2)
        'smartmontools'              # Для информации и проверки состояния здоровья HDD и SSD
        'fd'                         # Поиск файлов
        'ripgrep'                    # Более быстрая альтернатива grep (необходимо для telescope плагин nvim)
        'exa'                        # Замена ls
        'pkgfile'                    # Для плагина zsh "command-not-found"
        'libva-utils'                # Проверка VA-API дравера командой (vainfo)
        'vdpauinfo'                  # Проверка VDPAU драйвера командой (vdpauinfo)
        'net-tools'                  # Для прослушивания портов командой
        'hwinfo'                     # Системная информация
        'nmap'                       # Утилита для исследования сети и сканер портов
        'ncdu'                       # TUI анализатор свободного места
        'zbar'                       # Сканер QR кодов (для maim)
        'tesseract'                  # OCR сканер
        'tesseract-data-rus'
        'tesseract-data-eng'
        'tesseract-data-jpn'
        'jq'                         # (Необходимо для mpv-webtorrent-hook)
        'testdisk'                   # Востановления данных
        'aspell-ru'                  # Русский словарь для проверки орфографии (работает только с UTF8 кодировкой)
        'atool'                      # Для предпросмотра архивов через lf
        'noise-suppression-for-voice' # (Для pipewire) Плагин подавления шума микрофона в реальном времени в OBS
        'flashrom'                    # Для прошивания чипов программатором ch341a
        'dfu-util'                    # Для обновления прошивки паяльника Pinecil первой версии
        'hexedit'                     # TUI HEX-редактор
        'scrcpy'                      # Демонстрация экрана Android для Linux используя USB ADB
        'translate-shell'             # Переводчик в терминале (необходим для скриптов)
        'bat'                         # Замена cat
        'tor'
        'torsocks'
        'i2pd'
#        'system-config-printer'       # Менеджер принтеров
#        'cups'                        # Модульная система печати для принтеров
#        'cups-pdf'                    # Поддержка печати PDF файлов
        'cdemu-client'                # Эмуляция iso образов
        'transmission-cli'            # Для замены passkey в торрент файлах и многое другое
        'mame-tools'                  # Конвертирование .iso / .cue образов PS2 игр в сжатый .chd образ (chdman)
        'jre-openjdk'                 # Для работы Minecraft
        'jre-openjdk-headless' 
        'java-runtime-common'
        'lib32-sdl2'                  # Для работы steamcmd
        'lib32-dbus'                  # Для работы steamcmd
        'virt-manager'                # Менеджер виртуальных машин
        'qemu'                        # Виртуализация
        'qemu-emulators-full'         # Поддержка всех архитектур для виртуализации
        'dnsmasq' 
        'nftables' 
        'iptables-nft'
        'dmidecode' 
        'edk2-ovmf'		      # Поддержка UEFI для QEMU
        'swtpm'			      # Поддержка TPM для QEMU

    # --- FONTS

        'terminus-font'                 # Позволяет выбрать более крупный шрифт для небольших экранов HiDPI
        'ttf-hack-nerd'                 # Шрифты для иконок в терминале
        'ttf-sourcecodepro-nerd'        # Шрифты для иконок в терминале
        'ttf-roboto'                    # Шрифты Google
        'ttf-font-awesome'              # Для появления значков (Из https://fontawesome.com/v5/cheatsheet) из тем и i3 статус баром появляться
        'ttf-opensans'                  # Шрифты для Телеграмма
        'ttf-droid'                     # Android'ский шрифт не имеющий нуля с прорезью, поэтому 0 и O не различимы
        'ttf-liberation'                # Начальный набор шрифтов 
        'ttf-dejavu'                    # Начальный набор шрифтов 
        'adobe-source-han-sans-jp-fonts' # Японские шрифты
#        'noto-fonts-cjk'                # Набор Азиатских шрифтов, много весят
        'noto-fonts-emoji'              # Смайлы в терминал     
#       'noto-fonts'                     # (Захламляет кучу других шрифтов, весит 100мб) Без него всё текста тёмные в i3status

    # --- APPS

        'firefox'                        # Браузер
        'firefox-i18n-ru'                # Руссификация Firefox
#        'libreoffice-fresh'              # Документы
#        'libreoffice-fresh-ru'           # Руссификация LibreOffice
        'obs-studio'                     # Запись и трансляции
        'mpv'                            # Лучший видеопроигрыватель
        'songrec'                        # Shazam но для Linux
        'keepassxc'                      # Локально пароли
        'qbittorrent'                    # Торрент клиент
        'bleachbit'                      # Чистильщик для Linux
        'gimp'
#        'audacity'
        'kdenlive'
        'corectrl'                       # GUI управление GPU/CPU
#        'piper'                          # Настройка мышки Logitech
#        'discord'                        # Chat for gamers
        'telegram-desktop'
)
sudo pacman -S "${PKGS[@]}" --noconfirm --needed


echo "==> Установка AUR пакетов"
PKGS=(

    # --- DESKTOP RELATED

        'ungoogled-chromium-bin'  # Chromium но без Google
#        'czkawka-gui-bin'         # Удобный инструмент для удаления дубликатов
        'opentabletdriver'        # Драйвер для граф. планшета XP-PEN G640
        'webtorrent-cli'          # Просмотр онлайн торренты (Необходимо для mpv-webtorrent-hook) 
        'xidel'                   # (Необходимо для mpv-webtorrent-hook)
        'inxi'                    # Системная информация PC
        'obfs4proxy'              # Обфускация трафика тор
        'ventoy-bin'              # Создание загрузочной флешки для WIN/Linux образов
        'obs-gstreamer'           # Более эффективный плагин кодировщик для OBS
        'obs-vkcapture'           # OBS плагин для захвата напрямую через API OpenGL/Vulkan (минимизирует затраты)
        'lib32-obs-vkcapture'
        'amd-vulkan-prefixes'     # Быстрое переключение icd драйверов AMD используя переменные (RADV: vk_radv, AMDVLK: vk_amdvlk, AMDGPU-PRO: vk_pro)
#        'cpu-x'                   # CPU-Z для Linux
#        'android-apktool'         # Для декомпиляции apk файлов

    # --- GAMING

#        'lgogdownloader'            # CLI обвёртка GOG (не работает login)
#        'lgogdownloader-qt5'        # CLI обвёртка GOG (рабочий login)
        'heroic-games-launcher-bin' # Удобный EGS / GOG лаунчер для Linux
#        'tlauncher'                # Legacy TL Minecraft лаунчер 
        'dxvk-bin'                  # Свежий dxvk для ручных префиксов wine
        'protonup-qt'               # Удобная утилитка для скачки runner'ов wine
#        'goverlay-bin'              # GUI настройка оверлей mangohud
        'mangohud'                  # Мониторинг для игр
        'lib32-mangohud'
        'vkbasalt'                  # Постпроцессинг для игр
        'lib32-vkbasalt'
        'game-devices-udev'         # Udev правила для работы контроллеров в Steam
#        'rpcs3-bin'                 # PS3 Эмулятор
#        'cemu-git'                  # Wii U Эмулятор
#        'hid-nintendo-dkms'         # Драйвер для правильной работы геймпада 8BitDo Pro 2 режиме Switch в эмуляторах и играх
        'joycond-git'               # Альтернатива BetterJoy
        'joycond-cemuhook-git'      # Для подключания геймпада 8BitDo Pro 2 по DSU для работы гироскопа
#        'flashplayer-standalone'    # Запуск локальных .swf (Flash) файлов

    # --- FONTS

        'nerd-fonts-jetbrains-mono' # Шрифт для коректной работы иконок в exa и p10k

    # --- UTILITIES

        'mpdris2'               # Чтобы работал playerctl для mpd (+ вывод обложки в уведомлении)

    # --- THEMES
    # --- OTHER

        'man-pages-ru'                  # Russian Linux man pages
        'chromium-widevine'             # Плагин для работы DRM контента в браузере ungoogled-chromium
#        'kyocera-print-driver'          # Драйвер для Kyocera FS-1060DN

)
yay -S "${PKGS[@]}" --noconfirm --needed



# Corectrl без запроса пароля root
sudo bash -c 'cat <<EOF > /etc/polkit-1/rules.d/90-corectrl.rules
polkit.addRule(function(action, subject) {
	if ((action.id == "org.corectrl.helper.init" ||
     	action.id == "org.corectrl.helperkiller.init") &&
    	subject.local == true &&
    	subject.active == true &&
    	subject.isInGroup("wheel")) {
           return polkit.Result.YES;
	}
});
EOF'


echo "==> Установка моего dotfiles"
cd ~
git clone --recurse-submodules https://gitlab.com/anzix/dotfiles.git
cd dotfiles/base
# Вытягиваю только zsh конфиг
stow -vt ~ zsh
ln -siv $HOME/dotfiles/base/zsh/.config/zsh/profile.zsh ~/.zprofile


# Настройка Firefox
cd ~/dotfiles
chmod +x firefox_setup
./firefox_setup


mkdir -p ~/Pictures/{Screenshots/mpv,Gif}
mkdir -p ~/Documents/Backup
mkdir ~/.config/mpd/playlists

# Для функции "aurstore" в ~/.config/zsh/aliases.zsh
sudo pacman -Fy


# Для работы OpenTabletDriver граф. планшета Xp-Pen G640
echo "blacklist hid_uclogic" | sudo tee -a /etc/modprobe.d/blacklist.conf >/dev/null
sudo rmmod hid_uclogic
sudo mkinitcpio -P


echo "==> Окрашиваю GTK тему к root приложениям"
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
echo "\nUUID=F46C28716C2830B2         /media/Distrib    ntfs-3g        rw,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0       0" | sudo tee -a /etc/fstab >/dev/null
echo "UUID=CA8C4EB58C4E9BB7       /media/Other    ntfs-3g        rw,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0       0" | sudo tee -a /etc/fstab >/dev/null
echo "UUID=A81C9E2F1C9DF890    /media/Media    ntfs-3g        rw,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0       0" | sudo tee -a /etc/fstab >/dev/null
echo "UUID=30C4C35EC4C32546          /media/Games    ntfs-3g        rw,noatime,prealloc,fmask=0022,dmask=0022,uid=1000,gid=984,windows_names   0       0" | sudo tee -a /etc/fstab >/dev/null


# Настройка libvirt/QEMU/KVM для виртуализции win10/11
sudo sed -i 's/^#unix_sock_group/unix_sock_group/' /etc/libvirt/libvirtd.conf
sudo sed -i 's/^#unix_sock_rw_perms/unix_sock_rw_perms/' /etc/libvirt/libvirtd.conf
sudo sed -i "s|^#user = .*|user = \"${USERNAME}\"|g" /etc/libvirt/qemu.conf
sudo sed -i "s|^#group = .*|group = \"wheel\"|g" /etc/libvirt/qemu.conf
sudo usermod -aG libvirt,kvm $(whoami)
# Убираю конфликтующие строки с hosts для правильной работы dnsmasq
sudo sed -i '/fe80::1%lo0 localhost/d;/0.0.0.0 27--01bbcpolice.powercoremedia.com/d;/0.0.0.0 www.27--01bbcpolice.powercoremedia.com/d' /etc/hosts
# Запускаем сервис
sudo systemctl enable --now libvirtd
# Автозапуск вирт. сети [default] при запуске системы 
sudo virsh net-autostart default
# Включить [default] вирт. сеть
sudo virsh net-start default



# Install and configure desktop environment
if [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
    curl -O https://raw.githubusercontent.com/anzix/scriptinstall/main/plasma_setup.sh
    chmod +x plasma_install.sh
    ./plasma_install.sh
elif [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
    curl -O https://raw.githubusercontent.com/anzix/scriptinstall/main/gnome_setup.sh
    chmod +x gnome_install.sh
    ./gnome_install.sh
elif [ ${DESKTOP_ENVIRONMENT} = "i3wm" ]; then
    curl -O https://raw.githubusercontent.com/anzix/scriptinstall/main/i3_setup.sh
    chmod +x i3wm_install.sh
    ./i3wm_install.sh
fi

# Обнаружение фс
if grep -q ext4 "/etc/fstab"; then
  yay -S timeshift-bin --noconfirm --needed
elif
  grep -q btrfs "/etc/fstab"; then
  yay -S snapper snap-pac grub-btrfs snp snapper-gui-git --noconfirm --needed
  
  # Unmount .snapshots
  sudo umount -v /.snapshots
  sudo rm -rfv /.snapshots

  # Create Snapper config
  sudo snapper -c root create-config /

  # Delete Snapper's .snapshots subvolume
  sudo btrfs subvolume delete /.snapshots

  # Re-create and re-mount /.snapshots mount
  sudo mkdir -v /.snapshots
  sudo mount -v -a

  # Change default subvolume
  sudo btrfs subvol lis /
  sudo btrfs subvol get-def /
  sudo btrfs subvol set-def 256 / # Make sure it is @
  sudo btrfs subvol get-def /

  # Access for non-root users
  sudo chown :wheel /.snapshots

  # Configure Snapper
  # Позволять группе wheel использовать snapper ls non-root пользователю
  sudo sed -i "s|^ALLOW_GROUPS=.*|ALLOW_GROUPS=\"wheel\"|g" /etc/snapper/configs/root
  sudo sed -i "s|^TIMELINE_LIMIT_HOURLY=.*|TIMELINE_LIMIT_HOURLY=\"3\"|g" /etc/snapper/configs/root
  sudo sed -i "s|^TIMELINE_LIMIT_DAILY=.*|TIMELINE_LIMIT_DAILY=\"6\"|g" /etc/snapper/configs/root
  sudo sed -i "s|^TIMELINE_LIMIT_WEEKLY=.*|TIMELINE_LIMIT_WEEKLY=\"0\"|g" /etc/snapper/configs/root
  sudo sed -i "s|^TIMELINE_LIMIT_MONTHLY=.*|TIMELINE_LIMIT_MONTHLY=\"0\"|g" /etc/snapper/configs/root
  sudo sed -i "s|^TIMELINE_LIMIT_YEARLY=.*|TIMELINE_LIMIT_YEARLY=\"0\"|g" /etc/snapper/configs/root

  # Enable Snapper services
  sudo systemctl enable snapper-timeline.timer
  sudo systemctl enable snapper-cleanup.timer

  # Enable GRUB-BTRFS service
  sudo systemctl enable grub-btrfs.path

  # Configure initramfs to boot into snapshots using overlayfs (read-only mode)
  sudo sed -i "s|keymap)|keymap grub-btrfs-overlayfs)|g" /etc/mkinitcpio.conf

  # Пересоздаём initramfs
  sudo mkinitcpio -P
fi

# Устранение ошибки
# No Sound or pactl info shows Failure: Connection refused
if ! command -v pipewire &> /dev/null
then
    systemctl --user enable pipewire-pulse.service
    exit
fi


echo -e "\e[1;32m----------Установка системы завершена! Выполните ребут----------\e[0m"
