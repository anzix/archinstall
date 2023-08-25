#!/bin/bash
echo "==> Установка основных пакетов Pacman"
PKGS=(

# --- Основные пакеты, библиотеки wine и эмуляторы

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

# --- Игровые утилиты

 'mame-tools' # Конвертирование .iso / .cue образов PS2 игр в сжатый .chd образ (chdman)
)

# Загружаю все дополнительные библиотеки из wine-staging и дополняю список PKGS
PKGS+=($(expac -S '%o' wine-staging))

# Установка
sudo pacman -S "${PKGS[@]}" --noconfirm --needed

echo "==> Установка AUR пакетов"
PKGS=(

# 'lgogdownloader-qt5' # CLI обвёртка GOG (с рабочим логином)
 'heroic-games-launcher-bin' # Удобный EGS / GOG лаунчер для Linux
# 'legacylauncher' # Minecraft лаунчер
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
)
yay -S "${PKGS[@]}" --noconfirm --needed


# Экспорт игровых конфигов
cd ~
cd dotfiles/base
stow -vt ~ mangohud vkBasalt

# Дать возможность gamemode выставлять приоритет процесса игры (renice)
# https://wiki.archlinux.org/title/Gamemode#Renicing
sudo usermod -aG gamemode $(whoami)

# Запуск сервисов
#sudo systemctl enable --now zerotier-one.service
