#!/bin/bash

echo "==> Установка пакетов для окружения KDE Plasma"
PKGS=(
    'plasma-desktop'
    'bluedevil'
    'kinfocenter'
    'kscreen'
    'kwallet-pam'
    'kwayland-integration'
    'plasma-disks'
    'plasma-nm'
    'plasma-pa'
    'plasma-systemmonitor'
    'plasma-vault' # Plasma applet and services for creating encrypted vaults
    'plasma-workspace-wallpapers'
    'powerdevil'
    'xdg-desktop-portal'
    'xdg-desktop-portal-kde'
    'konsole'
    'kate'
    'dolphin'
    'ark'
    'plasma-wayland-session'
    'kwalletmanager'
    'spectacle'
    'okular'
    'gwenview'
    'plasma-browser-integration'
    'kdeplasma-addons'
    'plasma-firewall'
    'kdeconnect' # Управление Linux со смарта
    'sshfs' # Для доступа к ФС Android через kdeconnect
    'libappindicator-gtk3'

    'sddm'
    'sddm-kcm' # KDE Config Module for SDDM

    'plasma5-applets-window-buttons' # Апплет смены раскладки клавиатуры
    'breeze-gtk' # Improve integration of GTK applications
    'kde-gtk-config' # GTK2 and GTK3 Configurator for KDE
)
sudo pacman -S "${PKGS[@]}" --noconfirm --needed


echo "==> Установка AUR пакетов для окружения KDE Plasma"
PKGS=(

    'kde-cdemu-manager' # CDEmu интеграция (эмуляция образов)
)
yay -S "${PKGS[@]}" --noconfirm --needed


# Отключает baloo (файловый индекстор)
sudo balooctl suspend # Усыпляем работу индексатора
sudo balooctl disable # Отключаем Baloo
sudo balooctl purge # Чистим кэш


for FIREFOX_PROFILE_PATH in /home/${NEW_USER}/.mozilla/firefox/*.default*
do
# Install Firefox's Plasma Integration extension
curl https://addons.mozilla.org/firefox/downloads/file/3859385/plasma_integration-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/plasma-browser-integration@kde.org.xpi

# Import Firefox' user configurations
tee -a ${FIREFOX_PROFILE_PATH}/user.js << EOF
// Использовать KDE Plasma file picker
user_pref("widget.use-xdg-desktop-portal.mime-handler", 1);
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);

// Предотвращает дублирование записей в виджете медиаплеера KDE Plasma
user_pref("media.hardwaremediakeys.enabled", false);
EOF
done


# Скорость печатания
kwriteconfig5 --file kcminputrc --group Keyboard --key RepeatDelay "210"
kwriteconfig5 --file kcminputrc --group Keyboard --key RepeatRate "35"

# Отключает одиночный клик для открытия файлов/папок
kwriteconfig5 --file kdeglobals --group KDE --key SingleClick --type bool false


# Настройка раскладки
if grep -q ruwin_alt_sh-UTF-8 "/etc/vconsole.conf"; then
    # Переключение раскладки по Alt+Shift
    kwriteconfig5 --file kxkbrc --group Layout --key Use --type bool 1
    kwriteconfig5 --file kxkbrc --group Layout --key ResetOldOptions --type bool 1
    kwriteconfig5 --file kxkbrc --group Layout --key DisplayNames ','
    kwriteconfig5 --file kxkbrc --group Layout --key VariantList ','
    kwriteconfig5 --file kxkbrc --group Layout --key LayoutList 'us,ru'
    kwriteconfig5 --file kxkbrc --group Layout --key Options 'grp:alt_shift_toggle'
elif
    grep -q ruwin_cplk-UTF-8 "/etc/vconsole.conf"; then
    # Переключение раскладки CapsLock (Чтобы набирать капсом Shift+CapsLock)
    kwriteconfig5 --file kxkbrc --group Layout --key Use --type bool 1
    kwriteconfig5 --file kxkbrc --group Layout --key ResetOldOptions --type bool 1
    kwriteconfig5 --file kxkbrc --group Layout --key DisplayNames ','
    kwriteconfig5 --file kxkbrc --group Layout --key VariantList ','
    kwriteconfig5 --file kxkbrc --group Layout --key LayoutList 'us,ru'
    kwriteconfig5 --file kxkbrc --group Layout --key Options 'grp:caps_toggle'
fi

# Ставит тему Breeze для SDDM
sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group Theme --key "Current" "breeze"

# Тёмная тема Plasma
kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezedark.desktop"

# Увеличение скорости анимации
kwriteconfig5 --file kdeglobals --group KDE --key AnimationDurationFactor "0.5"

# Change window decorations
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips --type bool false

# Change Task Switcher behaviour
kwriteconfig5 --file kwinrc --group TabBox --key LayoutName "thumbnail_grid"

# Отключает splash screen при включении сессии
kwriteconfig5 --file ksplashrc --group KSplash --key Engine "none"
kwriteconfig5 --file ksplashrc --group KSplash --key Theme "none"

# Disable app launch feedback
kwriteconfig5 --file klaunchrc --group BusyCursorSettings --key "Bouncing" --type bool false
kwriteconfig5 --file klaunchrc --group FeedbackStyle --key "BusyCursor" --type bool false

# Configure screen edges
kwriteconfig5 --file kwinrc --group Effect-overview --key BorderActivate "7"
kwriteconfig5 --file kwinrc --group Effect-windowview --key BorderActivateAll "9"

# Konsole shortcut
kwriteconfig5 --file kglobalshortcutsrc --group org.kde.konsole.desktop --key "_launch" "Meta+Return,none,Konsole"

# Spectacle shortcut
kwriteconfig5 --file kglobalshortcutsrc --group "org.kde.spectacle.desktop" --key "RectangularRegionScreenShot" "Meta+Shift+S,none,Capture Rectangular Region"

# Overview shortcut
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Overview" "Meta+Tab,none,Toggle Overview"

# Close windows shortcut
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Shift+Q,none,Close Window"

# Включает 2 рабочих стола
kwriteconfig5 --file kwinrc --group Desktops --key Name_2 "Desktop 2"
kwriteconfig5 --file kwinrc --group Desktops --key Number "2"
kwriteconfig5 --file kwinrc --group Desktops --key Rows "1"

# Desktop shortcuts
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 1" "none,none,Activate Task Manager Entry 1"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 2" "none,none,Activate Task Manager Entry 2"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 3" "none,none,Activate Task Manager Entry 3"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 4" "none,none,Activate Task Manager Entry 4"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 5" "none,none,Activate Task Manager Entry 5"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 6" "none,none,Activate Task Manager Entry 6"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 7" "none,none,Activate Task Manager Entry 7"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 8" "none,none,Activate Task Manager Entry 8"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 9" "none,none,Activate Task Manager Entry 9"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 10" "none,none,Activate Task Manager Entry 10"

kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 1" "Meta+1,none,Switch to Desktop 1"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 2" "Meta+2,none,Switch to Desktop 2"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 3" "Meta+3,none,Switch to Desktop 3"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 4" "Meta+4,none,Switch to Desktop 4"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 5" "Meta+5,none,Switch to Desktop 5"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 6" "Meta+6,none,Switch to Desktop 6"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 7" "Meta+7,none,Switch to Desktop 7"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 8" "Meta+8,none,Switch to Desktop 8"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 9" "Meta+9,none,Switch to Desktop 9"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 10" "Meta+0,none,Switch to Desktop 10"

kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 1" "Meta+\!,none,Window to Desktop 1"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 2" "Meta+@,none,Window to Desktop 2"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 3" "Meta+#,none,Window to Desktop 3"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 4" "Meta+$,none,Window to Desktop 4"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 5" "Meta+%,none,Window to Desktop 5"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 6" "Meta+^,none,Window to Desktop 6"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 7" "Meta+&,none,Window to Desktop 7"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 8" "Meta+*,none,Window to Desktop 8"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 9" "Meta+(,none,Window to Desktop 9"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 10" "Meta+),none,Window to Desktop 10"

# Запуск
sudo systemctl enable sddm.service