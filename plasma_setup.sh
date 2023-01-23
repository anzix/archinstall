#!/bin/bash

# Позаимствовано
# https://github.com/gjpin/arch-linux/blob/main/setup_plasma.sh

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
    'ffmpegthumbs' # Предпросмотрщик видео для проводника dolphin
    'kdialog' # GUI диалоги
    'ark'
    'kcalc'
    'plasma-wayland-session'
    'kwalletmanager'
    'spectacle'
    'okular'
    'gwenview'
    'partitionmanager' # Менеджер дисков KDE
    'plasma-browser-integration'
    'kdeplasma-addons'
    'plasma-firewall'
#    'kdeconnect' # Управление Linux с Android
    'sshfs'
    'libappindicator-gtk2' # Для правильного отображения иконок в трее
    'libappindicator-gtk3' # Для правильного отображения иконок в трее
    'wl-clipboard' # Wayland clipboard copy+paste

    'sddm'
    'sddm-kcm' # KDE Config Module for SDDM

    'plasma5-applets-window-buttons' # Апплет смены раскладки клавиатуры
    'breeze-gtk' # Improve integration of GTK applications
    'kde-gtk-config' # GTK2 and GTK3 Configurator for KDE
)
sudo pacman -S "${PKGS[@]}" --noconfirm --needed


echo "==> Установка AUR пакетов для окружения KDE Plasma"
PKGS=(

#    'kde-cdemu-manager' # CDEmu интеграция (эмуляция образов)
)
yay -S "${PKGS[@]}" --noconfirm --needed


# Отключает baloo (файловый индекстор)
sudo balooctl suspend # Усыпляем работу индексатора
sudo balooctl disable # Отключаем Baloo
sudo balooctl purge # Чистим кэш


for FIREFOX_PROFILE_PATH in $HOME/.mozilla/firefox/*.default*
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

# Dolphin Root доступ
echo '[Desktop Entry]
X-KDE-ServiceTypes=KonqPopupMenu/Plugin
X-KDE-Priority=TopLevel
Type=Service
MimeType=all/all
Actions=EditFromRoot
Icon=folder-red

[Desktop Action EditFromRoot]
Name=Edit from root
Name[ru]=Dolphin-Root
Icon=folder-red
Exec=pkexec env DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" KDE_SESSION_VERSION=5 KDE_FULL_SESSION=true dbus-launch dolphin' | sudo tee -a /usr/share/kservices5/ServiceMenus/Dolphin-Root.desktop >/dev/null

# Автозапуск
mkdir -pv ~/.config/autostart/
cd /usr/share/applications/
sudo ln -svi steam.desktop \
             radeon-profile.desktop ~/.config/autostart/
# Тихий запуск Steam
sudo sed -i 's|^Exec=/usr/bin/steam-runtime %U|Exec=/usr/bin/steam-runtime -silent %U|g' /usr/share/applications/steam.desktop

cd ~

# Скорость печатания
kwriteconfig5 --file kcminputrc --group Keyboard --key RepeatDelay "210"
kwriteconfig5 --file kcminputrc --group Keyboard --key RepeatRate "35"

# Шрифты (Не применяются, лучше вводить вручную)
# Моноширинный (терминал) для поддержки powerlevel10k
# kwriteconfig5 --file kdeglobals --group General --key fixed "Насk Nerd Font,14,-1,5,50,0,0,0,0,0"

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

# Тёмная тема для SDDM
sudo cp /usr/share/wallpapers/Next/contents/images_dark/1920x1080.png /usr/share/sddm/themes/breeze/
echo "[General]
background=1920x1080.png
type=image " | sudo tee -a /usr/share/sddm/themes/breeze/theme.conf.user >/dev/null

# Тёмная тема Plasma
kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezedark.desktop"

# Увеличение скорости анимации
kwriteconfig5 --file kdeglobals --group KDE --key AnimationDurationFactor "0.5"

# Ночной режим
kwriteconfig5 --file kwinrc --group NightColor --key "Active" "true"
kwriteconfig5 --file kwinrc --group NightColor --key LatitudeAuto 54.799
kwriteconfig5 --file kwinrc --group NightColor --key LongtitudeAuto 55.9053
kwriteconfig5 --file kwinrc --group NightColor --key Mode Location

# Увеличить время простоя энергосбережение монитора DPMS (600 - 10мин, 900 - 15мин)
kwriteconfig5 --file powermanagementprofilesrc --group "AC" --group "DPMSControl" --key "idleTime" "900"
# Отключить энергосбережение монитора DPMS
# kwriteconfig5 --file powermanagementprofilesrc --group "AC" --group "DPMSControl" --key "idleTime" --delete

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
