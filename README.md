# Мой скрипт установки Arch Linux + мой dotfiles (Для личного использования)

### [Для ноутбуков] Установка Wi-Fi-соединения и проверка сети.

```sh
ip a
iwctl station wlan device scan
iwctl station wlan device get-networks
iwctl station wlan device connect SSID --passphrase ""
ping archlinux.org
```

***

После загрузки Arch Linux образа ISO необходимо подождать минуту чтобы сервис `pacman-init.service` **успешно** инициализировал связку ключей\
Если всё же вы столкнулись с ключами при скачивании git просто выполните `systemctl restart pacman-init.service` и снова произойдёт инициализация ключей\
После этого производим:

```sh
# Обновляем зеркала и устанавливаем git
pacman -Sy git
```

Клонируем репо и переходим в него

```sh
git clone https://github.com/anzix/scriptinstall && cd scriptinstall
```

Начинаем установку

```sh
./0-preinstall.sh
```

Когда установка первого скрипта закончиться, вы должны перезагрузиться и после перемещаем папку со скриптами в домашнюю директорию и запускаем финальный скрипт установки

```sh
sudo mv /scriptinstall ~
cd ~/scriptinstall
./2-setup.sh
```

## Для тестирования на виртуалке

Если QEMU/KVM качаем пакеты `qemu-guest-agent spice-vdagent`

> В оконных менеджерах (WM) для активации Shared Clipboard в терминале надо ввести `spice-vdagent`

Для VirtualBox (не проверенно):

- Качаем пакеты `virtualbox-guest-utils xf86-video-vmware`
- Присваиваем пользователю группу vboxfs командой `usermod -a -G vboxsf $(whoami)`
- Активируем systemd сервис `sudo systemctl enable vboxservice.service`

Поддержите меня за мои старания (´｡• ᵕ •｡`)

> [DonationAlerts](https://www.donationalerts.com/r/givefly)
