#!/bin/bash
echo "==> Установка пакетов для окружения i3-wm"
PKGS=(

    # --- XORG

        'xterm'                   # Терминал для TTY
        'xorg-server'             # XOrg сервер
        'xorg-xinit'              # XOrg инициализация
        'xorg-xrandr'             # Менять разрешение
        'xorg-xinput'             # Для работы граф.планшета XP-PEN G640 + OpenTabletDriver
        'xf86-video-amdgpu'       # Открытые драйвера AMDGPU

	# --- i3-wm

        'i3-gaps'
#        'i3-wm'                 # i3wm с недавно добавленными отступами (gaps)
        'polybar'               # Статус бар
        'dmenu'                 # Меню приложений
        'rofi'                  # Меню приложений
        'rofi-emoji'            # Плагин Rofi для выбора смайликов
        'maim'                  # Очень минималистичный скриншотер (хорошо сочетается с xclip)
        'scrot'                 # Необходим для maim
        'lxqt-policykit'        # Супер минималистичный polkit аутентификатор
        'nitrogen'              # Менеджер обоев рабочего стола X Window System
        'dunst'                 # Демон уведомлений
        'pcmanfm-gtk3'          # Графический файловый менеджер (версия GTK3)
        'ffmpegthumbnailer'     # Для отображения миниатюр в pcmanfm
        'galculator'            # GNOME калькулятор
        'file-roller'           # Gnome менеджер архивов
        'feh'                   # Минималистичный просмотрорщик изображений
        'udiskie'               # Автоматическое монторование USB флешек с треем
        'pasystray'             # System tray volume control
        'lxappearance'          # GTK оформления (GTK+ 2 версия)
        'qt5ct'                 # QT оформления
        'screenkey'             # Показывать набранные клавиши
        'xclip'                 # System Clipboard (необходимо для neovim)
        'xsel'                  # Для копирования текста из neovim
        'redshift'     		# Беречь глаза при работе за ПК

	# --- THEMES

        'breeze'                        # Для доступа к тёмной теме kdenlive
        'gtk-engine-murrine'            # Для работоспособности темы Materia Theme
        'materia-gtk-theme'             # Desktop Theme
        'capitaine-cursors'             # Cursor Icons
        'papirus-icon-theme'            # Desktop Icons

	# --- Другое

        'zathura-pdf-mupdf'          # Удобный PDF Reader
        'zathura-djvu'               # Для поддержки формата .djvu
        'zathura-cb'                 # Для поддержки формата .cbz (аниме манга)
        'alacritty'                  # Терминал
        'imwheel'                    # Конфигуратор мышки для X'ов (фиксит скролл chromium based браузеров)
        'lf'                         # Удобный TUI файлоый менеджер
        'ueberzug'                   # Необходим для предпросмотра картинок в LF
        'pulsemixer'                 # TUI PulseAudio volume control
)
sudo pacman -S "${PKGS[@]}" --noconfirm --needed

echo "==> Установка AUR пакетов для окружения i3-wm"
PKGS=(

        'picom-git'             # Прозрачность окон + blur dual_kawase
        'rofi-greenclip'        # Rofi/Dmenu Менеджер буфера обмена с поддержкой картинок
        'rofi-power-menu'       # Меню выключения
        'autotiling'            # Script for sway and i3 to automatically switch the horizontal / vertical window split orientation
        'giph'                  # Gif рекордер (для maim)
        'nsxiv'                 # Простой и удобный просмоторщик картинок
#        'betterlockscreen'     # A simple, minimal lockscreen
)
yay -S "${PKGS[@]}" --noconfirm --needed


echo "==> Включаю AMD Tear Free и VRR"
sudo bash -c 'cat <<EOF > /etc/X11/xorg.conf.d/20-amdgpu.conf
Section "Device"
     Identifier "AMD"
     Driver "amdgpu"
     Option "TearFree" "true"
     Option "VariableRefresh" "true"
     Option "DRI" "3"
EndSection
EOF'

sudo mkinitcpio -P

# Настройка раскладки
if grep -q ruwin_alt_sh-UTF-8 "/etc/vconsole.conf"; then
    # Переключение раскладки по Alt+Shift
    sudo localectl set-x11-keymap --no-convert us,ru pc105 "" grp:alt_shift_toggle
elif
    grep -q ruwin_cplk-UTF-8 "/etc/vconsole.conf"; then
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
