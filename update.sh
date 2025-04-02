#!/bin/sh

# === KONFIGURASIÝA ===
DROPBOX_URL="https://www.dropbox.com/scl/fi/2v1n1npb9kvbuzeen3pne/LG.txt?rlkey=d1o9u9m4p54zjybmemyycgibr&e=1&st=12yyncpr&dl=1"
GOOGLE_DRIVE_URL="https://drive.google.com/uc?export=download&id=1sLDhv9uZilP20bf_uK0klf-fZOWzPelF"
GITHUB_URL="https://raw.githubusercontent.com/seeyouvip/coffee/main/lg"
IHEART_FILEPICKER_URL="http://iheart-filepicker.me/lg.txt"  # Täze sublink goşuldy
TMP_FILE="/tmp/new_ip.txt"
CONFIG_FILE="/etc/openvpn/clients/LG.ovpn"
#COOKIE="NID=NYjjcwfdlNepOTQi_S2FpJRvPh7cKMJgXzVrrON"

# === INTERNETIŇ BARLANYŞY ===
echo "Internet barlanylýar..."

# Internet ýok bolsa, OpenVPN-i disable edip, lan, wan interfeýsi restart edeliň.
ping -c 3 www.google.com > /dev/null 2>&1 
if [ $? -ne 0 ]; then

    echo "Internet ýok, OpenVPN-disable edilýär..."
    
    # OpenVPN-i disable etmek
   # /etc/init.d/openvpn stop
   # /etc/init.d/openvpnc stop
    /etc/init.d/openvpn disable
    /etc/init.d/openvpnc disable
    
    # Internet gelýänçä garaşmak
    until ping -c 1 www.google.com > /dev/null 2>&1; do
        echo "Internet ýok, täzeden synanyşýarys..."
        sleep 5
    done
    echo "Internet geldi!"

    # IP almak üçin işlemler
    echo "Internet geldi, IP almak üçin işlemler başlatylýar..."
    curl -L --cookie "NID=$COOKIE" "$GOOGLE_DRIVE_URL" -o "$TMP_FILE"

    if [ $? -ne 0 ]; then
        echo "Google Drive-dan almak başartmady. Dropbox-dan synanyşylýar..."
        curl -Ls "$DROPBOX_URL" -o "$TMP_FILE"
    fi

    if [ $? -ne 0 ]; then
        echo "Dropbox-dan almak başartmady. GitHub-dan synanyşylýar..."
        curl -Ls "$GITHUB_URL" -o "$TMP_FILE"
    fi

    if [ $? -ne 0 ]; then
        echo "GitHub-dan almak başartmady. iheart-filepicker-dan synanyşylýar..."
        curl -Ls "$IHEART_FILEPICKER_URL" -o "$TMP_FILE"
    fi

    # IP bar bolsa, işlemeli
    if [ -s "$TMP_FILE" ]; then
        NEW_IP=$(cat "$TMP_FILE" | tr -d ' \n')
        CURRENT_IP=$(grep "^remote " "$CONFIG_FILE" | awk '{print $2}')
        
        echo "Häzirki IP: $CURRENT_IP"
        echo "Täze IP: $NEW_IP"

        # IP üýtgän bolsa, OpenVPN-i täzeden başlat
        if [ "$NEW_IP" != "$CURRENT_IP" ]; then
            echo "IP üýtgedi, OpenVPN konfigurasiýa faýly täzelenýär..."
            
            # IP üýtgän bolsa, täze IP-ni ýazmak
            sed -i "s/^remote .*/remote $NEW_IP 443/" "$CONFIG_FILE"

            # "scramble xormask 5" bar bolsa, ony poz
    sed -i '/scramble xormask 5/d' "$CONFIG_FILE"

    # Zerur konfigurasiýalar bar bolsa, täzeden goşma
    for line in \
        "proto tcp-client" \
        "tls-crypt" \
        "tun-mtu 1500" \
        "mssfix 1450" \
        "sndbuf 524288" \
        "rcvbuf 524288" \
        "socket-flags TCP_NODELAY" \
        "keepalive 10 60" \
        "scramble xormask ddFF"
    do
        grep -q "$line" "$CONFIG_FILE" || echo "$line" >> "$CONFIG_FILE"
    done

    # Türkmenistan IP ugurlary üçin konfigurasiýa
    for route in \
        "route 95.85.96.0 255.255.224.0 net_gateway" \
        "route 95.47.57.0 255.255.255.0 net_gateway" \
        "route 217.174.224.0 255.255.240.0 net_gateway" \
        "route 185.69.187.0 255.255.255.0 net_gateway" \
        "route 185.69.186.0 255.255.255.0 net_gateway" \
        "route 185.69.185.0 255.255.255.0 net_gateway" \
        "route 185.246.72.0 255.255.252.0 net_gateway" \
        "route 93.171.220.0 255.255.252.0 net_gateway" \
        "route 216.250.8.0 255.255.248.0 net_gateway" \
        "route 185.69.184.0 255.255.255.0 net_gateway" \
        "route 177.93.143.0 255.255.255.0 net_gateway" \
        "route 119.235.112.0 255.255.240.0 net_gateway" \
        "route 103.220.0.0 255.255.252.0 net_gateway"
    do
        grep -q "$route" "$CONFIG_FILE" || echo "$route" >> "$CONFIG_FILE"
    done

    echo "Konfigurasiýa täzelendi."

            # Network interfeysi restart
            /etc/init.d/network restart
            echo "Network interfeysi tazelenyar..."
            
            # OpenVPN-ýi täzeden başlatmak
           # /etc/init.d/openvpn restart
           # /etc/init.d/openvpnc restart
            /etc/init.d/openvpn start
            /etc/init.d/openvpnc start
            /etc/init.d/openvpn enable
            /etc/init.d/openvpnc enable
            echo "OpenVPN täzeden başlatyldy."

           # ifup lan
        else
            echo "IP üýtgemedi, hiç zat edilmeýär."
        fi
    else
        echo "Täze IP alyp bolmady!"
        exit 1
    fi

else
    echo "Internet bar, IP almak üçin işlemler başlatylýar..."

    # IP almak üçin işlemler başlatylýar
    curl -L --cookie "NID=$COOKIE" "$GOOGLE_DRIVE_URL" -o "$TMP_FILE"

    if [ $? -ne 0 ]; then
        echo "Google Drive-dan almak başartmady. Dropbox-dan synanyşylýar..."
        curl -Ls "$DROPBOX_URL" -o "$TMP_FILE"
    fi

    if [ $? -ne 0 ]; then
        echo "Dropbox-dan almak başartmady. GitHub-dan synanyşylýar..."
        curl -Ls "$GITHUB_URL" -o "$TMP_FILE"
    fi

    if [ $? -ne 0 ]; then
        echo "GitHub-dan almak başartmady. iheart-filepicker-dan synanyşylýar..."
        curl -Ls "$IHEART_FILEPICKER_URL" -o "$TMP_FILE"
    fi

    # IP bar bolsa, işlemeli
    if [ -s "$TMP_FILE" ]; then
        NEW_IP=$(cat "$TMP_FILE" | tr -d ' \n')
        CURRENT_IP=$(grep "^remote " "$CONFIG_FILE" | awk '{print $2}')
        
        echo "Häzirki IP: $CURRENT_IP"
        echo "Täze IP: $NEW_IP"

        # IP üýtgän bolsa, OpenVPN-i täzeden başlat
        if [ "$NEW_IP" != "$CURRENT_IP" ]; then
            echo "IP üýtgedi, OpenVPN konfigurasiýa faýly täzelenýär..."
            
            # IP üýtgän bolsa, täze IP-ni ýazmak
            sed -i "s/^remote .*/remote $NEW_IP 443/" "$CONFIG_FILE"

            # "scramble xormask 5" bar bolsa, ony poz
    sed -i '/scramble xormask 5/d' "$CONFIG_FILE"

    # Zerur konfigurasiýalar bar bolsa, täzeden goşma
    for line in \
        "proto tcp-client" \
        "tls-crypt" \
        "tun-mtu 1500" \
        "mssfix 1450" \
        "sndbuf 524288" \
        "rcvbuf 524288" \
        "socket-flags TCP_NODELAY" \
        "keepalive 10 60" \
        "scramble xormask ddFF"
    do
        grep -q "$line" "$CONFIG_FILE" || echo "$line" >> "$CONFIG_FILE"
    done

    # Türkmenistan IP ugurlary üçin konfigurasiýa
    for route in \
        "route 95.85.96.0 255.255.224.0 net_gateway" \
        "route 95.47.57.0 255.255.255.0 net_gateway" \
        "route 217.174.224.0 255.255.240.0 net_gateway" \
        "route 185.69.187.0 255.255.255.0 net_gateway" \
        "route 185.69.186.0 255.255.255.0 net_gateway" \
        "route 185.69.185.0 255.255.255.0 net_gateway" \
        "route 185.246.72.0 255.255.252.0 net_gateway" \
        "route 93.171.220.0 255.255.252.0 net_gateway" \
        "route 216.250.8.0 255.255.248.0 net_gateway" \
        "route 185.69.184.0 255.255.255.0 net_gateway" \
        "route 177.93.143.0 255.255.255.0 net_gateway" \
        "route 119.235.112.0 255.255.240.0 net_gateway" \
        "route 103.220.0.0 255.255.252.0 net_gateway"
    do
        grep -q "$route" "$CONFIG_FILE" || echo "$route" >> "$CONFIG_FILE"
    done

    echo "Konfigurasiýa täzelendi."

            # Network interfeysi restart
            /etc/init.d/network restart
            echo "Network interfeysi tazelenyar..."
            
            # OpenVPN-ýi täzeden başlatmak
           # /etc/init.d/openvpn restart
           # /etc/init.d/openvpn start
             /etc/init.d/openvpn start
             /etc/init.d/openvpnc start
             /etc/init.d/openvpn enable
             /etc/init.d/openvpnc enable

            echo "OpenVPN täzeden başlatyldy."

           # ifup lan
        else
            echo "IP üýtgemedi, hiç zat edilmeýär."
        fi
    else
        echo "Täze IP alyp bolmady!"
        exit 1
    fi
fi

echo "Script tamamlandy."
