#!/bin/bash

# Позаимствовано
# https://github.com/gjpin/arch-linux/blob/main/setup_plasma.sh

echo "==> Установка пакетов для окружения KDE Plasma"
yay -S --noconfirm --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/plasma | column -t)

# Вытягиваю конфиги для KDE Plasma
pushd ~/.dotfiles/plasma
stow -vt ~ */
popd

# Пользовательские переменные
# SDDM подхватывает настройки от выбранного $SHELL
ln -siv $HOME/.dotfiles/base/zsh/.config/zsh/profile.zsh ~/.zprofile

# Отключает baloo (файловый индекстор)
# Это исправляет медленную работу dolphin при монтировании sshfs
sudo balooctl suspend # Усыпляем работу индексатора
sudo balooctl disable # Отключаем Baloo
sudo balooctl purge # Чистим кэш

# Тёмная тема Plasma
kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezedark.desktop"

# Ставлю тему Breeze для SDDM
sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group Theme --key "Current" "breeze"

# Тёмная тема для SDDM
sudo cp /usr/share/wallpapers/Next/contents/images_dark/1920x1080.png /usr/share/sddm/themes/breeze/
sudo tee /usr/share/sddm/themes/breeze/theme.conf.user >/dev/null <<'EOF'
[General]
background=1920x1080.png
type=image
EOF

# Скорость печатания
kwriteconfig5 --file kcminputrc --group Keyboard --key RepeatDelay "210"
kwriteconfig5 --file kcminputrc --group Keyboard --key RepeatRate "35"

# Моноширинный шрифт для поддержки powerlevel10k в терминале
kwriteconfig5 --file kdeglobals --group General --key fixed 'JetBrainsMonoNL Nerd Font,14,-1,5,50,0,0,0,0,0'
# kwriteconfig5 --file kdeglobals --group General --key fixed 'Насk Nerd Font,14,-1,5,50,0,0,0,0,0'

# Подсвечивать non-default пункты в настройках KDE
kwriteconfig5 --file systemsettingsrc --group systemsettings_sidebar_mode --key "HighlightNonDefaultSettings" "true"

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
elif grep -q ruwin_cplk-UTF-8 "/etc/vconsole.conf"; then
    # Переключение раскладки CapsLock (Чтобы набирать капсом Shift+CapsLock)
    kwriteconfig5 --file kxkbrc --group Layout --key Use --type bool 1
    kwriteconfig5 --file kxkbrc --group Layout --key ResetOldOptions --type bool 1
    kwriteconfig5 --file kxkbrc --group Layout --key DisplayNames ','
    kwriteconfig5 --file kxkbrc --group Layout --key VariantList ','
    kwriteconfig5 --file kxkbrc --group Layout --key LayoutList 'us,ru'
    kwriteconfig5 --file kxkbrc --group Layout --key Options 'grp:caps_toggle'
fi


# Увеличение скорости анимации
kwriteconfig5 --file kdeglobals --group KDE --key AnimationDurationFactor "0.5"

# Предпочитать низкую задержку
kwriteconfig5 --file kwinrc --group Compositing --key "LatencyPolicy" "Low"

# Выставляю мою тему для konsole
kwriteconfig5 --file konsolerc --group Desktop\ Entry --key DefaultProfile "Profile.profile"

# Ночной режим
kwriteconfig5 --file kwinrc --group NightColor --key "Active" "true"
kwriteconfig5 --file kwinrc --group NightColor --key LatitudeAuto 54.799
kwriteconfig5 --file kwinrc --group NightColor --key LongtitudeAuto 55.9053
kwriteconfig5 --file kwinrc --group NightColor --key Mode Location

# Увеличить время простоя энергосбережение монитора DPMS (600 - 10мин, 900 - 15мин)
kwriteconfig5 --file powermanagementprofilesrc --group "AC" --group "DPMSControl" --key "idleTime" "900"
# Отключить энергосбережение монитора DPMS
# kwriteconfig5 --file powermanagementprofilesrc --group "AC" --group "DPMSControl" --key "idleTime" --delete

# Смена оформлений окон
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips --type bool false

# Изменение поведения переключателя задач ALT+TAB
kwriteconfig5 --file kwinrc --group TabBox --key LayoutName "thumbnail_grid"

# Отключает splash screen при включении сессии
kwriteconfig5 --file ksplashrc --group KSplash --key Engine "none"
kwriteconfig5 --file ksplashrc --group KSplash --key Theme "none"

# Отключить обратную связь курсора при запуске приложения
kwriteconfig5 --file klaunchrc --group BusyCursorSettings --key "Bouncing" --type bool false
kwriteconfig5 --file klaunchrc --group FeedbackStyle --key "BusyCursor" --type bool false

# Отключить появление "Обзор" при крае экрана курсора
kwriteconfig5 --file kwinrc --group Effect-windowview --key BorderActivateAll "9"

# Отключить напоминание о установке интеграции plasma в браузере
kwriteconfig5 --file kded5rc --group "Module-browserintegrationreminder"  --key "autoload" "false"

# Комбинация открытия Konsole
kwriteconfig5 --file kglobalshortcutsrc --group org.kde.konsole.desktop --key "_launch" "Meta+Return,none,Konsole"

# Комбинация открытия Spectacle (скриншот выделенной зоны)
# TODO: Убрать когда выйдет Plasma 6 т.к это там будет по дефолту
# FIXME: При выполнении убираются отсальные горячие клавиши такие как Meta+Print для захвата активного окна
# kwriteconfig5 --file kglobalshortcutsrc --group "org.kde.spectacle.desktop" --key "RectangularRegionScreenShot" "Meta+Shift+S,none,Capture Rectangular Region"

# Комбинация режима "Обзор"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Overview" "Meta+Tab,none,Toggle Overview"

# Комбинация закрытия окна
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Shift+Q,none,Close Window"

# Перезагрузка plasmashell
kwriteconfig5 --file kglobalshortcutsrc --group "plasmashell.desktop" --key "_k_friendly_name" "plasmashell --replace"
kwriteconfig5 --file kglobalshortcutsrc --group "plasmashell.desktop" --key "_launch" "Ctrl+Alt+Del,none,plasmashell --replace"

# Включает 2 рабочих стола
kwriteconfig5 --file kwinrc --group Desktops --key Name_2 "Рабочий стол 2"
kwriteconfig5 --file kwinrc --group Desktops --key Number "2"
kwriteconfig5 --file kwinrc --group Desktops --key Rows "1"

# Горячие клавиши рабочего стола
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
