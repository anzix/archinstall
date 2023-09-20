#!/bin/bash

echo "==> Установка пакетов для виртуализации"
sudo pacman -S --noconfirm --needed --ask 4 $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/vm_support | column -t)

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

