terraform {
    backend "azurerm" {
        resource_group_name  = "rg-terraform-state-tst"
        storage_account_name = "sttfstatemax1tst"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
        use_oidc            = true
        use_azuread_auth    = true
    }
}
