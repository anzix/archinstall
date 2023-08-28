#!/bin/bash

# Необходимые пакеты для виртуализации
PKGS=(
 'virt-manager' # Менеджер виртуальных машин
 'qemu-base' # Виртуализация
 'qemu-emulators-full' # Поддержка всех архитектур для виртуализации
 'dnsmasq'
 'nftables' 'iptables-nft' # Средство управления сетью пакетами данных ядра Linux используя интерфейс nft
 'dmidecode' # Утилиты о системной информации SMBIOS/DMI и т.д
 'edk2-ovmf' # Поддержка UEFI для QEMU
 'swtpm' # Поддержка TPM для QEMU
)
sudo pacman -S "${PKGS[@]}" --noconfirm --needed --ask 4

# Использовать как обычный пользователь
sudo usermod -aG libvirt $(whoami)

# Включаем сервис
sudo systemctl enable libvirtd

PS3="Выберите настройку сети VM: "
select ENTRY in "Default" "Bridge"; do
	export NETWORK_VM=$ENTRY
	echo "Выбран ${NETWORK_VM}."
	break
done

# Установка сети VM
if [ ${NETWORK_VM} = 'Default' ]; then
  # Автозапуск вирт. сети [default] при запуске системы
  sudo virsh net-autostart default
  # Включить [default] вирт. сеть
  sudo virsh net-start default
elif [ ${NETWORK_VM} = 'Bridge' ]; then
  echo "==> Создане моста и настройка сети на ваших виртуальных машинах"
  touch ~/.config/br10.xml
  tee -a ~/.config/br10.xml > /dev/null << END
<network>
<name>br10</name>
<forward mode='nat'>
<nat>
    <port start='1024' end='65535'/>
</nat>
</forward>
<bridge name='br10' stp='on' delay='0'/>
<ip address='192.168.30.1' netmask='255.255.255.0'>
<dhcp>
    <range start='192.168.30.50' end='192.168.30.200'/>
</dhcp>
</ip>
</network>
END
  echo "==> Добавление и автозапуск моста"
  sudo virsh net-define ~/.config/br10.xml
  sudo virsh net-autostart --network br10
  sudo virsh net-autostart --network default
fi

