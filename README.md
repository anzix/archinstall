# Bash scriptinstall для ArchLinux
UEFI + BTRFS + Subvolume + Zstd
----------------------------------
Мой скрипт установки Arch Linux (Пока только проверял на виртуалке Vmware player 16)

Если же хотите ручной установки от меня то вот ссылка на мой guide в гугл документы
https://docs.google.com/document/d/1c9yqKSz5LkS1Gd422w4TMdf-_76PHySzku4PsHbxZok/edit?usp=sharing

Данный скрипт подразумевает установку тайлингового оконного менеджера i3


Вводим эту строчку в начальный экран установки Arch Linux
--------------------------------------------------------
````
curl -O https://raw.githubusercontent.com/anzix/scriptinstall/main/install.sh
````
Потом даём право нашему файлу на чтение
---------------------------------------

````
chmod +x install.sh
````
И начинаем установку 
---------------------

````
./install.sh
````
Когда установка первого скрипта закончиться, вы должны перезагрузиться и после этого запустить второй скрипт. Проделав всё тоже самое

`````
curl -O https://raw.githubusercontent.com/anzix/scriptinstall/main/nextinstall.sh
`````
````
chmod +x nextinstall.sh
````

````
./nextinstall.sh
````

Всем тем кто будет заинтересован в изучении моего конфига как и что он устанавливает, какие команды выполняет, прошу ознакомиться (￢‿￢ )

Скрипт будет дополняться.
