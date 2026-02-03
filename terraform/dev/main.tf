terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 3.0"
        }
    }
}

provider "azurerm" {
    features {}
    use_oidc = true
}

data "azurerm_resource_group" "main" {
    name = "rg-max-dev"
}

resource "azurerm_virtual_network" "main" {
    name                = "vnet-demo-dev"
    address_space       = ["10.0.0.0/16"]
    location            = data.data.azurerm_resource_group.main.location
    resource_group_name = data.data.azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
    name                 = "snet-demo-dev"
    resource_group_name  = data.azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "main" {
    name                = "nic-vm-demo-dev"
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.main.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_linux_virtual_machine" "main" {
    name                            = "vm-demo-dev"
    resource_group_name             = data.azurerm_resource_group.main.name
    location                        = data.azurerm_resource_group.main.location
    size                            = "Standard_B1s"
    admin_username                  = "adminuser"
    admin_password                  = "P@ssw0rd123!"
    disable_password_authentication = false

    network_interface_ids = [
        azurerm_network_interface.main.id,
    ]

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts"
        version   = "latest"
    }
}
