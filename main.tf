resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# Cria rede virtual
resource "azurerm_virtual_network" "vnet" {
  name                = "acme-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Cria subnets
resource "azurerm_subnet" "subnet" {
  name                 = "acme-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.10.0/24"]
}

# Cria IPs públicos
resource "azurerm_public_ip" "myPubIP" {
  count               = var.number_resources
  name                = "myPublicIP-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Cria SG para SSH e HTTP (para VMs de índice par)
resource "azurerm_network_security_group" "nsg_ssh_http" {
  name                = "myNetworkSecurityGroupSSH_HTTP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Cria SG para SSH (para VMs de índice ímpar)
resource "azurerm_network_security_group" "nsg_ssh" {
  name                = "myNetworkSecurityGroupSSH"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Cria NIC
resource "azurerm_network_interface" "nic" {
  #depends_on          = [azurerm_public_ip.myPubIP]
  count               = var.number_resources
  name                = "myNIC-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic_${count.index + 1}_configuration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myPubIP[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "nicNSG_ssh_http" {
  #depends_on                = [azurerm_network_interface.nic]
  for_each                  = { for idx, nic in azurerm_network_interface.nic : idx => nic if idx == 0 }
  network_interface_id      = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg_ssh_http.id
}

resource "azurerm_network_interface_security_group_association" "nicNSG_ssh" {
  #depends_on                = [azurerm_network_interface.nic]
  for_each                  = { for idx, nic in azurerm_network_interface.nic : idx => nic if idx == 1 }
  network_interface_id      = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg_ssh.id
}

# Cria nome genérico para a chave ssh
resource "random_pet" "ssh_key_name" {
  #depends_on = [azurerm_network_interface.nic]
  prefix     = "ssh"
  separator  = ""
}

# Gera uma chave pública e uma privada
resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

# Associa o nome da chave criada aleatoriamente com a chave pública
resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name.id
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
}

# Salva a chave pública no diretório principal
resource "local_file" "private_key" {
  content         = azapi_resource_action.ssh_public_key_gen.output.privateKey
  filename        = "private_key.pem"
  file_permission = "0600"
}

# Cria a máquina virtual
resource "azurerm_linux_virtual_machine" "myVM" {
  count                 = var.number_resources
  name                  = "acmeVM${count.index + 1}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "acmeVM-${count.index + 1}"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }
}

# Gerar um inventario das VMs
resource "local_file" "inventory" {
 #depends_on = [azurerm_linux_virtual_machine.myVM]
  content = templatefile("inventory.tpl", {
    web_ip       = azurerm_linux_virtual_machine.myVM[0].public_ip_address,
    db_ip        = azurerm_linux_virtual_machine.myVM[1].public_ip_address,
    ansible_user = var.username
  })
  filename = "./ansible/inventory.ini"
}

# Outputs
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "virtual_network_name" {
  value = azurerm_virtual_network.vnet.name
}

output "subnet_name" {
  value = azurerm_subnet.subnet.name
}

output "linux_virtual_machine_names" {
  value = [for s in azurerm_linux_virtual_machine.myVM : s.name]
}

output "linux_virtual_machine_ips" {
  value = [for s in azurerm_linux_virtual_machine.myVM : s.public_ip_address]
}