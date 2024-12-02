# Мой скрипт установки Arch Linux + мой dotfiles (Для личного использования)

После загрузки Arch Linux образа ISO необходимо подождать минуту чтобы сервис `pacman-init.service` **успешно** инициализировал связку ключей\
Если всё же вы столкнулись с ключами при скачивании git просто выполните `systemctl restart pacman-init.service` и снова произойдёт инициализация ключей\

## [Для ноутбуков] Установка Wi-Fi-соединения и проверка сети

Вот что нужно делать как только вы вошли в установщик Arch Linux

```sh
# Необходимо узнать сетевой интерфейс устройства (device)
ip a

# Входим в интерактивный промпт
iwctl

# Сканируем на наличие новых сетей
# Вместо `device` должен быть ваш интерфейс полученный из предыдущей команды
[iwd] station device scan

# Выводим список сетей
[iwd] station device get-networks

# Подключаемся к сети заполняя свои данные
[iwd] station device connect SSID --passphrase ""

# Проверяем сеть
ping archlinux.org
```

***

Обновляем зеркала и устанавливаем git

```sh
pacman -Sy git
```

Клонируем репо и переходим в него

```sh
git clone https://github.com/anzix/archinstall && cd archinstall
```

> Перед тем как начать установку пробегитесь по выбору пакетов которые я указал в ``packages/base`` открыв любым текстовым редактором vim или nano\
> Выберете (закомментировав/раскомментировав) используя # (хэш) те пакеты которые вы нуждаетесь\
> Предоставляется выбор для драйверов между AMD и Nvidia

Начинаем установку

```sh
./0-preinstall.sh
```

Когда установка первого скрипта закончиться перезагружаемся.

Второй этап установки\
Перемещаем папку со скриптами в домашнюю директорию и запускаем финальный скрипт установки.

```sh
sudo mv /archinstall ~
cd ~/archinstall
./2-setup.sh
```

После входа в окружение вы можете опционально установить Firefox с моими настройками и расширениями\
Для этого просто выполните скрипт командой

```sh
./firefox_install.sh
```

## Для тестирования на виртуалке

1. Для QEMU/KVM качаем пакеты `qemu-guest-agent spice-vdagent`

   > В оконных менеджерах (WM) для активации Shared Clipboard в терминале надо ввести `spice-vdagent`

2. Для VirtualBox (не проверенно):

   - Качаем пакеты `virtualbox-guest-utils xf86-video-vmware`
   - Присваиваем пользователю группу vboxfs командой `usermod -a -G vboxsf $(whoami)`
   - Активируем systemd сервис `sudo systemctl enable vboxservice.service`

3. Для VMware

   - Качаем пакеты `open-vm-tools xf86-video-vmware xf86-input-vmmouse xf86-video-vesa xf86-input-libinput xf86-video-fbdev`
   - Активируем systemd сервис `sudo systemctl enable vmtoolsd.service`
   - Если нужно иметь общие папки, [читайте тут](https://wiki.archlinux.org/title/VMware/Install_Arch_Linux_as_a_guest#Shared_Folders_with_vmhgfs-fuse_utility)

## Восстановление Arch, chroot из под LiveISO

Скачиваем Arch LiveISO на флешку и загружаемся с неё

```sh
# Монтируем
mount -v -o subvol=@ /dev/vda2 /mnt
mount -v /dev/vda1 /mnt/boot/efi

# Чрутимся
arch-chroot /mnt
```

Поддержите меня за мои старания (´｡• ᵕ •｡`)

> [DonationAlerts](https://www.donationalerts.com/r/givefly)
