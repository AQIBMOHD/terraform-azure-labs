terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # now here i add Azure Backend where I store terraform.tfstate file which i created maually
  backend "azurerm"{
    resource_group_name = "rg-terraform-state"
    storage_account_name = "aqibtfstate2000"
    container_name = "tfstate"
    key = "dev.terraform.tfstate"
  }
  
}

provider "azurerm" {
  features {}
}

