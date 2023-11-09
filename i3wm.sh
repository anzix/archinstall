#!/bin/bash

echo "==> Установка пакетов для оконного менеджера i3"
yay -S --noconfirm --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/i3wm | column -t)

# Вытягиваю мои конфиги для i3-wm
cd ~/.dotfiles/i3wm
stow -vt ~ */

# Переменные для последовательного стиля приложений
sudo tee -a /etc/environment << EOF

# Qt
QT_QPA_PLATFORMTHEME=qt5ct
QT_STYLE_OVERRIDE=kvantum
EOF

if [ "$(systemd-detect-virt)" = "none" ]; then
echo "==> Настройка Xorg для AMDGPU"
sudo bash -c 'cat <<EOF > /etc/X11/xorg.conf.d/20-amdgpu.conf
Section "Device"
     Identifier "AMD"
     Driver "amdgpu"
     Option "TearFree" "false"
     Option "EnablePageFlip" "off"
     Option "VariableRefresh" "true"
EndSection
EOF'
fi

# Настройка раскладки
if grep -q ruwin_alt_sh-UTF-8 "/etc/vconsole.conf"; then
    # Переключение раскладки по Alt+Shift
    sudo localectl set-x11-keymap --no-convert us,ru pc105 "" grp:alt_shift_toggle
elif grep -q ruwin_cplk-UTF-8 "/etc/vconsole.conf"; then
	# Переключение раскладки CapsLock (Чтобы набирать капсом Shift+CapsLock)
    sudo localectl set-x11-keymap --no-convert us,ru pc105 "" grp:caps_toggle,grp_led:caps,grp:switch
fi


echo "==> Отключаю акселерацию мышки"
sudo bash -c 'cat <<EOF > /etc/X11/xorg.conf.d/50-mouse-acceleration.conf
Section "InputClass"
     Identifier "Logitech G102 Prodigy"
     Driver "libinput"
     MatchIsPointer "yes"
     Option "AccelProfile" "Flat"
     Option "AccelSpeed" "0"
EndSection
EOF'

# Включение сервисов
systemctl --user enable \
	redshift.service `# Беречь глаза` \
	greenclip.service `# dmenu менеджер буфера обмена` \
	dunst.service `# Демон уведомлений` \
	cdemu-daemon.service `# Эмуляция iso образов`

