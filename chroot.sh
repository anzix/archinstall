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
useradd -m -g users -G wheel,audio,video,input,optical,games -s /bin/zsh $USER_NAME
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

# Правка mkinitcpio.conf
if [ ${FS} = '2' ]; then
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

# Хук GRUB обновления
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

# Zram
tee /etc/systemd/zram-generator.conf > /dev/null << EOF
[zram0]
zram-size = min(min(ram, 4096) + max(ram - 4096, 0) / 2, 32 * 1024)
compression-algorithm = zstd
EOF

if [ "$(systemd-detect-virt)" = "none" ]; then
# Syslog оптимизации
# https://ventureo.codeberg.page/source/generic-system-acceleration.html#swap
# https://wiki.archlinux.org/title/Sysctl#Improving_performance

tee /etc/sysctl.d/99-sysctl.conf > /dev/null << EOF
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=5

# Increasing the size of the receive queue.
# The received frames will be stored in this queue after taking them from the ring buffer on the network card.
# Increasing this value for high speed cards may help prevent losing packets:
net.core.netdev_max_backlog=16384

# Increase the maximum connections
#The upper limit on how many connections the kernel will accept (default 128):
net.core.somaxconn=8192

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
systemctl enable systemd-oomd.service
systemctl enable dbus-broker.service
