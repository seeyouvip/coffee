#!/bin/sh

# === KONFIGURASIÝA ===
DROPBOX_URL="https://www.dropbox.com/scl/fi/n6lvhvmskif6ikih6c4i9/Mary_ip.ssr.txt?rlkey=pfko6m525xiwv97qdidxezhvl&st=3x0fj081&dl=1"
GOOGLE_DRIVE_URL="https://drive.google.com/uc?export=download&id=1sacbu-pjM1VRkURXj2Zo5xRot5-awhto"
GITHUB_URL="https://raw.githubusercontent.com/seeyouvip/coffee/main/mary_ip.ssr"
IHEART_URL="http://iheart-filepicker.me/sstp_ipMR.txt"
TMP_FILE="/tmp/new_ip.txt"
CONFIG_FILE="/tmp/ss-local.json"
CONFIG_FILE="/tmp/ss-redir.json"
SSR_SCRIPT="/usr/bin/shadowsocks.sh"  # SSR başlatmak üçin skript

echo "[INFO] SSR Stop-Disable"
"$SSR_SCRIPT" stop 2>/dev/null
sleep 2

# === CONFIG-DAKY HÄZIRKI IP/DOMAIN OKAÝARYS ===
CURRENT_HOST=$(grep -oE '"server":\s*"[^"]+"' "$CONFIG_FILE" | awk -F'"' '{print $4}')
echo "[INFO] Häzirki host: $CURRENT_HOST"

# === FAÝLDAN TÄZE IP/DOMAIN ALMAK ===
download_ip_file() {
    for URL in "$GITHUB_URL" "$GOOGLE_DRIVE_URL" "$DROPBOX_URL" "$IHEART_URL"; do
        echo "[INFO] Synanyşylýar: $URL"
        wget -q "$URL" -O "$TMP_FILE" || wget -q "$URL" -O "$TMP_FILE"
        if [ $? -eq 0 ] && grep -qE '[a-zA-Z0-9.-]+' "$TMP_FILE"; then
            echo "[OK] Alnan çeşme: $URL"
            return 0
        fi
    done
    echo "[ERROR] Täze IP ýa domain alynmady!"
    return 1
}

# === ALMAGA SYNANŞYLYAR ===
if ! download_ip_file; then
    exit 1
fi

# === TÄZE HOST ALÝARYS ===
NEW_HOST=$(grep -oE '[a-zA-Z0-9.-]+' "$TMP_FILE" | head -n1)

if [ -z "$NEW_HOST" ]; then
    echo "[ERROR] Täze IP ýa domain tapylmady!"
    exit 1
fi

echo "[INFO] Täze host: $NEW_HOST"

# === IP ÇÖZGÜT — DOMAINDEN IP TAPÝARYS ===
resolve_host() {
    if echo "$1" | grep -qE '[a-zA-Z]'; then
        nslookup "$1" | awk '/^Address: /{print $2}' | tail -n1
    else
        echo "$1"
    fi
}

RESOLVED_NEW=$(resolve_host "$NEW_HOST")
RESOLVED_CURRENT=$(resolve_host "$CURRENT_HOST")

# Täze we häzirki IP-lary deň bolsa, hiç zat etmek gerek däl
if [ "$RESOLVED_NEW" = "$RESOLVED_CURRENT" ]; then
    echo "[OK] Täze host bilen häzirki IP birmeňzeş — täzeläp gerek däl."
 echo "[INFO] SSR täzeden başlanylýar..."
  "$SSR_SCRIPT" restart 2>/dev/null
    rm -f "$TMP_FILE"
    exit 0
fi

# === CONFIG FAÝLYNY TÄZELÄÝÄRIS ===
if grep -q '"server":' "$CONFIG_FILE"; then
    sed -i "s/\"server\": \".*\"/\"server\": \"$NEW_HOST\"/" "$CONFIG_FILE"
    echo "[OK] Config täzelendi: \"server\": \"$NEW_HOST\""
else
    echo "{\"server\": \"$NEW_HOST\"}" >> "$CONFIG_FILE"
    echo "[OK] server ýazgysy goşuldy."
fi

# === NVRAM WE PANEL TÄZELEMEK ===
echo "[INFO] NVRAM we admin panel täzelenýär..."
nvram set ss_server="$NEW_HOST"
nvram commit

# === SSR-I TÄZEDEN BAŞLATMAK ===
echo "[INFO] SSR täzeden başlanylýar..."
"$SSR_SCRIPT" stop 2>/dev/null
sleep 2
"$SSR_SCRIPT" restart 2>/dev/null

# === BAGLANYŞYK BARLAGY ===
echo "[INFO] Baglanyşyk barlag (2 sekunt gözleýär)..."
sleep 2
if ping -c 2 "$NEW_HOST" >/dev/null; then
    echo "[OK] Täze IP işleýär: $NEW_HOST"
else
    echo "[WARN] SeeYou_VIP"
fi

# === ARASSALYK ===
rm -f "$TMP_FILE"
echo "✅ Tamamlandy. SSR we admin panel täzelendi!"
