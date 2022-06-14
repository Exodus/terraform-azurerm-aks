data "azurerm_client_config" "current" {}

# AAD K8s Cluster Admin Group in AAD
resource "azuread_group" "main" {
  count                   = var.enable_aad_admin_group ? 1 : 0
  display_name            = "${var.cluster_name}-clusteradmin"
  security_enabled        = true
  prevent_duplicate_names = true
}

# The Microsoft Controlled node resource group, used in case no subnet was selected for nodes
data "azurerm_resource_group" "mc_nodes_rg" {
  name = azurerm_kubernetes_cluster.main.node_resource_group
}

# K8s cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                      = var.cluster_name
  resource_group_name       = var.resource_group.name
  location                  = var.resource_group.location
  dns_prefix                = var.cluster_name
  kubernetes_version        = var.kubernetes_version
  automatic_channel_upgrade = var.auto_upgrade

  network_profile {
    network_plugin     = var.network_profile.network_plugin
    service_cidr       = var.network_profile.service_cidr
    dns_service_ip     = var.network_profile.dns_service_ip
    docker_bridge_cidr = var.network_profile.docker_bridge_cidr
  }

  default_node_pool {
    name                         = var.default_node_pool.name
    only_critical_addons_enabled = var.default_node_pool.only_critical_addons_enabled
    min_count                    = var.default_node_pool.min_count
    max_count                    = var.default_node_pool.max_count
    vm_size                      = var.default_node_pool.vm_size
    os_disk_type                 = var.default_node_pool.os_disk_type // https://docs.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    max_pods                     = var.default_node_pool.max_pods
    enable_auto_scaling          = var.default_node_pool.enable_auto_scaling
    vnet_subnet_id               = var.nodes_subnet.id
    orchestrator_version         = var.default_node_pool.orchestrator_version
  }

  identity {
    type = var.identity_type
  }

  azure_active_directory_role_based_access_control {
    managed                = var.enable_aad_admin_group
    admin_group_object_ids = var.enable_aad_admin_group == true ? [azuread_group.main[0].id] : null
  }

  sku_tier = var.sku_tier

  dynamic "oms_agent" {
    for_each = var.enable_log_analytics_workspace ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id
    }
  }
}

# Support to multiple node pools
resource "azurerm_kubernetes_cluster_node_pool" "main" {
  for_each              = var.extra_node_pools
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  name                  = each.value.os_type == "Windows" ? substr(each.key, 0, 6) : substr(each.key, 0, 12) # If os_type = Windows the name cannot be longer than 6 characters.
  node_count            = each.value.node_count
  vm_size               = each.value.vm_size
  enable_auto_scaling   = each.value.enable_auto_scaling
  max_pods              = each.value.max_pods
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_type               = each.value.os_type
  os_sku                = each.value.os_sku
  orchestrator_version  = each.value.orchestrator_version
  vnet_subnet_id        = try(var.nodes_subnet.id, null)
  node_taints           = each.value.node_taints
  min_count             = each.value.min_count
  max_count             = each.value.max_count
}

###
# Configure the Managed Identity Permissions
# If we've selected a specific subnet for the node pools, we want the AKS cluster and the node pool
# to be able to create a Load Balancer, or for any AAD Pod Identities to access storage
# in that subnet's resource group
###

# Required for creating load balancers in the vnets resource group
# For the case where the subnet's resource group is different from the main resource group used
resource "azurerm_role_assignment" "network_contributor" {
  count                = var.nodes_resource_group != null ? 1 : 0
  scope                = var.nodes_resource_group.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

# Required for manipulating storage accounts in the resource group
resource "azurerm_role_assignment" "storage_account_contributor" {
  scope                = var.resource_group.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

# If the resource group supplied is different from the resource group where the nodes are
# we also give the MIO role in that resource group in case that's where the MI live
resource "azurerm_role_assignment" "pod_identity_mio_rg" {
  scope                = var.resource_group.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "pod_identity_mio" {
  scope                = data.azurerm_resource_group.mc_nodes_rg.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "pod_identity_vmc" {
  scope                = data.azurerm_resource_group.mc_nodes_rg.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# Grant AcrPull to the Kubernetes Identity
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.enable_acr_integration ? 1 : 0
  scope                = var.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_log_analytics_workspace ? 1 : 0
  name                = var.cluster_name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_retention_in_days
}

resource "azurerm_log_analytics_solution" "main" {
  count                 = var.enable_log_analytics_workspace ? 1 : 0
  solution_name         = "ContainerInsights"
  location              = var.resource_group.location
  resource_group_name   = var.resource_group.name
  workspace_resource_id = azurerm_log_analytics_workspace.main[0].id
  workspace_name        = azurerm_log_analytics_workspace.main[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}
