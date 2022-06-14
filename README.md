# terraform-azurerm-aks

This terraform module deploys an AKS cluster with optional features:
- AAD Admin Group
- Integrate the cluster with an ACR
- Create the roles for [AAD Pod Identity](https://github.com/Azure/aad-pod-identity)
- Create a log analytics workspace for the cluster

Some inputs are objects, so either a `data` or `resource` are valid.

**Note:** If the the cluster and vnet do not share resource group, provide the `nodes_resource_group` input. This follows: https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal?tabs=azure-cli#networking and will assign the Network Contributor role to the cluster's identity in that resource group. This scenario is typical in more complex terraform scenarios, where you've separated state/concern of the base network infrastructure from its utilization in separate resource groups.

This module uses one experimental feature from Terraform called `module_variable_optional_attrs` which should be released soon (1.3?). Since it is current not completely stabilized, the use of this module requires the following as part of your terraform configuration:

```
terraform {
  experiments = [module_variable_optional_attrs]
}
```

## Considerations

### Networking
Ideally, you want separation of concerns, between base infrastructure and utilization of that base infrastructure. Separating the terraform code that creates the base infra (resource groups, vnet, subnets) from something like a kubernetes cluster and other applications.

You might want to allow (n) amount of developers to create clusters in a particular virtual network, but not want them to directly control the virtual networks.

### Defaults

There are good defaults, but some tie resources to each other. As an example of this, if you do not set the log_analytics_workspace_name, it will use the same name as the cluster (tying them), so, if you change the cluster name (which will recreate the cluster) it will recreate the log analytics workspace (since it's name changed). If your intention is to conserve the workspace and it's analytics when changing the cluster name, give the workspace a name.

## Example

### Production Ready Cluster
```
data "azurerm_resource_group" "main" {
  name = "rg-foo-app"
}

data "azurerm_subnet" "nodes_subnet" {
  name                 = "kube"
  virtual_network_name = "vnet-foo"
  resource_group_name  = "rg-foo-infra"
}

data "azurerm_container_registry" "acr" {
  name                = "foobar"
  resource_group_name = "rg-foo-app"
}

module "aks" {
  source  = "Exodus/aks/azurerm"
  version = "0.1.0"

  resource_group     = data.azurerm_resource_group.main
  cluster_name       = "foo-prod"
  kubernetes_version = "1.23.5"
  sku_tier           = "paid"

  nodes_subnet                  = data.azurerm_subnet.nodes_subnet

  enable_aad_admin_group         = true
  enable_aad_pod_identity_roles  = true
  enable_acr_integration         = true
  enable_log_analytics_workspace = true

  acr = data.azurerm_container_registry.acr

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
    only_critical_addons_enabled = true
  }

  extra_node_pools = {
    apps1 = {
      enable_auto_scaling   = true
      enable_node_public_ip = false
      max_count             = 10
      max_pods              = 110
      min_count             = 1
      node_count            = 1
      node_taints           = []
      orchestrator_version  = "1.23.5"
      os_disk_type          = "Ephemeral"
      os_disk_size_gb       = 200
      os_type               = "Linux"
      vm_size               = "Standard_D8ds_v5"
    }
  }
}
```

### Dev Cluster 💻
```
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
  # source  = "Exodus/aks/azurerm"
  # version = "0.1.0"
  source = "../../../../terraform-azurerm-aks"

  resource_group     = azurerm_resource_group.main
  cluster_name       = "foo-dev"
  kubernetes_version = "1.23.5"
  auto_upgrade       = "stable"

  nodes_subnet = azurerm_subnet.nodes_subnet
  network_profile = {
    network_plugin = "azure"
  }

  enable_aad_admin_group         = true
  enable_aad_pod_identity_roles  = true
  enable_acr_integration         = true
  enable_log_analytics_workspace = true

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
```