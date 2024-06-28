#!/bin/bash

# Загружаю wine-staging и все дополнительные библиотеки
sudo pacman -S --needed --noconfirm $(expac -S '%o' wine-staging) wine-staging winetricks wine-mono wine-gecko

echo "==> Установка основных пакетов Pacman"
yay -S --noconfirm --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/gaming | column -t)

# Экспорт игровых конфигов
# cd ~/.dotfiles/base
# stow -vt ~ mangohud vkBasalt

# Автозапуск и тихий запуск Steam
# INFO: при первом запуске steam сразу добавляется в autostart
mkdir -pv ~/.config/autostart/
ln -svi /usr/share/applications/steam.desktop ~/.config/autostart/
sed -i 's|^Exec=/usr/bin/steam-runtime %U|Exec=/usr/bin/steam-runtime -silent %U|g' ~/.config/autostart/steam.desktop

# Автозапуск Discord
ln -svi /usr/share/applications/discord.desktop ~/.config/autostart/
sed -i 's|^Exec=/usr/bin/discord|Exec=/usr/bin/discord --start-minimized|g' ~/.config/autostart/discord.desktop

# Дать возможность gamemode выставлять приоритет процесса игры (renice)
# https://wiki.archlinux.org/title/Gamemode#Renicing
sudo usermod -aG gamemode $(whoami)

# Запуск сервисов
# joycond: Для активации Virtual Pro Controller нажать одновременно - +
# sudo systemctl enable joycond
# sudo systemctl enable --now zerotier-one.service
