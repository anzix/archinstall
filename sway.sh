#!/bin/bash
echo "==> Установка пакетов для окружения sway"
PKGS=(
# --- sway и относящиеся пакеты

 'gammastep' # Redshift форк для sway
 'otf-font-awesome' # Шрифты для waybar и swappy
 'mako' # Уведомления
 'libnotify'
 'seatd'
 'swappy' # Редактирование скриншотов
 'sway' # Основной пакет
 'swaybg' # Ставить обои
 'slurp' # Эквивалентно maim
 'grim' # Скриншот утилита
 'waybar' # Бар
 'wf-recorder' # Запись экрана
 'wl-clipboard' # Поддержка буффера обмена
 'qt5-wayland'
 'wofi' # Менеджер приложений
 'polkit-gnome'
 'file-roller' # Gnome менеджер архивов
 'pcmanfm-qt' # Графический файловый менеджер (версия QT)
 'ffmpegthumbnailer' # Для отображения миниатюр в pcmanfm
 'wayland'
 'xdg-desktop-portal-wlr'
 'xorg-xwayland'

 'galculator' # GNOME калькулятор

 'udiskie' # Автоматическое монторование USB флешек с треем
 'qt5ct' # QT оформления
 'blueman' # Bluetooth менеджер

 'sddm' # Дисплей менеджер

# --- THEMES

 'breeze' # Для доступа к тёмной теме kdenlive
 'gtk-engine-murrine' # Для работоспособности темы Materia Theme
 'materia-gtk-theme' # Desktop Theme
 'capitaine-cursors' # Cursor Icons
 'papirus-icon-theme' # Desktop Icons

# --- Другое

 'zathura-pdf-mupdf' # Удобный PDF Reader
 'zathura-djvu' # Для поддержки формата .djvu
 'zathura-cb' # Для поддержки формата .cbz (аниме манга)
 'alacritty' # Терминал
 'lf' # TUI файлоый менеджер
 'ueberzug' # Необходим для предпросмотра картинок в LF
 'pavucontrol' # GTK Регулятор громкости PulseAudio
 'network-manager-applet' # Аплет NetworkManager
)
sudo pacman -S "${PKGS[@]}" --noconfirm --needed

echo "==> Установка AUR пакетов для окружения i3-wm"
PKGS=(
 'cliphist' # Менеджер буфера обмена для sway
 'wshowkeys-git' # Показ клавиш для sway
 'autotiling' # Script for sway and i3 to automatically switch the horizontal / vertical window split orientation
# 'polkit-dumb-agent-git' # Супер минималистичный polkit аутентификатор
)
yay -S "${PKGS[@]}" --noconfirm --needed

# Вытягиваю мои конфиги для sway
cd dotfiles/sway
stow -vt ~ */

# Включаю сервисы
sudo systemctl enable --now sddm

