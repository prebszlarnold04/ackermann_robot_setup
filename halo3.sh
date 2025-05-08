#!/bin/bash
set -euo pipefail

# Szín definíciók (ID: magyar:nemzetközi:betű)
declare -A SZINEK=(
  ["101"]="Fekete:fekete:f"
  ["102"]="Szürke:szurke:g"
  ["103"]="Fehér:feher:w"
  ["104"]="Bordó:bordo:d"
  ["105"]="Piros:piros:p"
  ["106"]="Narancs:narancs:n"
  ["107"]="Sárga:sarga:s"
  ["108"]="Barna:barna:b"
  ["109"]="Kék:kek:k"
  ["110"]="Lila:lila:l"
  ["111"]="Zöld:zold:z"
  ["112"]="Rózsaszín:rozsaszin:r"
  ["113"]="Bézs:bezs:x"
)

if [[ $# -ne 1 ]]; then
  echo "Használat: $0 <robot-szám> (101–113)"
  exit 1
fi
ROBOT_SZAM="$1"

if [[ -z "${SZINEK[$ROBOT_SZAM]:-}" ]]; then
  echo "Hiba: érvénytelen szám (csak 101–113)!"
  exit 2
fi

# Adatok kinyerése
IFS=':' read -r SZIN_HU SZIN_SSID SZIN_BETU <<< "${SZINEK[$ROBOT_SZAM]}"
ROBOT_ID="robo_${SZIN_BETU}"
ROBOT_IP="192.168.0.${ROBOT_SZAM}"
ROBOT_SSID="tsrobo_${SZIN_SSID}_${ROBOT_SZAM}"
WIFI_JELSZO="dongguan"

# UUID generálása kisbetűs formában
GENERATED_UUID="$(uuidgen | tr '[:upper:]' '[:lower:]')"


nmcli connection delete "hot2" 2>/dev/null || true
sudo ip addr flush dev wlan0 2>/dev/null || true
sudo rm -f /run/rnm-dnsmasq-wlan0.pid 2>/dev/null || true
# Generáljuk a Netplan YAML-t
NETPLAN_FILE="/etc/netplan/01-robot-${ROBOT_SZAM}.yaml"
cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  wifis:
    NM-${GENERATED_UUID}:
      renderer: NetworkManager
      match:
        name: "wlan0"
      # IPv4 statikus beállítás
      dhcp4: no
      addresses: ["${ROBOT_IP}/24"]
      gateway4: "192.168.0.1"
      # Ha kell, engedélyezheted az IPv6 DHCP-t:
      # dhcp6: true
      access-points:
        "${ROBOT_SSID}":
          band: "2.4GHz"
          auth:
            key-management: "psk"
            password: "${WIFI_JELSZO}"
          mode: "ap"
      networkmanager:
        uuid: "${GENERATED_UUID}"
        name: "hot2"
EOF

echo "✔ Netplan konfiguráció létrehozva: $NETPLAN_FILE"
# Alkalmazzuk a Netplan-t
sudo netplan generate
# Ellenőrizd, hogy a szükséges változók léteznek
if [[ -z "$ROBOT_SZAM" || -z "$ROBOT_ID" ]]; then
    echo "❌ Hiba: A ROBOT_SZAM vagy ROBOT_ID változó nincs beállítva."
    exit 1
fi
sudo systemctl restart NetworkManager
sudo netplan apply
# BASHRC elérési út
BASHRC="$HOME/.bashrc"

# ROBOT_NUM sort cseréljük vagy hozzáadjuk
if grep -q "^ROBOT_NUM=" "$BASHRC"; then
    sed -i "s/^ROBOT_NUM=.*/ROBOT_NUM=\"$ROBOT_SZAM\"/" "$BASHRC"
else
    echo "ROBOT_NUM=\"$ROBOT_SZAM\"" >> "$BASHRC"
fi

# ROBOT_ID sort cseréljük vagy hozzáadjuk
if grep -q "^ROBOT_ID=" "$BASHRC"; then
    sed -i "s/^ROBOT_ID=.*/ROBOT_ID=\"$ROBOT_ID\"/" "$BASHRC"
else
    echo "ROBOT_ID=\"$ROBOT_ID\"" >> "$BASHRC"
fi

echo "✔ Robot változók beállítva a $BASHRC fájlban."

USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
sed -i '/^echo -e "robo_/d' "$USER_HOME/.bashrc"
echo "echo -e \"${ROBOT_ID} | \e[44m\$my_ip\e[0m | ${SZIN_HU} - ${SZIN_SSID}\"" >> "$USER_HOME/.bashrc"


# Összefoglaló
cat <<EOT

Konfiguráció elkészült!
  Config fájl: ${NETPLAN_FILE}
  SSID:       ${ROBOT_SSID}
  Jelszó:     ${WIFI_JELSZO}
  IP-cím:     ${ROBOT_IP}
  Hostname:   ${ROBOT_ID}
  UUID:       ${GENERATED_UUID}

Indítsd újra a rendszert, ha szükséges.
EOT
