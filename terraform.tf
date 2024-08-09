#----Tell terraform to use Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

#----Tell terraform to use Az cli auth
provider "azurerm" {
  features {
  }
}