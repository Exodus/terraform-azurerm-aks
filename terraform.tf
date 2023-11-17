terraform {
  required_version = "~> 1.0"

  # experiments = [module_variable_optional_attrs]

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.81.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.29.0"
    }
  }
}
