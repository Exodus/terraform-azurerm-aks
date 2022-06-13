# terraform-azurerm-aks

This terraform module deploys an AKS cluster with optional features:
- AAD Admin Group
- Integrate the cluster with an ACR
- Create the roles for [AAD Pod Identity](https://github.com/Azure/aad-pod-identity)
- Create a log analytics workspace for the cluster

Some inputs are objects, so either a `data` or `resource` are valid.

* If the the cluster and vnet do not share resource group, remember to follow: https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal?tabs=azure-cli#networking (1)

This module uses one experimental feature from Terraform called `module_variable_optional_attrs` which should be released soon (1.3?). Since it is current not completely stabilized, the use of this module requires the following as part of your terraform configuration:

```
terraform {
  experiments = [module_variable_optional_attrs]
}
```
## Example

```
data "azurerm_resource_group" "main" {
  name = "rg-dev"
}

data "azurerm_subnet" "nodes_subnet" {
  name                 = "kube"
  virtual_network_name = "dev"
  resource_group_name  = "dev-infra"
}

data "azurerm_container_registry" "acr" {
  name                = "foo-acr"
  resource_group_name = "rg-dev"
}

module "aks" {
  # source  = "github.com/Exodus/terraform-azurerm-aks?ref=v0.1.0"

  resource_group     = data.azurerm_resource_group.main
  cluster_name       = "dev"
  kubernetes_version = "1.23.5"

  nodes_subnet                  = data.azurerm_subnet.nodes_subnet

  enable_aad_admin_group         = true
  enable_aad_pod_identity_roles  = true
  enable_acr_integration         = true
  enable_log_analytics_workspace = true

  acr = data.azurerm_container_registry.acr

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