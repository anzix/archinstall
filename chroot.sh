#!/bin/bash

# Руссифицируемся
sed -i "s/#\(en_US\.UTF-8\)/\1/; s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen
locale-gen
tee /etc/locale.conf > /dev/null << EOF
LANG=ru_RU.UTF-8
LC_COLLATE=C
EOF

# Смена раскладки клавиатуры в tty
# TODO: ru-mab — кодировка UTF-8 переключение на Ctrl+Shift
if [ ${XKB_LAYOUT} = '1' ]; then
  echo "KEYMAP=ruwin_alt_sh-UTF-8" > /etc/vconsole.conf
elif [ ${XKB_LAYOUT} = '2' ]; then
  echo "KEYMAP=ruwin_cplk-UTF-8" > /etc/vconsole.conf
fi
echo "FONT=ter-v22b" >> /etc/vconsole.conf

# Часовой пояс и апаратные часы
ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
hwclock --systohc # Эта команда предполагает, что аппаратные часы настроены в формате UTC.

# Имя хоста 
echo $HOST_NAME > /etc/hostname
tee /etc/hosts > /dev/null << EOF 
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOST_NAME.localdomain $HOST_NAME

EOF

# Пароль root пользователя
echo root:$USER_PASSWORD | chpasswd

# Инициализировать связку ключей Pacman
pacman-key --init
pacman-key --populate archlinux

# Добавления юзера и присваивание групп к юзеру
useradd -m -g users -G wheel,audio,video,input,optical,uucp,games -s /bin/zsh $USER_NAME
echo $USER_NAME:$USER_PASSWORD | chpasswd

# Привелегии sudo
if [ ${SUDO_PRIV} = 'y' ]; then
  # Привилегии sudo с запросом пароля
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL\.*/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
elif [ ${SUDO_PRIV} = 'n' ]; then
  # Привилегии sudo без запроса пароля
  sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL\.*/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
fi

# Создание пользовательских XDG директорий
LC_ALL=C sudo -u $USER_NAME xdg-user-dirs-update --force

# Настройка pacman
sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Делаем pacman красивее
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Добавляем цвета в pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 8/g" /etc/pacman.conf  # Увеличение паралельных загрузок с 5 на 8
sed -i "s/#VerbosePkgLists/VerbosePkgLists/g" /etc/pacman.conf # Более удобный просмотр лист пакетов
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf # Раскоментирование строчки multilib для запуска 32bit приложений

# Синхронизация базы пакетов
pacman -Syy

# Обнаружение виртуалки
case $hypervisor in
  kvm )     echo "==> KVM обнаружен."
            echo "==> Устанавливаю гостевые инструменты."
            pacman -S qemu-guest-agent spice-vdagent --noconfirm --needed
            # В оконных менеджерах (WM) для активации Shared Clipboard в терминале надо ввести spice-vdagent
            ;;
  oracle )  echo "==> VirtualBox обнружен."
            echo "==> Устанавливаю гостевые инструменты."
            pacman -S virtualbox-guest-utils xf86-video-vmware --noconfirm --needed
            # Shared Folder
            usermod -a -G vboxsf $USER_NAME
            # systemctl enable vboxservice.service
            ;;
  * ) ;;
esac

# Настройка snapper и btrfs в случае обнаружения
if [ ${FS} = '2' ]; then
  # Unmount .snapshots
  umount -v /.snapshots
  rm -rfv /.snapshots

  # Create Snapper config
  snapper --no-dbus -c root create-config /
  
  # Информация о размере снапшота btrfs
  #btrfs quota enable /
  
  # Delete Snapper's .snapshots subvolume
  btrfs subvolume delete /.snapshots

  # Re-create and re-mount /.snapshots mount
  mkdir -v /.snapshots
  mount -v -a

  # Меняем права доступа для легкой замены снимка @ в любое время без потери снимков snapper.
  chmod -v 750 /.snapshots

  # Access for non-root users
  chown -R :wheel /.snapshots

  # Configure Snapper
  # Позволять группе wheel использовать snapper ls non-root пользователю
  sed -i "s|^ALLOW_GROUPS=.*|ALLOW_GROUPS=\"wheel\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_HOURLY=.*|TIMELINE_LIMIT_HOURLY=\"3\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_DAILY=.*|TIMELINE_LIMIT_DAILY=\"6\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_WEEKLY=.*|TIMELINE_LIMIT_WEEKLY=\"0\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_MONTHLY=.*|TIMELINE_LIMIT_MONTHLY=\"0\"|g" /etc/snapper/configs/root
  sed -i "s|^TIMELINE_LIMIT_YEARLY=.*|TIMELINE_LIMIT_YEARLY=\"0\"|g" /etc/snapper/configs/root

  # Enable Snapper services
  systemctl enable snapper-timeline.timer
  systemctl enable snapper-cleanup.timer

  # Btrfs твики
  systemctl enable btrfs-scrub@home.timer 
  systemctl enable btrfs-scrub@-.timer 

  # Пропускать снапшоты для locate (Предотвращает замедление моментальных снимков)
  sed -i '/^PRUNENAMES/s/"\(.*\)"/"\1 .snapshots"/' /etc/updatedb.conf

  # Правка mkinitcpio.conf
  sed -i 's/^MODULES.*/MODULES=(btrfs amdgpu)/' /etc/mkinitcpio.conf
  
  # Add the btrfs binary in order to do maintenence on system without mounting it
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
Description = Очистка устаревших кэшированных пакетов (с сохранением двух последних)...
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
# UEFI/GPT
Exec = /usr/bin/sh -c "grub-install --efi-directory=/boot/efi; grub-mkconfig -o /boot/grub/grub.cfg"
# BIOS/MBR
# Exec = /usr/bin/sh -c "grub-install --target=i386-pc /dev/sda; grub-mkconfig -o /boot/grub/grub.cfg"
EOF

# Запрещаем Wine создавать ассоциацию файлов
tee /etc/pacman.d/hooks/stop-wine-associations.hook > /dev/null << EOF
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

# Zram
tee /etc/systemd/zram-generator.conf > /dev/null << EOF
[zram0]
zram-size = min(min(ram, 4096) + max(ram - 4096, 0) / 2, 32 * 1024)
compression-algorithm = zstd
EOF

if [ "$(systemd-detect-virt)" = "none" ]; then
# Sysctl оптимизации
# https://ventureo.codeberg.page/source/generic-system-acceleration.html#swap
# https://wiki.archlinux.org/title/Sysctl#Improving_performance

tee /etc/sysctl.d/99-sysctl.conf > /dev/null << EOF
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# Исправляет различные проблемы связанные с играми используя SteamPlay (Proton)
vm.max_map_count=1048576

# Увеличение длины очереди входящих пакетов.
# После получения пакетов из кольцевого буфера сетевой карты они помещаются в специальную очередь в ядре.
# При использовании высокоскоростных сетевых карт увеличение размера очереди может помочь предотвратить потерю пакетов:
net.core.netdev_max_backlog = 16384

# Увеличение максимального числа ожидающих соединений
# Максимальное число входящих соединений, ожидающих приёма (accept) программой, на одном сокете: (default 4096):
net.core.somaxconn = 8192

# Скрывает любые сообщения ядра с консоли.
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
fi

# Добавления моих опций ядра grub
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 mitigations=off pcie_aspm=off intel_iommu=on iommu=pt audit=0 nowatchdog amdgpu.ppfeaturemask=0xffffffff cpufreq.default_governor=performance intel_pstate=passive zswap.enabled=0"/g' /etc/default/grub

#sed -i -e 's/GRUB_GFXMODE=auto/GRUB_GFXMODE="1920x1080x32"/g' /etc/default/grub
#sed -i -e 's/#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /etc/default/grub # Обнаруживать другие ОС и добавлять их в grub (нужен пакет os-prober)
grub-install --efi-directory=/boot/efi # UEFI/GPT
# grub-install --target=i386-pc /dev/sda # BIOS/MBR
grub-mkconfig -o /boot/grub/grub.cfg


# Врубаю сервисы
systemctl enable NetworkManager.service
# systemctl enable dhcpcd
systemctl enable sshd
systemctl enable fstrim.timer
systemctl enable plocate-updatedb.timer
systemctl enable systemd-oomd.service
systemctl enable dbus-broker.service
