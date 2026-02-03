terraform {
    backend "azurerm" {
        resource_group_name  = "rg-terraform-state-dev"
        storage_account_name = "sttfstatemax1dev"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
        use_oidc             = true
    }
}
