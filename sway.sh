#!/bin/bash
#
echo "==> Установка пакетов для оконного менеджера sway"
yay -S --noconfirm --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/sway | column -t)

# Вытягиваю мои конфиги для sway
pushd ~/.dotfiles/sway
stow -vt ~ */
popd

# Создание пользовательских директорий
mkdir ~/Pictures/Screenshots

# Sway не экспортирует переменные в ~/.config/environment.d/
# Придётся ставить их тут /etc/environment
# Глобальные переменные для окружения Sway
sudo tee -a /etc/environment > /dev/null << EOF

# xdg-desktop-portal override
XDG_CURRENT_DESKTOP=sway

# Для оформления приложений Qt
QT_QPA_PLATFORMTHEME=qt5ct
QT_STYLE_OVERRIDE=kvantum

# Задаёт бэкэнд для seat для доступа к устройствам
# Исправляет: Could not connect to socket /run/seatd.sock: no such file or directory
LIBSEAT_BACKEND=logind

# Использовать бэкэнд Wayland для QT
QT_QPA_PLATFORM=wayland

# Отключить рисовку оформлений окон в старых версиях QT на стороне клиента
QT_WAYLAND_DISABLE_WINDOWDECORATION="1"

# Включает курсор мыши на виртуальных машинах
WLR_NO_HARDWARE_CURSORS=1

# Исправляет отрисовку приложений Java jre8 таких как pycharm
_JAVA_AWT_WM_NONREPARENTING=1
EOF

# Настраиваю sddm на использование протокола wayland
# Исправляет: Failed to bind socket @/tmp/.X11-unix/X0: Address already in use
sudo sed -i "s|DisplayServer=.*|DisplayServer=wayland|g" /usr/lib/sddm/sddm.conf.d/default.conf

# Включаю сервисы
sudo systemctl enable sddm
systemctl --user enable \
	mako.service \
	gammastep.service

