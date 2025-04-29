#!/bin/sh

# === KONFIGURASIÝA ===
DROPBOX_URL="https://www.dropbox.com/scl/fi/n6lvhvmskif6ikih6c4i9/Mary_ip.ssr.txt?rlkey=pfko6m525xiwv97qdidxezhvl&st=3x0fj081&dl=1"
GOOGLE_DRIVE_URL="https://drive.google.com/uc?export=download&id=1sacbu-pjM1VRkURkZo5xRot5-awhto"
GITHUB_URL="https://raw.githubusercontent.com/seeyouvip/coffee/main/mary_ip.ssr"
IHEART_URL="http://iheart-filepicker.me/mary_ip.ssr.txt"

TMP_FILE="/tmp/new_ip.txt"
CONFIG_LOCAL="/tmp/ss-local.json"
CONFIG_REDIR="/tmp/ss-redir.json"
SSR_SCRIPT="/usr/bin/shadowsocks.sh"

PORT="443"
PASSWORD="SeeYou_VIP"

echo "[INFO] SSR Stop-Disable"
"$SSR_SCRIPT" stop 2>/dev/null
sleep 2

# === CONFIG-DAKY HÄZIRKI IP OKAÝARYS ===
CURRENT_HOST=$(grep -oE '"server":\s*"[^"]+"' "$CONFIG_LOCAL" | awk -F'"' '{print $4}')
echo "[INFO] Häzirki host: $CURRENT_HOST"

# === IP FAÝLY ALMAK ===
download_ip_file() {
    for URL in "$GITHUB_URL" "$GOOGLE_DRIVE_URL" "$DROPBOX_URL" "$IHEART_URL"; do
        echo "[INFO] Synanyşylýar: $URL"
        wget -q "$URL" -O "$TMP_FILE"
        if [ $? -eq 0 ] && grep -qE '[a-zA-Z0-9.-]+' "$TMP_FILE"; then
            echo "[OK] Alnan çeşme: $URL"
            return 0
        fi
    done
    echo "[ERROR] Täze IP tapylmady!"
    return 1
}

if ! download_ip_file; then
    exit 1
fi

NEW_HOST=$(grep -oE '[a-zA-Z0-9.-]+' "$TMP_FILE" | head -n1)

if [ -z "$NEW_HOST" ]; then
    echo "[ERROR] Täze host tapylmady!"
    exit 1
fi

echo "[INFO] Täze host: $NEW_HOST"

# Täze we häzirki IP deň bolsa — hiç zat etmeli däl
if [ "$NEW_HOST" = "$CURRENT_HOST" ]; then
    echo "[OK] Täze host öňki bilen deň — täzeläp gerek däl."
    "$SSR_SCRIPT" restart 2>/dev/null
    rm -f "$TMP_FILE"
    exit 0
fi

# === ss-local.json täzeläp goýmak ===
sed -i "s/\"server\": \".*\"/\"server\": \"$NEW_HOST\"/" "$CONFIG_LOCAL"
sed -i "s/\"server_port\": [0-9]\+/\"server_port\": $PORT/" "$CONFIG_LOCAL"
sed -i "s/\"password\": \".*\"/\"password\": \"$PASSWORD\"/" "$CONFIG_LOCAL"

# === ss-redir.json hem täzelenýär ===
sed -i "s/\"server\": \".*\"/\"server\": \"$NEW_HOST\"/" "$CONFIG_REDIR"
sed -i "s/\"server_port\": [0-9]\+/\"server_port\": $PORT/" "$CONFIG_REDIR"
sed -i "s/\"password\": \".*\"/\"password\": \"$PASSWORD\"/" "$CONFIG_REDIR"

echo "[OK] ss-local we ss-redir faýllar täzelendi."

# === NVRAM maglumatlary ýazylýar ===
nvram set ss_server="$NEW_HOST"
nvram set ss_server_port="$PORT"
nvram set ss_key="$PASSWORD"
nvram commit

# === SSR täzeden başlanylýar ===
echo "[INFO] SSR täzeden başlanylýar..."
"$SSR_SCRIPT" stop 2>/dev/null
sleep 2
"$SSR_SCRIPT" restart 2>/dev/null

# === Baglanyşyk barlagy ===
echo "[INFO] Baglanyşyk barlagy..."
sleep 2
if ping -c 2 "$NEW_HOST" >/dev/null; then
    echo "[OK] Täze IP işleýär: $NEW_HOST"
else
    echo "[WARN] Täze hosta baglanyp bolmady, emma täzelenme üstünlikli."
fi

rm -f "$TMP_FILE"
echo "✅ Tamamlandy!"
