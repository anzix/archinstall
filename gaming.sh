#!/bin/bash

# Загружаю wine-staging и все дополнительные библиотеки
sudo pacman -S --needed --noconfirm $(expac -S '%o' wine-staging) wine-staging winetricks wine-mono wine-gecko

echo "==> Установка основных пакетов Pacman"
yay -S --noconfirm --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/gaming | column -t)

# Вытягиваю игровые конфиги и файлы
pushd ~/.dotfiles/gaming
stow -vt ~ */
popd

# INFO: иконки которые были вытянуты из dotfiles можно добавить в autostart
# сунув их в ~/.config/autostart/. Поддерживает GNOME и KDE Plasma

# Дать возможность gamemode выставлять приоритет процесса игры (renice)
# https://wiki.archlinux.org/title/Gamemode#Renicing
sudo usermod -aG gamemode $(whoami)

# Запуск сервисов
# joycond: Для активации Virtual Pro Controller нажать одновременно - +
# sudo systemctl enable joycond
# sudo systemctl enable --now zerotier-one.service
