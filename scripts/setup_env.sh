#!/bin/bash


GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


DISTRO=""
PKG_MANAGER=""
PKG_INSTALL=""
PKG_UPDATE=""


detect_distribution() {
  echo -e "${YELLOW}Detectando distribuição Linux...${NC}"
  
  if command -v apt-get &> /dev/null; then
    DISTRO="debian"
    PKG_MANAGER="apt-get"
    PKG_UPDATE="apt-get update"
    PKG_INSTALL="apt-get install -y"
    
    if command -v lsb_release &> /dev/null; then
      DISTRO_NAME=$(lsb_release -sd)
    elif [ -f /etc/os-release ]; then
      DISTRO_NAME=$(grep -oP '(?<=^PRETTY_NAME=")[^"]+' /etc/os-release)
    else
      DISTRO_NAME="Debian/Ubuntu"
    fi
    echo -e "${GREEN}Sistema detectado: $DISTRO_NAME${NC}"
    return 0
  fi
  
  if command -v dnf &> /dev/null; then
    DISTRO="fedora"
    PKG_MANAGER="dnf"
    PKG_UPDATE="dnf check-update || true"
    PKG_INSTALL="dnf install -y"
    
    if [ -f /etc/os-release ]; then
      DISTRO_NAME=$(grep -oP '(?<=^PRETTY_NAME=")[^"]+' /etc/os-release)
    else
      DISTRO_NAME="Fedora/RHEL"
    fi
    echo -e "${GREEN}Sistema detectado: $DISTRO_NAME${NC}"
    return 0
  fi
  
  if command -v yum &> /dev/null; then
    DISTRO="centos"
    PKG_MANAGER="yum"
    PKG_UPDATE="yum check-update || true"
    PKG_INSTALL="yum install -y"
    
    if [ -f /etc/os-release ]; then
      DISTRO_NAME=$(grep -oP '(?<=^PRETTY_NAME=")[^"]+' /etc/os-release)
    else
      DISTRO_NAME="CentOS/RHEL"
    fi
    echo -e "${GREEN}Sistema detectado: $DISTRO_NAME${NC}"
    return 0
  fi
  
  if command -v pacman &> /dev/null; then
    DISTRO="arch"
    PKG_MANAGER="pacman"
    PKG_UPDATE="pacman -Sy"
    PKG_INSTALL="pacman -S --noconfirm"
    
    if [ -f /etc/os-release ]; then
      DISTRO_NAME=$(grep -oP '(?<=^PRETTY_NAME=")[^"]+' /etc/os-release)
    else
      DISTRO_NAME="Arch Linux"
    fi
    echo -e "${GREEN}Sistema detectado: $DISTRO_NAME${NC}"
    return 0
  fi
  
  if command -v zypper &> /dev/null; then
    DISTRO="suse"
    PKG_MANAGER="zypper"
    PKG_UPDATE="zypper refresh"
    PKG_INSTALL="zypper install -y"
    
    if [ -f /etc/os-release ]; then
      DISTRO_NAME=$(grep -oP '(?<=^PRETTY_NAME=")[^"]+' /etc/os-release)
    else
      DISTRO_NAME="openSUSE"
    fi
    echo -e "${GREEN}Sistema detectado: $DISTRO_NAME${NC}"
    return 0
  fi
  
  echo -e "${RED}Não foi possível detectar a distribuição Linux.${NC}"
  echo -e "${RED}Este script suporta: Debian/Ubuntu, Fedora, CentOS, Arch Linux e openSUSE.${NC}"
  return 1
}

install_basic_packages() {
  echo -e "${YELLOW}Instalando pacotes básicos...${NC}"
  
  local PACKAGES=""
  
  case $DISTRO in
    debian)
      PACKAGES="curl wget net-tools iproute2 jq"
      ;;
    fedora|centos)
      PACKAGES="curl wget net-tools iproute jq"
      ;;
    arch)
      PACKAGES="curl wget net-tools iproute2 jq"
      ;;
    suse)
      PACKAGES="curl wget net-tools iproute2 jq"
      ;;
    *)
      echo -e "${RED}Distribuição não suportada para instalação de pacotes.${NC}"
      return 1
      ;;
  esac
  
  echo -e "${BLUE}Atualizando repositórios...${NC}"
  sudo $PKG_UPDATE
  
  echo -e "${BLUE}Instalando: $PACKAGES${NC}"
  sudo $PKG_INSTALL $PACKAGES
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Pacotes básicos instalados com sucesso.${NC}"
    return 0
  else
    echo -e "${RED}Falha ao instalar pacotes básicos.${NC}"
    return 1
  fi
}

check_vagrant() {
  if command -v vagrant &> /dev/null; then
    echo -e "${GREEN}Vagrant já está instalado:${NC}"
    vagrant --version
    return 0
  else
    echo -e "${YELLOW}Vagrant não está instalado.${NC}"
    return 1
  fi
}

check_virtualbox() {
  if command -v VBoxManage &> /dev/null; then
    echo -e "${GREEN}VirtualBox já está instalado:${NC}"
    VBoxManage --version
    return 0
  else
    echo -e "${YELLOW}VirtualBox não está instalado.${NC}"
    return 1
  fi
}

install_vagrant() {
  echo -e "${YELLOW}Instalando Vagrant...${NC}"
  
  case $DISTRO in
    debian)
      echo -e "${BLUE}Adicionando chave GPG do Vagrant...${NC}"
      curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
      
      echo -e "${BLUE}Adicionando repositório do Vagrant...${NC}"
      sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
      
      echo -e "${BLUE}Atualizando repositórios...${NC}"
      sudo apt-get update
      
      echo -e "${BLUE}Instalando Vagrant...${NC}"
      sudo apt-get install -y vagrant
      ;;
    
    fedora)
      echo -e "${BLUE}Instalando Vagrant via DNF...${NC}"
      sudo dnf install -y vagrant
      ;;
    
    centos)
      echo -e "${BLUE}Instalando dependências...${NC}"
      sudo yum install -y yum-utils
      
      echo -e "${BLUE}Adicionando repositório do Vagrant...${NC}"
      sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
      
      echo -e "${BLUE}Instalando Vagrant...${NC}"
      sudo yum -y install vagrant
      ;;
    
    arch)
      echo -e "${BLUE}Instalando Vagrant via Pacman...${NC}"
      sudo pacman -S --noconfirm vagrant
      ;;
    
    suse)
      echo -e "${BLUE}Instalando Vagrant via Zypper...${NC}"
      sudo zypper install -y vagrant
      ;;
    
    *)
      echo -e "${RED}Instalação automática do Vagrant não suportada para esta distribuição.${NC}"
      echo -e "${YELLOW}Por favor, instale o Vagrant manualmente:${NC}"
      echo "https://www.vagrantup.com/downloads"
      return 1
      ;;
  esac
  
  if command -v vagrant &> /dev/null; then
    echo -e "${GREEN}Vagrant instalado com sucesso:${NC}"
    vagrant --version
    return 0
  else
    echo -e "${RED}Falha ao instalar o Vagrant.${NC}"
    echo -e "${YELLOW}Por favor, instale o Vagrant manualmente:${NC}"
    echo "https://www.vagrantup.com/downloads"
    return 1
  fi
}

install_virtualbox() {
  echo -e "${YELLOW}Instalando VirtualBox...${NC}"
  
  case $DISTRO in
    debian)
      echo -e "${BLUE}Adicionando chave GPG do VirtualBox...${NC}"
      curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo apt-key add -
      
      echo -e "${BLUE}Adicionando repositório do VirtualBox...${NC}"
      sudo add-apt-repository "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib"
      
      echo -e "${BLUE}Atualizando repositórios...${NC}"
      sudo apt-get update
      
      echo -e "${BLUE}Instalando VirtualBox...${NC}"
      sudo apt-get install -y virtualbox-6.1
      ;;
    
    fedora)
      echo -e "${BLUE}Instalando dependências...${NC}"
      sudo dnf install -y @development-tools
      sudo dnf install -y kernel-devel kernel-headers dkms elfutils-libelf-devel qt5-qtx11extras
      
      echo -e "${BLUE}Adicionando repositório do VirtualBox...${NC}"
      sudo dnf config-manager --add-repo=https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo
      
      echo -e "${BLUE}Instalando VirtualBox...${NC}"
      sudo dnf install -y VirtualBox-6.1
      ;;
    
    centos)
      echo -e "${BLUE}Instalando dependências...${NC}"
      sudo yum install -y kernel-devel kernel-headers dkms make bzip2 perl
      
      echo -e "${BLUE}Adicionando repositório do VirtualBox...${NC}"
      sudo yum-config-manager --add-repo=https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo
      
      echo -e "${BLUE}Instalando VirtualBox...${NC}"
      sudo yum install -y VirtualBox-6.1
      ;;
    
    arch)
      echo -e "${BLUE}Instalando VirtualBox via Pacman...${NC}"
      sudo pacman -S --noconfirm virtualbox virtualbox-host-modules-arch
      
      echo -e "${BLUE}Carregando módulos do kernel...${NC}"
      sudo modprobe vboxdrv
      ;;
    
    suse)
      echo -e "${BLUE}Instalando VirtualBox via Zypper...${NC}"
      sudo zypper install -y virtualbox
      ;;
    
    *)
      echo -e "${RED}Instalação automática do VirtualBox não suportada para esta distribuição.${NC}"
      echo -e "${YELLOW}Por favor, instale o VirtualBox manualmente:${NC}"
      echo "https://www.virtualbox.org/wiki/Downloads"
      return 1
      ;;
  esac
  
  if command -v VBoxManage &> /dev/null; then
    echo -e "${GREEN}VirtualBox instalado com sucesso:${NC}"
    VBoxManage --version
    return 0
  else
    echo -e "${RED}Falha ao instalar o VirtualBox.${NC}"
    echo -e "${YELLOW}Por favor, instale o VirtualBox manualmente:${NC}"
    echo "https://www.virtualbox.org/wiki/Downloads"
    return 1
  fi
}

create_directories() {
  echo -e "${YELLOW}Criando diretórios necessários...${NC}"
  
  mkdir -p vagrant/tmp
  
  echo -e "${GREEN}Diretórios criados com sucesso.${NC}"
}

main() {
  echo -e "${BLUE}=== Configuração do Ambiente para Laboratório de Infraestrutura ===${NC}"
  
  detect_distribution || exit 1
  
  install_basic_packages
  
  echo -e "${YELLOW}Verificando se o Vagrant está instalado...${NC}"
  if ! check_vagrant; then
    read -p "Deseja instalar o Vagrant? (s/n): " install_vagrant_choice
    if [[ $install_vagrant_choice =~ ^[Ss]$ ]]; then
      install_vagrant
    else
      echo -e "${YELLOW}Você optou por não instalar o Vagrant.${NC}"
      echo -e "${RED}O Vagrant é necessário para este laboratório.${NC}"
      echo -e "${YELLOW}Por favor, instale o Vagrant manualmente:${NC}"
      echo "https://www.vagrantup.com/downloads"
    fi
  fi
  
  echo -e "${YELLOW}Verificando se o VirtualBox está instalado...${NC}"
  if ! check_virtualbox; then
    read -p "Deseja instalar o VirtualBox? (s/n): " install_virtualbox_choice
    if [[ $install_virtualbox_choice =~ ^[Ss]$ ]]; then
      install_virtualbox
    else
      echo -e "${YELLOW}Você optou por não instalar o VirtualBox.${NC}"
      echo -e "${RED}O VirtualBox é necessário para este laboratório.${NC}"
      echo -e "${YELLOW}Por favor, instale o VirtualBox manualmente:${NC}"
      echo "https://www.virtualbox.org/wiki/Downloads"
    fi
  fi
  
  create_directories
  
  if check_vagrant && check_virtualbox; then
    echo -e "${GREEN}Ambiente configurado com sucesso!${NC}"
    echo -e "${YELLOW}Para iniciar as VMs, execute:${NC}"
    echo "cd vagrant && vagrant up"
  else
    echo -e "${RED}Algumas dependências não foram instaladas.${NC}"
    echo -e "${YELLOW}Por favor, instale as dependências faltantes e execute este script novamente.${NC}"
  fi
}

main 