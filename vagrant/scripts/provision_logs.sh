#!/bin/bash

OUTPUT_DIR="/vagrant/tmp"
mkdir -p $OUTPUT_DIR/logs/network
mkdir -p $OUTPUT_DIR/logs/disk

HOSTNAME=$(hostname)

NETWORK_INFO_FILE="$OUTPUT_DIR/logs/network/${HOSTNAME}_network_info.txt"
DISK_INFO_FILE="$OUTPUT_DIR/logs/disk/${HOSTNAME}_disk_info.txt"

echo "============================================" > $NETWORK_INFO_FILE
echo "Interfaces de rede e seus IPs para $HOSTNAME:" >> $NETWORK_INFO_FILE
echo "============================================" >> $NETWORK_INFO_FILE

sleep 5

for iface in eth1 eth2 enp0s8 enp0s9; do
  if ip link show $iface &>/dev/null; then
    echo "Renovando DHCP para $iface..." >> $NETWORK_INFO_FILE
    sudo dhclient -r $iface
    sudo dhclient $iface
  fi
done

for iface in $(ls /sys/class/net); do
  echo "Interface: $iface" >> $NETWORK_INFO_FILE
  ip addr show $iface | grep 'inet ' >> $NETWORK_INFO_FILE || echo "Sem IP configurado" >> $NETWORK_INFO_FILE
  echo "--------------------------------------------" >> $NETWORK_INFO_FILE
done

echo "============================================" >> $NETWORK_INFO_FILE
echo "Tabela de rotas:" >> $NETWORK_INFO_FILE
echo "============================================" >> $NETWORK_INFO_FILE
ip route >> $NETWORK_INFO_FILE
echo "--------------------------------------------" >> $NETWORK_INFO_FILE

NAT_IP=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1 || ip -4 addr show enp0s3 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
PRIVATE_IP=$(ip -4 addr show eth1 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1 || ip -4 addr show enp0s8 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
BRIDGE_IP=$(ip -4 addr show eth2 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1 || ip -4 addr show enp0s9 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)

cat > "$OUTPUT_DIR/${HOSTNAME}_ips.json" << EOF
{
  "hostname": "$HOSTNAME",
  "nat_ip": "$NAT_IP",
  "private_ip": "$PRIVATE_IP",
  "bridge_ip": "$BRIDGE_IP"
}
EOF

echo "Informações de rede salvas em $NETWORK_INFO_FILE"
echo "IPs salvos em $OUTPUT_DIR/${HOSTNAME}_ips.json"

if [ ! -z "$BRIDGE_IP" ]; then
  echo "Esta VM ($HOSTNAME) está acessível via IP bridge: $BRIDGE_IP"
elif [ ! -z "$PRIVATE_IP" ]; then
  echo "Esta VM ($HOSTNAME) está acessível via IP privado: $PRIVATE_IP"
else
  echo "AVISO: Não foi possível determinar um IP acessível para esta VM ($HOSTNAME)"
fi

echo "============================================" > $DISK_INFO_FILE
echo "Informações de disco:" >> $DISK_INFO_FILE
echo "============================================" >> $DISK_INFO_FILE
df -h / >> $DISK_INFO_FILE
echo "--------------------------------------------" >> $DISK_INFO_FILE