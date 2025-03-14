#!/bin/bash

INPUT_DIR="vagrant/tmp"
INVENTORY_FILE="inventory.yml"

if [ ! -d "$INPUT_DIR" ]; then
  echo "Diretório $INPUT_DIR não encontrado. Execute 'vagrant up' primeiro."
  exit 1
fi

cat > $INVENTORY_FILE << EOF
---
all:
  children:
    vagrant_vms:
      hosts:
EOF

for IP_FILE in $INPUT_DIR/*_ips.json; do
  if [ -f "$IP_FILE" ]; then
    HOSTNAME=$(grep -o '"hostname": "[^"]*"' $IP_FILE | cut -d'"' -f4)
    BRIDGE_IP=$(grep -o '"bridge_ip": "[^"]*"' $IP_FILE | cut -d'"' -f4)
    
    ANSIBLE_HOST=${BRIDGE_IP}
    
    cat >> $INVENTORY_FILE << EOF
        $HOSTNAME:
          ansible_host: $ANSIBLE_HOST
          ansible_user: vagrant
          ansible_ssh_private_key_file: vagrant/.vagrant/machines/$HOSTNAME/virtualbox/private_key
EOF
  fi
done

echo "Inventário Ansible gerado em $INVENTORY_FILE"
echo "Para usar com o Ansible: ansible-playbook -i $INVENTORY_FILE seu_playbook.yml"