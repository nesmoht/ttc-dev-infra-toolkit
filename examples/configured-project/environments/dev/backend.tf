terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-shared"
    storage_account_name = "sttfstateshared001"
    container_name       = "tfstate"
    key                  = "dataplatform-dev.terraform.tfstate"
  }
}
