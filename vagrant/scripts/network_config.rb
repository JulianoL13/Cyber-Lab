module NetworkConfig
  
  DEFAULT_INTERFACE = `ip route | awk '/^default/ {printf "%s", $5; exit 0}'`
  
  
  def self.configure_private_network(node)
    node.vm.network "private_network", type: "dhcp"
  end
  
  def self.configure_public_network(node)
    node.vm.network "public_network", 
                    bridge: DEFAULT_INTERFACE.empty? ? nil : DEFAULT_INTERFACE,
                    use_dhcp_assigned_default_route: true
  end
  
  def self.bridge_config_script
    return <<-SHELL
      echo "Configurando interface bridge..."
      
      
      if ip link show eth2 > /dev/null 2>&1; then
        BRIDGE_IFACE="eth2"
      elif ip link show enp0s9 > /dev/null 2>&1; then
        BRIDGE_IFACE="enp0s9"
      else
        echo "Nenhuma interface bridge encontrada (tentou eth2 e enp0s9)!"
        exit 1
      fi
      
      echo "Interface bridge encontrada: $BRIDGE_IFACE"
      
      echo "Configurando DHCP na interface $BRIDGE_IFACE"
      sudo ip link set $BRIDGE_IFACE up
      sudo dhclient -r $BRIDGE_IFACE
      sudo dhclient $BRIDGE_IFACE
      
      IP=$(ip -4 addr show $BRIDGE_IFACE | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}')
      if [ -z "$IP" ]; then
        echo "Não foi possível obter IP via DHCP. Tentando configuração alternativa..."
        sudo ip link set $BRIDGE_IFACE up
        sudo dhclient $BRIDGE_IFACE
        
        IP=$(ip -4 addr show $BRIDGE_IFACE | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}')
        if [ ! -z "$IP" ]; then
          echo "Interface $BRIDGE_IFACE configurada com IP: $IP"
        else
          echo "Não foi possível obter IP para a interface $BRIDGE_IFACE"
        fi
      else
        echo "Interface $BRIDGE_IFACE configurada com IP: $IP"
      fi

      if [ -f /vagrant/scripts/provision_logs.sh ]; then
        bash /vagrant/scripts/provision_logs.sh
      fi
    SHELL
  end
end 