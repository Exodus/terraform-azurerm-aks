resource "azurerm_resource_group" "main" {
  name     = "rg-foo-infra"
  location = "Central US"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-foo"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "nodes_subnet" {
  name                 = "kube-subnet"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_container_registry" "acr" {
  name                = "foobartest123"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
}

module "aks" {
  source  = "Exodus/aks/azurerm"
  version = "0.2.0"

  resource_group     = azurerm_resource_group.main
  cluster_name       = "foo-dev"
  kubernetes_version = "1.23.5"
  auto_upgrade       = "stable"

  nodes_subnet = azurerm_subnet.nodes_subnet

  enable_aad_admin_group         = true
  enable_aad_pod_identity_roles  = true
  enable_acr_integration         = true
  enable_log_analytics_workspace = true

  log_analytics_workspace_name = "foobar-la"

  acr = azurerm_container_registry.acr

  default_node_pool = {
    name                 = "systempool"
    os_disk_type         = "Ephemeral"
    os_disk_size_gb      = 200
    max_pods             = 110
    enable_auto_scaling  = true
    min_count            = 2
    max_count            = 4
    vm_size              = "Standard_D8ds_v4"
    orchestrator_version = "1.23.5"
  }
}
