#!/bin/bash

# Позаимствовано
# https://github.com/gjpin/arch-linux/blob/main/setup_gnome.sh

echo "==> Установка пакетов для окружения Gnome"
PKGS=(
 'eog' # Просмоторщик изображений
 'evince' # Просмотрщик документов
 'file-roller' # Архивато # Архиваторр
 'gnome-backgrounds'
 'gnome-calculator'
 'gnome-calendar'
 'gnome-color-manager'
 'gnome-console'
 'gnome-control-center'
 'gnome-disk-utility'
 'gnome-font-viewer'
 'gnome-keyring'
 'gnome-music'
 'gnome-session'
 'gnome-settings-daemon'
 'gnome-shell'
 'gnome-shell-extensions'
 'gnome-system-monitor'
 'gnome-text-editor'
# 'gnome-themes-extra' # Экстра темы для Gnome
 'grilo-plugins'
 'mutter'
 'ghex' # Hex редактор
 'gpaste' # Clipboard Manager
 'gvfs-mtp'
 'gvfs-nfs'
 'nautilus' # Файловый менеджер
 'sushi' # Быстрый предварительный просмотрщик для Nautilus
 'totem' # Видеоплеер
 'xdg-user-dirs-gtk'
 'xdg-desktop-portal-gnome'
 'qgnomeplatform-qt5' # Улучшает интеграцию приложений QT
 'qgnomeplatform-qt6' # Улучшает интеграцию приложений QT
 'kvantum' # Движок тем на основе SVG для Qt5/6 (включая инструмент настройки и дополнительные темы)
 'gnome-tweaks' # Экстра настройки Gnome
 'webp-pixbuf-loader' # Поддержка WEBP изображений для eog
 'wl-clipboard' # Wayland clipboard copy+paste
 'gdm' # Дисплей менеджер

 'gnome-shell-extension-appindicator' 'libappindicator-gtk2' 'libappindicator-gtk3' # Устаревшее отображение иконок в трее (gtk2/3)
)
sudo pacman -S "${PKGS[@]}" --noconfirm --needed

echo "==> Установка AUR пакетов для окружения Gnome"
PKGS=(
 'gcdemu' # CDEmu интеграция (эмуляция образов)
 'adw-gtk3' # Adwaita тема для устаревших GTK3 приложений
 'kvantum-theme-libadwaita-git' # LibAdwaita тема для QT 5/6 приложений

# 'gnome-shell-extension-dash-to-dock' # Dock панель
# 'gnome-shell-extension-desktop-icons-ng' # Иконки на рабочем столе
# 'gnome-shell-extension-freon-git' # Отображение CPU/GPU/HDD/SSD температуры
# 'gnome-shell-extension-kimpanel-git' # Реализация KDE kimpanel для GNOME Shell, теперь поддерживает fcitx

)
yay -S "${PKGS[@]}" --noconfirm --needed


# Переменные для последовательного стиля GNOME
tee -a /etc/environment << EOF

# Qt
QT_QPA_PLATFORMTHEME=gnome
QT_STYLE_OVERRIDE=kvantum
XCURSOR_THEME=Adwaita
XCURSOR_SIZE=24
EOF

# Улучшение интеграции приложений QT
sed -i '/QT_QPA_PLATFORMTHEME.*/s/qt5ct/gnome/' ~/.zprofile
# Установка Kvantum для всех Qt программ
sed -i '/QT_STYLE.*/s/^# //g' ~/.zprofile

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
 	gsettings set org.gnome.desktop.input-sources xkb-options "['grp:alt_shift_toggle']"
 	gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Shift>Alt_L', 'XF86Keyboard']"
 	gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Alt>Shift_L', 'XF86Keyboard']"
elif
    grep -q ruwin_cplk-UTF-8 "/etc/vconsole.conf"; then
    # Переключение раскладки CapsLock (Чтобы набирать капсом Shift+CapsLock)
	# Нет надобности в OSD уведомлении при переключении раскладки
	gsettings set org.gnome.desktop.input-sources xkb-options "['grp:caps_toggle']"
	gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"
	gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"
fi

# Создание пользовательского профиля
sudo mkdir -pv /etc/dconf/profile
sudo mkdir -pv /etc/dconf/db/local.d/
sudo tee /etc/dconf/profile/user >/dev/null <<'EOF'
user-db:user
system-db:local
EOF

# Импорт конфигурации Gnome
sudo tee /etc/dconf/db/local.d/01-custom >/dev/null <<'EOF'
[org/gnome/desktop/interface]
gtk-theme='adw-gtk3-dark'
color-scheme='prefer-dark'

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
enabled-extensions=['appindicatorsupport@rgcjonas.gmail.com']

[org/gnome/desktop/peripherals/keyboard]
delay=uint32 210
repeat-interval=uint32 35

[org/gnome/desktop/sound]
allow-volume-above-100-percent=false
event-sounds=false

[org/gtk/settings/file-chooser]
sort-directories-first=true

[org/gnome/nautilus/preferences]
show-create-link=true
always-use-location-entry=true

[org/gnome/mutter]
center-new-windows=true

[org/gnome/nautilus/icon-view]
default-zoom-level='small'

[org/gnome/TextEditor]
show-line-numbers=true
show-map=true

[org/gnome/desktop/input-sources]
sources=[('xkb', 'us'), ('xkb', 'ru')]

[org/gnome/desktop/calendar]
show-weekdate=true

[org/gnome/desktop/peripherals/mouse]
accel-profile='flat'

[org/gnome/desktop/interface]
monospace-font-name='JetBrainsMono Nerd Font Medium 10'

[org/gnome/desktop/interface]
font-name='Noto Sans 10'
document-font-name='Noto Sans 10'
monospace-font-name='Noto Sans Mono 10'

[org/gnome/desktop/wm/preferences]
titlebar-font='Noto Sans Bold 10'

[org/gnome/shell]
disable-user-extensions=false

[org/gnome/desktop/wm/preferences]
button-layout='appmenu:minimize,maximize,close'

[org/gnome/desktop/screensaver]
lock-enabled=false

[org/gnome/desktop/session]
idle-delay=uint32 600

[org/gnome/desktop/interface]
font-antialiasing='rgba'
EOF


# Конфигурации Gnome для конкретных ноутбуков
# https://wiki.archlinux.org/title/Libinput#Touchpad_not_working_in_GNOME
if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then
sudo tee /etc/dconf/db/local.d/01-laptop >/dev/null <<'EOF'
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

# Запуск
sudo systemctl enable gdm.service
