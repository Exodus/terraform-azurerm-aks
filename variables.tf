variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "resource_group" {
  description = "The name of a new or existing resource group to create the AKS cluster under. Expects a `resource` or `data` of `azurerm_resource_group`"
  type = object({
    id       = optional(string)
    name     = string
    location = string
  })
}

variable "nodes_subnet" {
  description = "The name of an existing subnet where the AKS cluster nodes will be deployed. Expects a `data` of `azurerm_subnet`"
  type = object({
    id                   = optional(string)
    name                 = string
    virtual_network_name = string
    resource_group_name  = string
  })
  default = null
}

variable "vnet_resource_group" {
  description = "Set if the nodes_subnet is in a different resource group from the main resource_group. Expects a `resource` or `data` of `azurerm_resource_group`"
  type = object({
    id       = optional(string)
    name     = string
    location = string
  })
  default = null
}

variable "kubernetes_version" {
  description = "Version of Kubernetes specified when creating the AKS managed cluster."
  type        = string
  default     = null
}

variable "auto_upgrade" {
  description = "Kubernetes Automatic Channel Upgrades."
  type        = string
  default     = "none"
}

variable "sku_tier" {
  description = "The SKU Tier that should be used for this Kubernetes Cluster. Possible values are Free and Paid (which includes the Uptime SLA). Defaults to Free."
  type        = string
  default     = "Free"
}

variable "network_profile" {
  type = object({
    network_plugin     = string
    service_cidr       = optional(string)
    dns_service_ip     = optional(string)
    docker_bridge_cidr = optional(string)
  })
  default = {
    network_plugin = "azure"
  }

  validation {
    condition = (
      var.network_profile.service_cidr != null ||
      var.network_profile.dns_service_ip != null ||
      var.network_profile.docker_bridge_cidr != null ?
      can(join(",", [var.network_profile.service_cidr, var.network_profile.dns_service_ip, var.network_profile.docker_bridge_cidr]))
      : true
    )
    error_message = "service_cidr, dns_service_ip and docker_bridge_cidr must be set together"
  }
}

variable "identity_type" {
  description = "Identity type to use. System or User Assigned."
  type        = string
  default     = "SystemAssigned"
}

variable "default_node_pool" {
  description = "Default node pool in cluster. Expects a default node pool configuration (from: azurerm_kubernetes_cluster)."
  type = object({
    name                         = string           # Required
    vnet_subnet_id               = optional(string) # Optional
    vm_size                      = string           # Required
    min_count                    = optional(number) # Only if enable_auto_scaling == true: Required
    node_count                   = optional(number) # Only if enable_auto_scaling == true: Optional
    max_count                    = optional(number) # Only if enable_auto_scaling == true: Required
    orchestrator_version         = string           # Optional
    mode                         = optional(string) # Optional. Default = User
    max_pods                     = number           # Optional
    only_critical_addons_enabled = optional(bool)   # Optional
    os_disk_type                 = string           # Optional
    os_disk_size_gb              = number           # Optional
    enable_auto_scaling          = bool             # Optional. Defautl = false
    enable_node_public_ip        = optional(bool)   # Optional
  })
}

variable "extra_node_pools" {
  description = "Additional node pools. A map of `azurerm_kubernetes_cluster_node_pool` to create and associate with the cluster"
  type = map(object({
    os_type               = optional(string) # Optional. Linux or Windows. Default: Linux
    os_sku                = optional(string) # Optional. Not applicable to Windows os type. Ubuntu or CBLMariner.
    vnet_subnet_id        = optional(string) # Optional
    vm_size               = string           # Required
    min_count             = number           # Only if enable_auto_scaling == true: Required
    node_count            = number           # Only if enable_auto_scaling == true: Optional
    max_count             = number           # Only if enable_auto_scaling == true: Required
    orchestrator_version  = string           # Optional
    mode                  = optional(string) # Optional. Default = User
    max_pods              = number           # Optional
    os_disk_type          = string           # Optional
    os_disk_size_gb       = number           # Optional
    node_taints           = list(string)     # Optional
    enable_auto_scaling   = bool             # Optional. Defautl = false
    enable_node_public_ip = optional(bool)   # Optional
  }))
  default = {}
}

variable "acr" {
  description = "The container registry to enable access to. Expects a `resource` or `data` of `azurerm_container_registry`"
  type = object({
    id                  = optional(string)
    name                = string
    resource_group_name = string
  })
  default = null
}

variable "enable_aad_admin_group" {
  description = "Whether to create the aad cluster admin group"
  type        = bool
  default     = false
}

variable "enable_acr_integration" {
  description = "Whether to attach the AKS cluster to an Azure Container Registry"
  type        = bool
  default     = false
}

variable "enable_aad_pod_identity_roles" {
  description = "Creation of role assignments for pod identities"
  type        = bool
  default     = false
}

variable "enable_log_analytics_workspace" {
  type    = bool
  default = false
}

variable "log_analytics_workspace_name" {
  description = "Name for the log analytics workspace. Will be tied to the cluster name if this is not set."
  type        = string
  default     = null
}

variable "log_analytics_workspace_sku" {
  description = "SKU"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_in_days" {
  type    = number
  default = 30
}
