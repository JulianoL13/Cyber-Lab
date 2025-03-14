# Cyber Lab Manager

Gerenciador de laboratório de infraestrutura utilizando Vagrant e VirtualBox, com foco em automação e praticidade.

⚠️ **Este projeto está em desenvolvimento (W.I.P - Work In Progress)** ⚠️

## 🚧 Próximos passos planejados:

- Integração completa com Ansible para provisionamento automatizado.
- Tornar o repositório mais personalizável para quem está clonando.
- Melhorias na documentação e usabilidade.

## 📋 Pré-requisitos

- Linux (Ubuntu, Debian, Fedora, CentOS, Arch Linux ou openSUSE)
- VirtualBox instalado
- Vagrant instalado
- Mínimo recomendado: 8GB RAM e 40-120GB espaço em disco (dependendo do uso)

## 🚀 Como usar

Clone o repositório:

```
git clone <url-do-repositorio>
cd cyber-lab-manager
```

Dê permissão de execução ao script principal:

```
chmod +x lab_manager.sh
```

Execute o gerenciador:

```
./lab_manager.sh
```

Escolha a opção desejada no menu interativo:

- **Configurar o ambiente**: instala dependências necessárias.
- **Iniciar VMs**: sobe as máquinas virtuais.
- **Parar VMs**: desliga as máquinas virtuais.
- **Verificar status**: verifica o estado atual das VMs.
- **Acessar VM via SSH**: conecta-se a uma VM específica.
- **Exibir informações de rede**: exibe IPs e configurações das VMs.
- **Destruir VMs**: remove completamente as máquinas virtuais.

## 🛠️ Estrutura atual

- 3 máquinas virtuais Ubuntu Trusty64
- Cada VM possui:
  - Interface NAT (acesso à internet)
  - Interface privada (comunicação interna)
  - Interface bridge (acesso externo)

## 🔮 Próximos passos planejados

- Integração completa com Ansible para provisionamento automatizado.
- Tornar o repositório mais personalizável para quem clonar.
- Suporte a múltiplos provedores além do VirtualBox.

## 🤝 Contribuições

Contribuições são bem-vindas! Consulte o arquivo [CONTRIBUTING.md](CONTRIBUTING.md) para mais detalhes.

## 📄 Licença

Este projeto está licenciado sob a licença MIT. Veja o arquivo [LICENSE.md](LICENSE.md) para mais detalhes.

