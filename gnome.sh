#!/bin/bash

# Позаимствовано
# https://github.com/gjpin/arch-linux/blob/main/setup_gnome.sh

echo "==> Установка пакетов для окружения Gnome"
yay -S --noconfirm --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/gnome | column -t)

# Вытягиваю конфиги для GNOME
pushd ~/.dotfiles/gnome
stow -vt ~ */
popd

# Установка KvLibadwaitaDark в качестве темы для QT 5/6 приложений
mkdir -v ~/.config/Kvantum
echo 'theme=KvLibadwaitaDark' > ~/.config/Kvantum/kvantum.kvconfig

# Создаю шаблоны для использования из под контекстное меню проводника Gnome Файлы
touch $(xdg-user-dir TEMPLATES)/Новый\ файл
tee $(xdg-user-dir TEMPLATES)/Пустой\ Bash\ файл > /dev/null << EOF
#!/bin/bash
EOF
tee $(xdg-user-dir TEMPLATES)/Пустой\ ярлык > /dev/null << EOF
[Desktop Entry]
Name=
Comment=
Keywords=
Exec=
TryExec=
Terminal=false
Icon=
Type=
Categories=
MimeType=
StartupNotify=false
StartupWMClass=
OnlyShowIn=
Actions=
EOF


# Смена раскладки языка
if grep -q ruwin_alt_sh-UTF-8 "/etc/vconsole.conf"; then
# Переключение раскладки Alt+Shift
dconf load / << EOF
[org/gnome/desktop/input-sources]
xkb-options=['grp:alt_shift_toggle']
[org/gnome/desktop/wm/keybindings]
switch-input-source=['<Shift>Alt_L', 'XF86Keyboard']
switch-input-source-backward=['<Alt>Shift_L', 'XF86Keyboard']
EOF
elif grep -q ruwin_cplk-UTF-8 "/etc/vconsole.conf"; then
# Переключение раскладки CapsLock (Чтобы набирать капсом Shift+CapsLock)
# Нет надобности в OSD уведомлении при переключении раскладки
dconf load / << EOF
[org/gnome/desktop/input-sources]
xkb-options=['grp:caps_toggle']
[org/gnome/desktop/wm/keybindings]
switch-input-source=@as []
switch-input-source-backward=@as []
EOF
fi

# # Создание пользовательского профиля
# sudo mkdir -pv /etc/dconf/profile
# sudo mkdir -pv /etc/dconf/db/local.d/
# sudo tee /etc/dconf/profile/user >/dev/null <<'EOF'
# user-db:user
# system-db:local
# EOF

# Импорт конфигурации Gnome
dconf load / << EOF
[org/gnome/desktop/wm/keybindings]
close=['<Shift><Super>q']
switch-applications=@as []
switch-applications-backward=@as []
switch-windows=['<Alt>Tab']
switch-windows-backward=['<Shift><Alt>Tab']
switch-to-workspace-1=['<Super>1']
switch-to-workspace-2=['<Super>2']
switch-to-workspace-3=['<Super>3']
switch-to-workspace-4=['<Super>4']
move-to-workspace-1=['<Shift><Super>exclam']
move-to-workspace-2=['<Shift><Super>at']
move-to-workspace-3=['<Shift><Super>numbersign']
move-to-workspace-4=['<Shift><Super>dollar']

[org/gnome/shell/keybindings]
show-screenshot-ui=['<Shift><Super>s']
switch-to-application-1=@as []
switch-to-application-2=@as []
switch-to-application-3=@as []
switch-to-application-4=@as []

[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
binding='<Super>Return'
command='kgx'
name='Gnome Console'
[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1]
binding='<Super>E'
command='nautilus'
name='Nautilus'
[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2]
binding='<Shift><Control>Escape'
command='gnome-system-monitor'
name='Gnome System Monitor'

[org/gnome/shell]
disable-user-extensions=false
enabled-extensions=['appindicatorsupport@rgcjonas.gmail.com']

[org/gnome/desktop/peripherals/keyboard]
delay=uint32 210
repeat-interval=uint32 35

[org/gnome/Console]
custom-font='JetBrainsMonoNL Nerd Font 11'
font-scale=1.3000000000000003
use-system-font=false

[org/gnome/desktop/sound]
allow-volume-above-100-percent=false
event-sounds=false

[org/gtk/settings/file-chooser]
sort-directories-first=true
sort-column='name'
sort-order='ascending'

[org/gnome/nautilus/preferences]
show-create-link=true

[org/gnome/mutter]
center-new-windows=true

[org/gnome/nautilus/icon-view]
default-zoom-level='small-plus'

[org/gnome/TextEditor]
show-line-numbers=true
show-map=true
spellcheck=false

[org/gnome/desktop/input-sources]
sources=[('xkb', 'us'), ('xkb', 'ru')]

[org/gnome/desktop/calendar]
show-weekdate=true

[org/gnome/desktop/peripherals/mouse]
accel-profile='flat'

[org/gnome/desktop/interface]
color-scheme='prefer-dark'
enable-hot-corners=false
font-antialiasing='rgba'
gtk-theme='adw-gtk3-dark'
font-name='Noto Sans 10'
document-font-name='Noto Sans 10'
monospace-font-name='Noto Sans Mono 10'

[org/gnome/desktop/wm/preferences]
titlebar-font='Noto Sans Bold 10'

[org/gnome/desktop/screensaver]
lock-enabled=false

[org/gnome/desktop/session]
idle-delay=uint32 600
EOF


# Конфигурации Gnome для конкретных ноутбуков
# https://wiki.archlinux.org/title/Libinput#Touchpad_not_working_in_GNOME
if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then
dconf load / << EOF
[org/gnome/desktop/peripherals/touchpad]
tap-to-click=true
disable-while-typing=false

[org/gnome/desktop/interface]
show-battery-percentage=true
EOF
fi

# Обновление системных баз данных Gnome
sudo dconf update

# Запуск расширений
gnome-extensions enable GPaste@gnome-shell-extensions.gnome.org
gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com

# Запуск
sudo systemctl enable gdm.service
