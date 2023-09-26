# Мой скрипт установки Arch Linux + мой dotfiles (Для личного использования)

- Клонируем репо и переходим в него

```sh
git clone https://github.com/anzix/scriptinstall && cd scriptinstall
```

Начинаем установку

```sh
./0-preinstall.sh
```

Когда установка первого скрипта закончиться, вы должны перезагрузиться и после клонируем мои dotfiles. И тянем только zsh конфиги

```sh
git clone https://github.com/anzix/dotfiles ~/.dotfiles && cd ~/.dotfiles/base
stow -vt ~ zsh
ln -svi /home/$USER/.dotfiles/base/zsh/.config/zsh/profile.zsh ~/.zprofile
exit # перелогиниваемся для применения результатов
```

После перелогина пойдёт установка необходимых плагинов zsh, если что-то не работает например substring search попробуйте снова перелогинится

Теперь перемещаем папку со скриптами в домашнюю директорию и запускаем второй скрипт установки


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
