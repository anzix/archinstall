# Мой скрипт установки Arch Linux + мой dotfiles (Для личного использования)

(Необязательно) Для начала временно установим Русский шрифт в начальный экран установки Arch Linux 
>Это делается для того чтобы можно было увидеть при редактировании русские символы в моём скрипте для полного понимания моего скрипта

````
loadkeys ru
````
````
setfont cyr-sun16
````

Далее вводим эту строчку для скачивания первого файла скрипта


`````````````````````````````````
curl -O https://raw.githubusercontent.com/anzix/scriptinstall/main/install.sh
`````````````````````````````````
Потом даём право нашему файлу на чтение


`````````````````````````````````
chmod +x install.sh
`````````````````````````````````
И начинаем установку 


`````````````````````````````````
./install.sh
`````````````````````````````````
Когда установка первого скрипта закончиться, вы должны перезагрузиться и после этого скачиваем второй файл скрипта. Проделав всё тоже самое как с первым

`````````````````````````````````
curl -O https://raw.githubusercontent.com/anzix/scriptinstall/main/setup.sh
`````````````````````````````````

>Если хотите подробно увидеть или отредактировать скрипт введите 
`````````````````````````````````
nano setup.sh
`````````````````````````````````
`````````````````````````````````
chmod +x setup.sh
`````````````````````````````````

`````````````````````````````````
./setup.sh
`````````````````````````````````

Поддержите меня за мои старания (´｡• ᵕ •｡`)

>[DonationAlerts](https://www.donationalerts.com/r/givefly)
