# We may want to create a new resource group for things relating to the cluster
# instead of using a data (1) / the same resource group used by the base infrastructure.
# That way we can give contributors access to the cluster things, without giving them
# access to base infrastructure.
resource "azurerm_resource_group" "main" {
  name     = "foobar"
  location = "Central US"
}

# If we want the nodes to belong to a particular subnet (which is part of a different resource group), we should
# indicate which resource group that subnet is in.
data "azurerm_resource_group" "nodes_resource_group" {
  name = "rg-foo-infra"
}

# As well as a data resource for that subnet.
data "azurerm_subnet" "nodes_subnet" {
  name                 = "kube-subnet"
  virtual_network_name = "vnet-foo"
  resource_group_name  = "rg-foo-infra"
}

data "azurerm_container_registry" "acr" {
  name                = "foobartest123"
  resource_group_name = "rg-foo-infra"
}

module "aks" {
  source  = "Exodus/aks/azurerm"
  version = "0.2.0"

  resource_group     = azurerm_resource_group.main
  cluster_name       = "foo-dev"
  kubernetes_version = "1.23.5"
  sku_tier           = "paid" # Prod clusters should have higher SLA on the control plane

  nodes_resource_group = data.azurerm_resource_group.nodes_resource_group
  nodes_subnet         = data.azurerm_subnet.nodes_subnet
  network_profile = {
    network_plugin = "azure"
  }

  enable_aad_admin_group         = true
  enable_aad_pod_identity_roles  = true
  enable_acr_integration         = true
  enable_log_analytics_workspace = true

  acr = azurerm_container_registry.acr

  default_node_pool = {
    name                         = "systempool"
    os_disk_type                 = "Ephemeral"
    os_disk_size_gb              = 200
    max_pods                     = 110
    enable_auto_scaling          = true
    min_count                    = 2
    max_count                    = 4
    vm_size                      = "Standard_D8ds_v4"
    orchestrator_version         = "1.23.5"
    only_critical_addons_enabled = true # We want to dedicate the default node pool to azure things / control plane
  }

  # This is for our applications, we may have multiple items in the map
  # Maybe there's a GPU specialized node pool, etc
  extra_node_pools = {
    apps1 = {
      enable_auto_scaling   = true
      enable_node_public_ip = false
      max_count             = 10
      max_pods              = 110
      min_count             = 1
      node_count            = 1
      node_taints           = []
      orchestrator_version  = "1.22.6"
      os_disk_type          = "Ephemeral"
      os_disk_size_gb       = 200
      os_type               = "Linux"
      vm_size               = "Standard_D8ds_v5"
    }
  }
}
