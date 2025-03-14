#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

BASE_DIR=$(pwd)
VAGRANT_DIR="${BASE_DIR}/vagrant"

show_header() {
  clear
  echo -e "${BLUE}=================================================${NC}"
  echo -e "${BLUE}   Gerenciador do Laboratório de Infraestrutura   ${NC}"
  echo -e "${BLUE}=================================================${NC}"
  echo ""
}

check_environment() {
  if [ ! -d "$VAGRANT_DIR" ]; then
    echo -e "${RED}Diretório Vagrant não encontrado. Execute a configuração do ambiente primeiro.${NC}"
    return 1
  fi
  
  if ! command -v vagrant &> /dev/null; then
    echo -e "${RED}Vagrant não está instalado. Execute a configuração do ambiente primeiro.${NC}"
    return 1
  fi
  
  if ! command -v VBoxManage &> /dev/null; then
    echo -e "${RED}VirtualBox não está instalado. Execute a configuração do ambiente primeiro.${NC}"
    return 1
  fi
  
  return 0
}

setup_environment() {
  show_header
  echo -e "${YELLOW}Configurando o ambiente...${NC}"
  echo ""
  
  bash "${BASE_DIR}/scripts/setup_env.sh"
  
  echo ""
  echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
  read
}

start_vms() {
  show_header
  echo -e "${YELLOW}Iniciando as máquinas virtuais...${NC}"
  echo ""
  
  if ! check_environment; then
    echo ""
    echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
    read
    return 1
  fi
  
  cd "$VAGRANT_DIR"
  vagrant up
  
  echo ""
  echo -e "${GREEN}Gerando inventário Ansible...${NC}"
  cd "$BASE_DIR"
  bash "${BASE_DIR}/scripts/generate_inventory.sh"
  
  echo ""
  echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
  read
}

stop_vms() {
  show_header
  echo -e "${YELLOW}Parando as máquinas virtuais...${NC}"
  echo ""
  
  if ! check_environment; then
    echo ""
    echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
    read
    return 1
  fi
  
  cd "$VAGRANT_DIR"
  vagrant halt
  
  echo ""
  echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
  read
}

check_status() {
  show_header
  echo -e "${YELLOW}Verificando status das máquinas virtuais...${NC}"
  echo ""
  
  if ! check_environment; then
    echo ""
    echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
    read
    return 1
  fi
  
  cd "$VAGRANT_DIR"
  vagrant status
  
  echo ""
  echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
  read
}

ssh_to_vm() {
  show_header
  echo -e "${YELLOW}Acessando máquina virtual via SSH...${NC}"
  echo ""
  
  if ! check_environment; then
    echo ""
    echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
    read
    return 1
  fi
  
  cd "$VAGRANT_DIR"
  
  echo -e "${CYAN}Máquinas virtuais disponíveis:${NC}"
  vagrant status | grep -E 'node[0-9]+' | awk '{print $1, $2}'
  echo ""
  
  echo -e "${YELLOW}Digite o nome da VM para acessar (ex: node1):${NC}"
  read vm_name
  
  if [ -z "$vm_name" ]; then
    echo -e "${RED}Nome da VM não pode ser vazio.${NC}"
  else
    echo -e "${GREEN}Conectando à VM $vm_name...${NC}"
    vagrant ssh "$vm_name"
  fi
  
  echo ""
  echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
  read
}

destroy_vms() {
  show_header
  echo -e "${RED}ATENÇÃO: Esta operação irá destruir todas as máquinas virtuais!${NC}"
  echo -e "${YELLOW}Todos os dados não persistidos serão perdidos.${NC}"
  echo ""
  
  if ! check_environment; then
    echo ""
    echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
    read
    return 1
  fi
  
  echo -e "${YELLOW}Tem certeza que deseja destruir todas as VMs? (s/N):${NC}"
  read confirm
  
  if [[ $confirm =~ ^[Ss]$ ]]; then
    cd "$VAGRANT_DIR"
    vagrant destroy -f
    echo -e "${GREEN}Todas as VMs foram destruídas.${NC}"
  else
    echo -e "${BLUE}Operação cancelada.${NC}"
  fi
  
  echo ""
  echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
  read
}

show_network_info() {
  show_header
  echo -e "${YELLOW}Informações de rede das máquinas virtuais...${NC}"
  echo ""
  
  if ! check_environment; then
    echo ""
    echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
    read
    return 1
  fi
  
  if [ ! -d "${VAGRANT_DIR}/tmp" ]; then
    echo -e "${RED}Diretório de informações de rede não encontrado.${NC}"
    echo -e "${YELLOW}As VMs estão em execução? Execute 'Iniciar VMs' primeiro.${NC}"
    echo ""
    echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
    read
    return 1
  fi
  
  echo -e "${CYAN}IPs das máquinas virtuais:${NC}"
  echo -e "${BLUE}----------------------------------------${NC}"
  
  for IP_FILE in ${VAGRANT_DIR}/tmp/*_ips.json; do
    if [ -f "$IP_FILE" ]; then
      HOSTNAME=$(grep -o '"hostname": "[^"]*"' $IP_FILE | cut -d'"' -f4)
      NAT_IP=$(grep -o '"nat_ip": "[^"]*"' $IP_FILE | cut -d'"' -f4)
      PRIVATE_IP=$(grep -o '"private_ip": "[^"]*"' $IP_FILE | cut -d'"' -f4)
      BRIDGE_IP=$(grep -o '"bridge_ip": "[^"]*"' $IP_FILE | cut -d'"' -f4)
      
      echo -e "${GREEN}VM: $HOSTNAME${NC}"
      echo -e "  NAT IP:     ${YELLOW}$NAT_IP${NC}"
      echo -e "  Private IP: ${YELLOW}$PRIVATE_IP${NC}"
      echo -e "  Bridge IP:  ${YELLOW}$BRIDGE_IP${NC}"
      echo -e "${BLUE}----------------------------------------${NC}"
    fi
  done
  
  echo ""
  echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
  read
}

while true; do
  show_header
  
  echo -e "${CYAN}Escolha uma opção:${NC}"
  echo -e "${BLUE}----------------------------------------${NC}"
  echo -e "  ${GREEN}1)${NC} Configurar ambiente (instalar dependências)"
  echo -e "  ${GREEN}2)${NC} Iniciar VMs"
  echo -e "  ${GREEN}3)${NC} Parar VMs"
  echo -e "  ${GREEN}4)${NC} Verificar status das VMs"
  echo -e "  ${GREEN}5)${NC} Acessar VM via SSH"
  echo -e "  ${GREEN}6)${NC} Exibir informações de rede"
  echo -e "  ${RED}7)${NC} Destruir VMs"
  echo -e "  ${YELLOW}0)${NC} Sair"
  echo -e "${BLUE}----------------------------------------${NC}"
  echo ""
  
  read -p "Opção: " option
  
  case $option in
    1)
      setup_environment
      ;;
    2)
      start_vms
      ;;
    3)
      stop_vms
      ;;
    4)
      check_status
      ;;
    5)
      ssh_to_vm
      ;;
    6)
      show_network_info
      ;;
    7)
      destroy_vms
      ;;
    0)
      show_header
      echo -e "${GREEN}Obrigado por usar o Gerenciador do Laboratório de Infraestrutura!${NC}"
      echo ""
      exit 0
      ;;
    *)
      echo -e "${RED}Opção inválida!${NC}"
      sleep 2
      ;;
  esac
done 