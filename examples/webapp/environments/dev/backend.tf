terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-shd"
    storage_account_name = "sttfstateshd001"
    container_name       = "landing-zone"
    key                  = "webapp-dev.terraform.tfstate"
  }
}
