// To create Resource Group
resource "azurerm_resource_group" "DemoRG1" {
  name     = "DemoRG1"
  location = var.location
}

// to create virtaul machines
resource "azurerm_linux_virtual_machine" "demo-az-dev" {
  admin_password                  = "ignored-as-imported"
  admin_username                  = "azdev"
  disable_password_authentication = false
  location                        = "eastus"
  name                            = "demo-az-dev"
  network_interface_ids           = ["/subscriptions/id/resourceGroups/DemoRG1/providers/Microsoft.Network/networkInterfaces/demo-az-dev976"]
  resource_group_name             = "DemoRG1"
  size                            = "Standard_D2s_v3"
  boot_diagnostics {
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "canonical"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.res-9,
  ]
}
resource "azurerm_linux_virtual_machine" "demo-az-jenkins" {
  admin_password                  = "ignored-as-imported"
  admin_username                  = "azdev"
  disable_password_authentication = false
  location                        = "eastus"
  name                            = "demo-az-jenkins"
  network_interface_ids           = ["/subscriptions/id/resourceGroups/DemoRG1/providers/Microsoft.Network/networkInterfaces/demo-az-jenkins319"]
  resource_group_name             = "DemoRG1"
  size                            = "Standard_D2s_v3"
  boot_diagnostics {
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "canonical"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.res-11,
  ]
}

//to create ACR authentication
resource "azurerm_role_assignment" "role_acrpull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}
//to create ACR
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.DemoRG1.name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = true
}
//to create Azure kubernetes cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  location            = var.location
  resource_group_name = azurerm_resource_group.DemoRG1.name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name                = "system"
    node_count          = var.system_node_count
    vm_size             = "Standard_DS2_v2"
    type                = "VirtualMachineScaleSets"
  //  availability_zones  = [1, 2, 3]
    enable_auto_scaling = false
  }

// identity and network profile
  identity {
    type = "SystemAssigned"
  }

  network_profile {
    load_balancer_sku = "Standard"
    network_plugin    = "kubenet" 
  }
  lifecycle {
    ignore_changes = [
    ]
  }
}

// network resources

resource "azurerm_network_interface" "res-9" {
  enable_accelerated_networking = true
  location                      = "eastus"
  name                          = "demo-az-dev976"
  resource_group_name           = "DemoRG1"
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "/subscriptions/id/resourceGroups/DemoRG1/providers/Microsoft.Network/publicIPAddresses/demo-az-dev-ip"
    subnet_id                     = "/subscriptions/id/resourceGroups/DemoRG1/providers/Microsoft.Network/virtualNetworks/DemoRG1-vnet/subnets/default"
  }
  depends_on = [
    azurerm_public_ip.res-20,
    azurerm_subnet.res-23,
  ]
}
resource "azurerm_network_interface_security_group_association" "res-10" {
  network_interface_id      = "/subscriptions/id/resourceGroups/DemoRG1/providers/Microsoft.Network/networkInterfaces/demo-az-dev976"
  network_security_group_id = "/subscriptions/id/resourceGroups/DemoRG1/providers/Microsoft.Network/networkSecurityGroups/demo-az-dev-nsg"
  depends_on = [
    azurerm_network_interface.res-9,
    azurerm_network_security_group.res-13,
  ]
}
resource "azurerm_network_interface" "res-11" {
  enable_accelerated_networking = true
  location                      = "eastus"
  name                          = "demo-az-jenkins319"
  resource_group_name           = "DemoRG1"
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "/subscriptions/id/resourceGroups/DemoRG1/providers/Microsoft.Network/publicIPAddresses/demo-az-jenkins-ip"
    subnet_id                     = "/subscriptions/id/resourceGroups/DemoRG1/providers/Microsoft.Network/virtualNetworks/DemoRG1-vnet/subnets/default"
  }
  depends_on = [
    azurerm_public_ip.res-21,
    azurerm_subnet.res-23,
  ]
}
resource "azurerm_network_interface_security_group_association" "res-12" {
  network_interface_id      = "/subscriptions/id/resourceGroups/DemoRG1/providers/Microsoft.Network/networkInterfaces/demo-az-jenkins319"
  network_security_group_id = "/subscriptions/id/resourceGroups/DemoRG1/providers/Microsoft.Network/networkSecurityGroups/demo-az-jenkins-nsg"
  depends_on = [
    azurerm_network_interface.res-11,
    azurerm_network_security_group.res-17,
  ]
}
resource "azurerm_network_security_group" "res-13" {
  location            = "eastus"
  name                = "demo-az-dev-nsg"
  resource_group_name = "DemoRG1"
  depends_on = [
    azurerm_resource_group.DemoRG1,
  ]
}
resource "azurerm_network_security_rule" "res-14" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "3000"
  direction                   = "Inbound"
  name                        = "AllowAnyCustom3000Inbound"
  network_security_group_name = "demo-az-dev-nsg"
  priority                    = 310
  protocol                    = "*"
  resource_group_name         = "DemoRG1"
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-13,
  ]
}
resource "azurerm_network_security_rule" "res-15" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "5000-5001"
  direction                   = "Inbound"
  name                        = "AllowAnyCustom5000-5001Inbound"
  network_security_group_name = "demo-az-dev-nsg"
  priority                    = 320
  protocol                    = "*"
  resource_group_name         = "DemoRG1"
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-13,
  ]
}
resource "azurerm_network_security_rule" "res-16" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "22"
  direction                   = "Inbound"
  name                        = "SSH"
  network_security_group_name = "demo-az-dev-nsg"
  priority                    = 300
  protocol                    = "TCP"
  resource_group_name         = "DemoRG1"
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-13,
  ]
}
resource "azurerm_network_security_group" "res-17" {
  location            = "eastus"
  name                = "demo-az-jenkins-nsg"
  resource_group_name = "DemoRG1"
  depends_on = [
    azurerm_resource_group.DemoRG1,
  ]
}
resource "azurerm_network_security_rule" "res-18" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "8080"
  direction                   = "Inbound"
  name                        = "AllowAnyCustom8080Inbound"
  network_security_group_name = "demo-az-jenkins-nsg"
  priority                    = 310
  protocol                    = "*"
  resource_group_name         = "DemoRG1"
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-17,
  ]
}
resource "azurerm_network_security_rule" "res-19" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "22"
  direction                   = "Inbound"
  name                        = "SSH"
  network_security_group_name = "demo-az-jenkins-nsg"
  priority                    = 300
  protocol                    = "TCP"
  resource_group_name         = "DemoRG1"
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-17,
  ]
}
resource "azurerm_public_ip" "res-20" {
  allocation_method   = "Static"
  location            = "eastus"
  name                = "demo-az-dev-ip"
  resource_group_name = "DemoRG1"
  sku                 = "Standard"
  domain_name_label   = "azure-dev"
  depends_on = [
    azurerm_resource_group.DemoRG1,
  ]
}
resource "azurerm_public_ip" "res-21" {
  allocation_method   = "Static"
  location            = "eastus"
  name                = "demo-az-jenkins-ip"
  resource_group_name = "DemoRG1"
  sku                 = "Standard"
  domain_name_label   = "azure-jenkins"
  depends_on = [
    azurerm_resource_group.DemoRG1,
  ]
}
resource "azurerm_virtual_network" "res-22" {
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  name                = "DemoRG1-vnet"
  resource_group_name = "DemoRG1"
  depends_on = [
    azurerm_resource_group.DemoRG1,
  ]
}
resource "azurerm_subnet" "res-23" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "default"
  resource_group_name  = "DemoRG1"
  virtual_network_name = "DemoRG1-vnet"
  depends_on = [
    azurerm_virtual_network.res-22,
  ]
}
