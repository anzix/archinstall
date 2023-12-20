#!/bin/bash

# Установка
PKGS=(
	'firefox' # Браузер
	'firefox-i18n-ru' # Руссификация браузера
)

sudo pacman -S "${PKGS[@]}" --noconfirm --needed

echo "==> Настройка и экспорт настроек Firefox"
# Временно открыть Firefox, чтобы создать папку профиля.
timeout 5 firefox --headless

# Устанавливаю путь к профилю Firefox
FIREFOX_PROFILE_PATH=$(realpath "${HOME}/.mozilla/firefox/"*.default-release)

# Создание каталога расширений
mkdir -p "${FIREFOX_PROFILE_PATH}/extensions"

# Список расширений (25)
EXTENSIONS=(
 "3913593/matte_black_red-latest.xpi:{a7589411-c5f6-41cf-8bdc-f66527d9d930}" # Тема браузера
 "4050539/violentmonkey-latest.xpi:{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" # Violentmonkey
 "4011167/traduzir_paginas_web-latest.xpi:{036a55b4-5e72-4d05-a06c-cba2dfcc134a}" # TWP - Translate Web Pages
 "4003969/ublock_origin-latest.xpi:uBlock0@raymondhill.net" # UBlock Origin
 "4045009/auto_tab_discard-latest.xpi:{c2c003ee-bd69-42a2-b0e9-6f34222cb046}" # Auto Tab Discard (Усыпление вкладок)
 "3983730/tse_torrents_search_engine-latest.xpi:tse@example.com" # TSE - Torrents Search Engine
 "3898765/ff2mpv-latest.xpi:ff2mpv@yossarian.net" # ff2mpv
 "3009842/enhanced_h264ify-latest.xpi:{9a41dee2-b924-4161-a971-7fb35c053a4a}" # Enchanced h264ify
 "3865240/2668061-latest.xpi:{290ce447-2abb-4d96-8384-7256dd4a1c43}" # Обход блокировок Рунета
 "4043870/browsec-latest.xpi:browsec@browsec.com" # Browsec VPN (Временный vpn)
 "4021899/darkreader-latest.xpi:addon@darkreader.org" # Dark Reader
 "4005382/return_youtube_dislikes-latest.xpi:{762f9885-5a13-4abd-9c77-433dcd38b8fd}" # Return Youtube Dislikes
 "4023682/keepassxc_browser-latest.xpi:keepassxc-browser@keepassxc.org" # Keepassxc Browser
 "4026759/sponsorblock-latest.xpi:sponsorBlocker@ajay.app" # SponsorBlock
 "4026911/steam_database-latest.xpi:firefox-extension@steamdb.info" # SteamDB
 "3900368/cute_save_button-latest.xpi:ochecuteextension@plaza.ink" # Cute Save Button
 "3983650/downthemall-latest.xpi:{DDC359D1-844A-42a7-9AA1-88A850A938A8}" # DownloadThemAll!
 "3971429/cookie_autodelete-latest.xpi:CookieAutoDelete@kennydo.com" # Cookie AutoDelete
 "4027739/dollchan_extension-latest.xpi:dollchan_extension@dscript.me" # Dollchan Extension Tools
 "1051594/switchyomega-latest.xpi:switchyomega@feliscatus.addons.mozilla.org" # Proxy SwitchyOmega
 "3452835/cookies_txt_one_click-latest.xpi:{520a19d3-2d3c-47ee-ba15-cd66aae65db2}" # cookies-txt-one-click
 "3988430/bookmark_dupes-latest.xpi:bookmarkdupes@martin-vaeth.org" # Bookmark Dupes
 "1705492/fixed_zoom-latest.xpi:{a655a6b2-69a5-40de-a3b8-3f7f200c95a7}" # Fixed Zoom
 "3782841/enforce_browser_fonts-latest.xpi:{83e08b00-32de-44e7-97bb-1bab84d1350f}" # Enforce Browser Fonts - полезно особенно для Linux
# "3941342/dont_accept_webp-latest.xpi:dont-accept-webp@jeffersonscher.com" # Don't "Accept" image/webp

# "3988775/7tv-latest.xpi:{7ef0f00c-2ebe-4626-8ed7-3185847fcfad}" # 7TV (Twitch) - Удалён
# "3998783/floccus-latest.xpi:floccus@handmadeideas.org.xpi"
# "3932862/multi_account_containers-latest.xpi:@testpilot-containers.xpi"
)

# Загрузка и установка расширений
for EXTENSION in "${EXTENSIONS[@]}"; do
  PARTIAL_URL=$(echo "$EXTENSION" | cut -d ':' -f 1)
  ID=$(echo "$EXTENSION" | cut -d ':' -f 2)
  URL="https://addons.mozilla.org/firefox/downloads/file/${PARTIAL_URL}"
  FILENAME="$ID.xpi"
  wget -q --show-progress --hsts-file=~/.cache/wget-hsts -O "${FIREFOX_PROFILE_PATH}/extensions/$FILENAME" "$URL"
done

# Импорт Firefox конфига
cp -v ~/.dotfiles/user.js "${FIREFOX_PROFILE_PATH}"

# Настраиваю Firefox под окружение
if [ "${XDG_SESSION_DESKTOP}" = 'KDE' ]; then
# Set Firefox profile path
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.mozilla/firefox/*.default-release)

# KDE specific configurations
tee -a ${FIREFOX_PROFILE_PATH}/user.js > /dev/null << 'EOF'
// Использовать KDE Plasma file picker
user_pref("widget.use-xdg-desktop-portal.mime-handler", 1);
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);

// Предотвращает дублирование записей в виджете медиаплеера KDE Plasma
user_pref("media.hardwaremediakeys.enabled", false);
EOF
fi

