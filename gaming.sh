#!/bin/bash

# Загружаю все дополнительные библиотеки из wine-staging
expac -S '%o' wine-staging >> packages/gaming

echo "==> Установка основных пакетов Pacman"
yay -S --noconfirm --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' packages/gaming)

# Экспорт игровых конфигов
cd ~/dotfiles/base
stow -vt ~ mangohud vkBasalt

# Автозапуск и тихий запуск Steam
mkdir -pv ~/.config/autostart/
ln -svi /usr/share/applications/steam.desktop ~/.config/autostart/
sed -i 's|^Exec=/usr/bin/steam-runtime %U|Exec=/usr/bin/steam-runtime -silent %U|g' ~/.config/autostart/steam.desktop

# Дать возможность gamemode выставлять приоритет процесса игры (renice)
# https://wiki.archlinux.org/title/Gamemode#Renicing
sudo usermod -aG gamemode $(whoami)

# Запуск сервисов
# joycond: Для активации Virtual Pro Controller нажать одновременно - +
# sudo systemctl enable joycond
# sudo systemctl enable --now zerotier-one.service
