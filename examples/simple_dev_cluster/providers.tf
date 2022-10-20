provider "azurerm" {
  features {}
  subscription_id = "e2daffb6-11cb-4f53-ae77-319aadde63fe"
}

provider "azuread" {
  tenant_id   = "6a844b32-ed76-47b2-b479-764994438a8c"
  environment = "global"
}
