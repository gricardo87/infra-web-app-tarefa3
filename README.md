# Infraestrutura para Aplicação Web da Acme SA

Este projeto demonstra a criação e configuração de uma infraestrutura para uma aplicação web utilizando Terraform e Ansible. A infraestrutura consiste em uma rede virtual, subnet, VMs, e as configurações necessárias para suportar os requisitos da aplicação.

## Visão Geral do Projeto

O objetivo deste projeto é criar e configurar uma infraestrutura para a aplicação web da Acme SA. A infraestrutura inclui os seguintes componentes e configurações:

### Terraform

- **Rede Virtual (VNet)**
  - Nome: `acme-vnet`
  - Espaço de Endereçamento: `10.0.0.0/16`
  
- **Subnet**
  - Nome: `acme-subnet`
  - Espaço de Endereçamento: `10.0.10.0/24`
  
- **Máquinas Virtuais**
  - `acmeVM1`
    - Usuário administrador: `acmeadmin`
    - IP público anexado
    - Acessível via SSH (porta 22)
    - Acessível via HTTP (porta 80)
  - `acmeVM2`
    - Usuário administrador: `acmeadmin`
    - IP público anexado
    - Acessível via SSH (porta 22)

- **Chave SSH**
  - As duas VMs serão acessíveis através de uma mesma chave privada.

- **Arquivo de Inventário Ansible**
  - Ao final do provisionamento das VMs, um arquivo de inventário Ansible será gerado com a `acmeVM1` no grupo `web` e a `acmeVM2` no grupo `db`.

### Ansible

- **Configuração do Grupo `web`**
  - Instalação do pacote `nginx`
  - Habilitação e inicialização do serviço `nginx`
  - Criação do arquivo `index.html` em `/var/www/html/` com o conteúdo da variável `ansible_hostname`
  - O arquivo `index.html` terá permissões 0644, proprietário `root` e grupo `root`.

- **Configuração do Grupo `db`**
  - Instalação do pacote `postgres`
  - Habilitação e inicialização do serviço `postgres`

- **Configuração Comum a Todos os Grupos**
  - Criação do usuário `acmeuser` com diretório home e senha `aulapuc1234`

### Datadog

- **Instalação do Agente Datadog**
  - O agente da Datadog será instalado e habilitado em todas as VMs.

## Avaliação

A avaliação deste projeto será baseada nos seguintes critérios:

- Completude dos itens descritos acima
- Qualidade do uso de variáveis e índices (por exemplo, uso de `count` no Terraform)
- Organização e melhores práticas dos playbooks Ansible e planos Terraform

## Estrutura do Projeto

- `main.tf`: Arquivo principal do Terraform para definir a infraestrutura.
- `ansible/`: Diretório contendo os playbooks Ansible.
  - `configure.yml`: Playbook principal para configuração das VMs.
  - `datadog.yml`: Playbook principal para configuração dos agents do datadog.
- `inventory.ini`: Arquivo de inventário Ansible gerado ao final do provisionamento.

## Como Executar

1. Clone este repositório.
2. Configure as credenciais necessárias para provisionar a infraestrutura no provedor de nuvem.
3. Execute `terraform init` e `terraform apply` para criar a infraestrutura.
4. Após o provisionamento, navegue até o diretório `ansible/` e execute `ansible-playbook -i inventory.ini configure.yml datadog.yml` para configurar as VMs.

## Conclusão

Este projeto demonstra a criação e configuração de uma infraestrutura completa para uma aplicação web utilizando Terraform e Ansible, seguindo as melhores práticas e garantindo uma configuração consistente e reproduzível.
