#!/bin/bash

echo "==> Установка пакетов для виртуализации"
sudo pacman -S --noconfirm --needed --ask 4 $(sed -e '/^#/d' -e 's/#.*//' -e "s/'//g" -e '/^\s*$/d' -e 's/ /\n/g' packages/vm_support | column -t)

# libvirt - Использовать как обычный пользователь
# kvm - для проброса input устройств (VFIO)
sudo usermod -aG kvm,libvirt $(whoami)

# Иметь доступ к локальным .qcow2 образам за пределами /var/lib/libvirt/images
sudo cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.bak
sudo sed -i 's|#user = .*|user = "'$(id -un)'"|g' /etc/libvirt/qemu.conf
sudo sed -i 's|^#group = .*|group = "'$(id -un)'"|g' /etc/libvirt/qemu.conf

# Включаем сервис
sudo systemctl enable libvirtd

PS3="Выберите настройку сети VM: "
select ENTRY in "Default virbr0 (NAT)" "Bridge"; do
	export NETWORK_VM=$ENTRY
	echo "Выбран ${NETWORK_VM}."
	break
done

# FIXME: исправить второй вариант Bridge
# так как это НЕ мост по своей сути это
# тот же NAT
# https://www.redhat.com/sysadmin/setup-network-bridge-VM
# https://wiki.archlinux.org/title/Network_bridge
# https://linuxconfig.org/how-to-use-bridged-networking-with-libvirt-and-kvm
# https://www.spad.uk/posts/really-simple-network-bridging-with-qemu/
# https://www.altlinux.org/%D0%9D%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0_%D1%81%D0%B5%D1%82%D0%B8_%D0%B2_KVM#%D0%92%D0%BD%D1%83%D1%82%D1%80%D0%B5%D0%BD%D0%BD%D0%B8%D0%B9_%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9_%D0%BC%D0%BE%D1%81%D1%82

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

