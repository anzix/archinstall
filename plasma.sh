#!/bin/bash

# Позаимствовано
# https://github.com/gjpin/arch-linux/blob/main/setup_plasma.sh

echo "==> Установка пакетов для окружения KDE Plasma"
yay -S --noconfirm --needed $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/plasma | column -t)

# # Тёмная тема Plasma
# kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezedark.desktop"
#
# # Ставлю тему Breeze для SDDM
# sudo kwriteconfig6 --file /etc/sddm.conf.d/kde_settings.conf --group Theme --key "Current" "breeze"
#
# # Тёмная тема для SDDM
# sudo cp /usr/share/wallpapers/Next/contents/images_dark/1920x1080.png /usr/share/sddm/themes/breeze/
# sudo tee /usr/share/sddm/themes/breeze/theme.conf.user >/dev/null <<'EOF'
# [General]
# background=1920x1080.png
# type=image
# EOF
#
# # Скорость печатания
# kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatDelay "210"
# kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatRate "35"
#
# # Моноширинный шрифт для поддержки powerlevel10k в терминале
# kwriteconfig6 --file kdeglobals --group General --key fixed 'JetBrainsMonoNL Nerd Font,14,-1,5,50,0,0,0,0,0'
# # kwriteconfig6 --file kdeglobals --group General --key fixed 'Насk Nerd Font,14,-1,5,50,0,0,0,0,0'
#
# # Подсвечивать non-default пункты в настройках KDE
# kwriteconfig6 --file systemsettingsrc --group systemsettings_sidebar_mode --key "HighlightNonDefaultSettings" "true"
#
# # Отключает одиночный клик для открытия файлов/папок
# # В Plasma 6 это действие по умолчанию
# kwriteconfig6 --file kdeglobals --group KDE --key SingleClick --type bool false

# Настройка раскладки
# if grep -q ruwin_alt_sh-UTF-8 "/etc/vconsole.conf"; then
#     # Переключение раскладки по Alt+Shift
#     kwriteconfig6 --file kxkbrc --group Layout --key Use --type bool 1
#     kwriteconfig6 --file kxkbrc --group Layout --key ResetOldOptions --type bool 1
#     kwriteconfig6 --file kxkbrc --group Layout --key DisplayNames ','
#     kwriteconfig6 --file kxkbrc --group Layout --key VariantList ','
#     kwriteconfig6 --file kxkbrc --group Layout --key LayoutList 'us,ru'
#     kwriteconfig6 --file kxkbrc --group Layout --key Options 'grp:alt_shift_toggle'
# elif grep -q ruwin_cplk-UTF-8 "/etc/vconsole.conf"; then
#     # Переключение раскладки CapsLock (Чтобы набирать капсом Shift+CapsLock)
#     kwriteconfig6 --file kxkbrc --group Layout --key Use --type bool 1
#     kwriteconfig6 --file kxkbrc --group Layout --key ResetOldOptions --type bool 1
#     kwriteconfig6 --file kxkbrc --group Layout --key DisplayNames ','
#     kwriteconfig6 --file kxkbrc --group Layout --key VariantList ','
#     kwriteconfig6 --file kxkbrc --group Layout --key LayoutList 'us,ru'
#     kwriteconfig6 --file kxkbrc --group Layout --key Options 'grp:caps_toggle'
# fi


# Увеличение скорости анимации
# kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor "0.5"

# Предпочитать низкую задержку
# kwriteconfig6 --file kwinrc --group Compositing --key "LatencyPolicy" "Low"

# Увеличить время простоя энергосбережение монитора DPMS (600 - 10мин, 900 - 15мин)
# kwriteconfig6 --file powermanagementprofilesrc --group "AC" --group "DPMSControl" --key "idleTime" "900"
# Отключить энергосбережение монитора DPMS
# kwriteconfig6 --file powermanagementprofilesrc --group "AC" --group "DPMSControl" --key "idleTime" --delete

# Смена оформлений окон
# kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
# kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
# kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips --type bool false

# Изменение поведения переключателя задач ALT+TAB
# kwriteconfig6 --file kwinrc --group TabBox --key LayoutName "thumbnail_grid"

# Отключает splash screen при включении сессии
# kwriteconfig6 --file ksplashrc --group KSplash --key Engine "none"
# kwriteconfig6 --file ksplashrc --group KSplash --key Theme "none"
#
# Отключить обратную связь курсора при запуске приложения
# kwriteconfig6 --file klaunchrc --group BusyCursorSettings --key "Bouncing" --type bool false
# kwriteconfig6 --file klaunchrc --group FeedbackStyle --key "BusyCursor" --type bool false

# Отключить появление "Обзор" при крае экрана курсора
# kwriteconfig6 --file kwinrc --group Effect-windowview --key BorderActivateAll "9"

# Отключить напоминание о установке интеграции plasma в браузере
# kwriteconfig6 --file kded5rc --group "Module-browserintegrationreminder"  --key "autoload" "false"

# Комбинация открытия Konsole
# kwriteconfig6 --file kglobalshortcutsrc --group org.kde.konsole.desktop --key "_launch" "Meta+Return,none,Konsole"

# TODO: Убрать для бинда по умолчанию Meta+w
# Комбинация режима "Обзор"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Overview" "Meta+Tab,none,Toggle Overview"

# Комбинация закрытия окна
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Shift+Q,none,Close Window"

# Перезагрузка plasmashell
# kwriteconfig6 --file kglobalshortcutsrc --group "plasmashell.desktop" --key "_k_friendly_name" "plasmashell --replace"
# kwriteconfig6 --file kglobalshortcutsrc --group "plasmashell.desktop" --key "_launch" "Ctrl+Alt+Del,none,plasmashell --replace"
#
# Включает 2 рабочих стола
# kwriteconfig6 --file kwinrc --group Desktops --key Name_2 "Рабочий стол 2"
# kwriteconfig6 --file kwinrc --group Desktops --key Number "2"
# kwriteconfig6 --file kwinrc --group Desktops --key Rows "1"

# Горячие клавиши рабочего стола
# kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 1" "none,none,Activate Task Manager Entry 1"
# kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 2" "none,none,Activate Task Manager Entry 2"
# kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 3" "none,none,Activate Task Manager Entry 3"
# kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 4" "none,none,Activate Task Manager Entry 4"
# kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 5" "none,none,Activate Task Manager Entry 5"
# kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 6" "none,none,Activate Task Manager Entry 6"
# kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 7" "none,none,Activate Task Manager Entry 7"
# kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 8" "none,none,Activate Task Manager Entry 8"
# kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 9" "none,none,Activate Task Manager Entry 9"
# kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 10" "none,none,Activate Task Manager Entry 10"
#
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 1" "Meta+1,none,Switch to Desktop 1"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 2" "Meta+2,none,Switch to Desktop 2"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 3" "Meta+3,none,Switch to Desktop 3"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 4" "Meta+4,none,Switch to Desktop 4"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 5" "Meta+5,none,Switch to Desktop 5"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 6" "Meta+6,none,Switch to Desktop 6"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 7" "Meta+7,none,Switch to Desktop 7"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 8" "Meta+8,none,Switch to Desktop 8"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 9" "Meta+9,none,Switch to Desktop 9"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 10" "Meta+0,none,Switch to Desktop 10"
#
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 1" "Meta+\!,none,Window to Desktop 1"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 2" "Meta+@,none,Window to Desktop 2"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 3" "Meta+#,none,Window to Desktop 3"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 4" "Meta+$,none,Window to Desktop 4"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 5" "Meta+%,none,Window to Desktop 5"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 6" "Meta+^,none,Window to Desktop 6"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 7" "Meta+&,none,Window to Desktop 7"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 8" "Meta+*,none,Window to Desktop 8"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 9" "Meta+(,none,Window to Desktop 9"
# kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 10" "Meta+),none,Window to Desktop 10"

# Запуск
sudo systemctl enable sddm.service
