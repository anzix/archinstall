#!/bin/bash

# раскомментируйте, чтобы просмотреть информацию об отладке
#set -xe

# Руссифицируемся
sed -i "s/#\(en_US\.UTF-8\)/\1/; s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen
locale-gen
tee /etc/locale.conf > /dev/null << EOF
LANG=ru_RU.UTF-8
LC_COLLATE=C
EOF

# Смена раскладки клавиатуры в tty
# TODO: ru-mab — кодировка UTF-8 переключение на Ctrl+Shift
if [ "${XKB_LAYOUT}" = 'Alt+Shift' ]; then
  echo "KEYMAP=ruwin_alt_sh-UTF-8" > /etc/vconsole.conf
elif [ "${XKB_LAYOUT}" = 'Caps Lock' ]; then
  echo "KEYMAP=ruwin_cplk-UTF-8" > /etc/vconsole.conf
fi
echo "FONT=ter-v22b" >> /etc/vconsole.conf

# Часовой пояс и апаратные часы
ln -sf /usr/share/zoneinfo/"${time_zone}" /etc/localtime
hwclock --systohc # Эта команда предполагает, что аппаратные часы настроены в формате UTC.

# Имя хоста
echo "${HOST_NAME}" > /etc/hostname
tee /etc/hosts > /dev/null << EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOST_NAME.localdomain $HOST_NAME
EOF

# Добавление глобальных переменных системы
tee -a /etc/environment > /dev/null << EOF

# Принудительно включаю icd RADV драйвер (если установлен)
AMD_VULKAN_ICD=RADV
EOF

# Для работы граф. планшета Xp-Pen G640 с OpenTabletDriver
echo "blacklist hid_uclogic" > /etc/modprobe.d/blacklist.conf

# Отключение системного звукового сигнала
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

# Установка универсального host файла от StevenBlack (убирает рекламу и вредоносы из WEB'а)
# Обновление host файла выполняется командой: $ uphosts
wget -qO- https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts \
 | grep '^0\.0\.0\.0' \
 | grep -v '^0\.0\.0\.0 [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$' \
 | sed '1s/^/\n/' \
 | tee --append /etc/hosts >/dev/null

# Не позволять системе становится раздудой
# Выставляю максимальный размер журнала systemd
sed -i 's/#SystemMaxUse=/SystemMaxUse=50M/g' /etc/systemd/journald.conf

# Разрешение на вход по SSH отключено для пользователя root
sed -ri -e "s/^#PermitRootLogin.*/PermitRootLogin\ no/g" /etc/ssh/sshd_config

# Пароль root пользователя
echo "root:${USER_PASSWORD}" | chpasswd

# Инициализировать связку ключей Pacman
pacman-key --init
pacman-key --populate archlinux

# Добавления юзера с созданием $HOME и присваивание групп к юзеру, оболочка zsh
useradd -m -G wheel,audio,video,input,optical,users,uucp,games -s /bin/zsh "${USER_NAME}"

# Пароль пользователя
echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd

# Привелегии sudo
if [ "${SUDO_PRIV}" = 'y' ]; then
  # Привилегии sudo с запросом пароля
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL\.*/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
elif [ "${SUDO_PRIV}" = 'n' ]; then
  # Привилегии sudo без запроса пароля
  sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL\.*/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
fi

# Создание пользовательских XDG директорий
# Используются английские названия для удобной работы с терминала
LC_ALL=C sudo -u "${USER_NAME}" xdg-user-dirs-update --force

# Создание других каталогов
mkdir -pv $(xdg-user-dir PICTURES)/{Screenshots/Gif}

# Настройка pacman
sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Делаем pacman красивее
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Добавляем цвета в pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 8/g" /etc/pacman.conf  # Увеличение паралельных загрузок с 5 на 8
sed -i "s/#VerbosePkgLists/VerbosePkgLists/g" /etc/pacman.conf # Более удобный просмотр лист пакетов
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf # Включение multilib репо для запуска 32bit приложений

# Оптимизация makepkg
cp /etc/makepkg.conf{,.backup}
sed -i -e 's|CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt -fexceptions|CFLAGS="-march=native -mtune=native -O2 -pipe -fno-plt -fexceptions|g' \
	-e 's|#MAKEFLAGS=.*|MAKEFLAGS="-j$(expr $(nproc) - 1)"|' \
	-e 's|#RUSTFLAGS=.*|RUSTFLAGS="-C opt-level=2 -C target-cpu=native"|' \
	-e 's|^BUILDENV.*|BUILDENV=(!distcc color ccache check !sign)|g' \
	-e 's|#BUILDDIR.*|BUILDDIR=/tmp/makepkg|g' \
	-e 's|xz.*|xz -c -z -q - --threads=$(nproc))|;s|^#COMPRESSXZ|COMPRESSXZ|' \
	-e 's|zstd.*|zstd -c -z -q - --threads=$(nproc))|;s|^#COMPRESSZST|COMPRESSZST|' \
	-e 's|lz4.*|lz4 -q --best)|;s|^#COMPRESSLZ4|COMPRESSLZ4|' \
	-e "s|PKGEXT.*|PKGEXT='.pkg.tar.lz4'|g" \
 /etc/makepkg.conf

# Синхронизация базы пакетов
pacman -Syy

# Настройка snapper и btrfs в случае обнаружения
if [ "${FS}" = 'btrfs' ]; then

  # Unmount .snapshots
  umount -v /.snapshots
  rm -rfv /.snapshots

  # Create Snapper config
  snapper --no-dbus -c root create-config /

  # Удаляем подтом .snapshots Snapper'а
  btrfs subvolume delete /.snapshots

  # Пересоздаём и переподключаем /.snapshots
  mkdir -v /.snapshots
  mount -v -a

  # Меняем права доступа для легкой замены снимка @ в любое время без потери снимков snapper.
  chmod -v 750 /.snapshots

  # Доступ к снимкам для non-root пользователям
  chown -R :wheel /.snapshots

  # Настройка Snapper
  # Позволять группе wheel использовать команду snapper non-root пользователю
  sed -i "s|^ALLOW_GROUPS=.*|ALLOW_GROUPS=\"wheel\"|g" /etc/snapper/configs/root

  # Установка лимата снимков
  sed -i "s|^TIMELINE_LIMIT_HOURLY=.*|TIMELINE_LIMIT_HOURLY=\"3\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_DAILY=.*|TIMELINE_LIMIT_DAILY=\"6\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_WEEKLY=.*|TIMELINE_LIMIT_WEEKLY=\"0\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_MONTHLY=.*|TIMELINE_LIMIT_MONTHLY=\"0\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_YEARLY=.*|TIMELINE_LIMIT_YEARLY=\"0\"|g" /etc/snapper/configs/root

  # Включение таймеров создания снимков по времени и их очистку
  systemctl enable \
	  snapper-timeline.timer \
      snapper-cleanup.timer

  # Включение таймеров проверки целостности файловой системы для home и /
  systemctl enable \
	  btrfs-scrub@home.timer \
      btrfs-scrub@-.timer

  # Предотвращение индексирования снимков программой "updatedb", что замедляло бы работу системы
  sed -i '/^PRUNENAMES/s/"\(.*\)"/"\1 .snapshots"/' /etc/updatedb.conf

  # Правка mkinitcpio.conf
  sed -i 's/^MODULES.*/MODULES=(btrfs amdgpu)/' /etc/mkinitcpio.conf

  # Добавяем бинарный файл btrfs, чтобы выполнять обслуживание системы без ее монтирования
  sed -i 's/^BINARIES=.*$/BINARIES=(btrfs)/' /etc/mkinitcpio.conf
  sed -i "s/^HOOKS.*/HOOKS=(base consolefont udev autodetect modconf block filesystems keyboard keymap)/g" /etc/mkinitcpio.conf

else
  sed -i 's/^MODULES.*/MODULES=(amdgpu)/' /etc/mkinitcpio.conf
  sed -i "s/^HOOKS.*/HOOKS=(base consolefont udev autodetect modconf block filesystems keyboard keymap fsck)/g" /etc/mkinitcpio.conf
fi
mkinitcpio -P

# Правка конфига reflector
sed -i "s/^--protocol.*/--protocol http,https/" /etc/xdg/reflector/reflector.conf
sed -i "s/# --country.*/--country ru,by/" /etc/xdg/reflector/reflector.conf
sed -i "s/^--latest.*/--latest 12/" /etc/xdg/reflector/reflector.conf
sed -i "s/^--sort.*/--sort rate/" /etc/xdg/reflector/reflector.conf

mkdir /etc/pacman.d/hooks

# Создаю Reflector хук
tee /etc/pacman.d/hooks/mirrorupgrade.hook > /dev/null << EOF
[Trigger]
Operation = Upgrade
Type = Package
Target = pacman-mirrorlist

[Action]
Description = Updating pacman-mirrorlist with reflector and removing pacnew...
When = PostTransaction
Depends = reflector
Exec = /bin/sh -c "systemctl start reflector.service; if [ -f /etc/pacman.d/mirrorlist.pacnew ]; then rm /etc/pacman.d/mirrorlist.pacnew; fi"
EOF

# Чистка кэша Pacman хук
tee /etc/pacman.d/hooks/clean_package_cache.hook > /dev/null << EOF
[Trigger]
Type = Package
Operation = Upgrade
Operation = Install
Operation = Remove
Target = *

[Action]
Description = Чистка кэш пакетов (с сохранением двух последних)...
Depends=pacman-contrib
When = PostTransaction
Exec = /usr/bin/paccache -rk2
EOF

# Хук GRUB обновления (для стабильности)
tee /etc/pacman.d/hooks/92-grub-upgrade.hook > /dev/null << EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = grub

[Action]
Description = Upgrading GRUB...
When = PostTransaction
Exec = /usr/bin/sh -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB; grub-mkconfig -o /boot/grub/grub.cfg"
EOF

# Хук для предотвращения создания Wine ассоциации файлов
tee /etc/pacman.d/hooks/stop-wine-associations.hook > /dev/null << "EOF"
[Trigger]
Operation = Install
Operation = Upgrade
Type = Path
Target = usr/share/wine/wine.inf

[Action]
Description = Остановливаю Wine от перехвата ассоциаций файлов...
When = PostTransaction
Exec = /bin/sh -c '/usr/bin/grep -q "HKCU,\"Software\\\Wine\\\FileOpenAssociations\",\"Enable\",2,\"N\"" /usr/share/wine/wine.inf || /usr/bin/sed -i "s/\[Services\]/\[Services\]\nHKCU,\"Software\\\Wine\\\FileOpenAssociations\",\"Enable\",2,\"N\"/g" /usr/share/wine/wine.inf'
EOF

# Размер Zram
tee /etc/systemd/zram-generator.conf > /dev/null << EOF
[zram0]
zram-size = min(min(ram, 4096) + max(ram - 4096, 0) / 2, 32 * 1024)
compression-algorithm = zstd
EOF

if [ "$(systemd-detect-virt)" = "none" ]; then
# Sysctl оптимизации
# https://ventureo.codeberg.page/source/generic-system-acceleration.html#swap
# https://wiki.archlinux.org/title/Sysctl#Improving_performance

tee /etc/sysctl.d/99-sysctl-performance-tweaks.conf > /dev/null << EOF
# TLDR по первым 4: Исправляет системные тормоза когда копируется большое кол-во/огромных файлов

# Параметр swappiness sysctl представляет предпочтение (или избегание) ядром пространства подкачки. Swappiness может иметь значение от 0 до 100, значение по умолчанию равно 60.
# Низкое значение заставляет ядро избегать подкачки, более высокое - пытаться использовать пространство подкачки. Известно, что использование низкого значения при достаточном объеме памяти улучшает быстродействие многих систем.
# Для 4Gb или 8Gb RAM - оставляем значение по умолчанию 60 или меняем на 80 чтобы стимулировать больше свопа
# Если у вас 16gb RAM - ставим значение 10
vm.swappiness = 10

# Значение контролирует склонность ядра к освобождению памяти, используемой для кэширования объектов каталогов и инодов (VFS-кэш).
# Уменьшение этого значения по сравнению со значением по умолчанию, равным 100, делает ядро менее склонным к восстановлению VFS-кэша (не устанавливайте его равным 0, это может привести к OoM т.е нехватке памяти)
# Рекомендуемым значением будет от 50 до 500
vm.vfs_cache_pressure = 50

# Содержит в процентах от общей доступной памяти, содержащей свободные страницы и страницы, подлежащие восстановлению,
# количество страниц, при котором процесс, генерирующий записи на диск, сам начнет выписывать грязные данные (по умолчанию - 20).
vm.dirty_ratio = 10

# Содержит в процентах от общей доступной памяти, содержащей свободные страницы и страницы, которые можно восстановить, количество страниц, на которых потоки фоновой очистки ядра начнут записывать "грязные" данные (по умолчанию - 10).
vm.dirty_background_ratio = 5

# Исправляет различные проблемы связанные с играми используя SteamPlay (Proton)
# https://wiki.archlinux.org/title/gaming#Increase_vm.max_map_count
vm.max_map_count=2147483642

# Увеличение длины очереди входящих пакетов.
# После получения пакетов из кольцевого буфера сетевой карты они помещаются в специальную очередь в ядре.
# При использовании высокоскоростных сетевых карт увеличение размера очереди может помочь предотвратить потерю пакетов:
net.core.netdev_max_backlog = 16384

# Увеличение максимального числа ожидающих соединений
# Максимальное число входящих соединений, ожидающих приёма (accept) программой, на одном сокете: (default 4096):
net.core.somaxconn = 8192

# Скрывает низкоприоритетные сообщения ядра с консоли.
kernel.printk = 3 3 3 3

# TCP Fast Open — это расширение протокола управления передачей (TCP), которое помогает уменьшить задержки в сети,
# позволяя начать передачу данных сразу при отправке клиентом первого TCP SYN [3].
# Значение 3 вместо стандартного 1 включит TCP Fast Open как для входящих, так и для исходящих соединений:
net.ipv4.tcp_fastopen = 3

# Включение BBR
# Алгоритм управления перегрузками BBR может помочь достичь более высокой пропускной способности и более низких задержек для интернет-трафика.
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr

# Защита от tcp time-wait assassination hazards, отбрасывание RST-пакетов для сокетов в состоянии time-wait.
# За пределами Linux поддерживается не очень широко, но соответствует RFC:
net.ipv4.tcp_rfc1337 = 1

# При включении reverse path filtering ядро будет проверять источник пакетов, полученных со всех интерфейсов машины.
# Это может защитить от злоумышленников, которые используют методы подмены IP-адресов для нанесения вреда.
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1

# Отключение перенаправлений ICMP
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# To use the new FQ-PIE Queue Discipline (>= Linux 5.6) in systems with systemd (>= 217), will need to replace the default fq_codel.
net.core.default_qdisc = fq_pie
EOF

# Экспорт fancontrol конфиг для управления вертиляторов (только AMD RX580)
# 40º - min скорость вентиляторов
# 79º - max скорость вентиляторов
tee /etc/fancontrol > /dev/null << EOF
# Configuration file generated by pwmconfig, changes will be lost
INTERVAL=5
DEVPATH=hwmon0=devices/pci0000:00/0000:00:03.0/0000:03:00.0
DEVNAME=hwmon0=amdgpu
FCTEMPS=hwmon0/pwm1=hwmon0/temp1_input
FCFANS= hwmon0/pwm1=
MINTEMP=hwmon0/pwm1=40
MAXTEMP=hwmon0/pwm1=79
MINSTART=hwmon0/pwm1=150
MINSTOP=hwmon0/pwm1=75
EOF
fi

# Добавления моих опций ядра grub
# intel_iommu=on - Включает драйвер intel iommu
# iommu=pt - Проброс только тех устройств которые поддерживаются
# zswap.enabled=0 - Отключает приоритетный zswap который заменяется на zram
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 mitigations=off intel_iommu=on iommu=pt amdgpu.ppfeaturemask=0xffffffff cpufreq.default_governor=performance zswap.enabled=0"/g' /etc/default/grub

# Правка разрешений папке скриптов
chmod -v 700 /scriptinstall
chown -v 1000:users /scriptinstall

# Установка и настройка Grub
#sed -i -e 's/#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /etc/default/grub # Обнаруживать другие ОС и добавлять их в grub (нужен пакет os-prober)
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Врубаю сервисы
# BTRFS: discard=async можно использовать вместе с fstrim.timer
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable sshd.service
systemctl enable fstrim.timer
systemctl enable plocate-updatedb.timer
systemctl enable systemd-oomd.service
systemctl enable dbus-broker.service
systemctl enable fancontrol.service
systemctl mask systemd-networkd.service
