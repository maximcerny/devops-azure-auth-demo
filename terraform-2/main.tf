terraform {
    required_version = ">= 1.0"

    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 3.0"
        }
    }
}

provider "azurerm" {
    features {}
    use_oidc                   = true
    skip_provider_registration = true
}

data "azurerm_resource_group" "main" {
    name = var.resource_group_name
}

resource "azurerm_virtual_network" "main" {
    name                = "vnet-demo-${var.environment}"
    address_space       = var.vnet_address_space
    location            = var.location
    resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
    name                 = "snet-demo-${var.environment}"
    resource_group_name  = data.azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = var.subnet_address_prefixes
}

resource "azurerm_network_interface" "main" {
    name                = "nic-vm-demo-${var.environment}"
    location            = var.location
    resource_group_name = data.azurerm_resource_group.main.name

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.main.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_linux_virtual_machine" "main" {
    name                            = "vm-demo-${var.environment}"
    resource_group_name             = data.azurerm_resource_group.main.name
    location                        = var.location
    size                            = var.vm_size
    admin_username                  = var.admin_username
    admin_password                  = var.admin_password
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
