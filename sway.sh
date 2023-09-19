#!/bin/bash
#
echo "==> Установка пакетов для оконного менеджера sway"
yay -S --noconfirm --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' packages/sway)

# Вытягиваю мои конфиги для sway
cd dotfiles/sway
stow -vt ~ */

# Включаю сервисы
sudo systemctl enable sddm

