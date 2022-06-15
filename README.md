# terraform-azurerm-aks

A terraform module for safely/easily deploying a Kubernetes (AKS) Cluster in Azure with optional addons/features, including:
- AAD Admin Group
- Integrate the cluster with an ACR
- Create the roles for [AAD Pod Identity](https://github.com/Azure/aad-pod-identity)
- Create a log analytics workspace for the cluster
- When the cluster is deployed in another resource group's subnet, enables additional configuration for load balancer and volume creation.
- and a few other things handled for you out of the box...

Some inputs are objects, so either a `data` or `resource` are valid.

**Note:** If the the cluster and vnet do not share resource group, provide the `vnet_resource_group` input. This follows: https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal?tabs=azure-cli#networking and will assign the Network Contributor role to the cluster's identity in that resource group. This scenario is typical in more complex terraform scenarios, where you've separated state/concern of the base network infrastructure from its utilization in separate resource groups.

## Considerations
### Networking
Ideally, you want separation of concerns, between base infrastructure and utilization of that base infrastructure. Separating the terraform code that creates the base infra (resource groups, vnet, subnets) from something like a kubernetes cluster and other applications.

You might want to allow (n) amount of developers to create clusters in a particular virtual network, but not want them to directly control the virtual networks.

AKS uses the 10.0.0.0/16 CIDR for it's default service CIDR. If your current VNet is occupying that CIDR space, you should set the `network_profile` object, review the [prod cluster](./examples/prod_cluster/) for an example.

### Defaults
There are good defaults, but some tie resources to each other. As an example of this, if you do not set the log_analytics_workspace_name, it will use the same name as the cluster (tying them), so, if you change the cluster name (which will recreate the cluster) it will recreate the log analytics workspace (since it's name changed). If your intention is to conserve the workspace and it's analytics when changing the cluster name, give the workspace a name.

## Examples
- [Simple Dev Cluster](./examples/simple_dev_cluster/)
- [Production Ready Cluster](./examples/prod_cluster/)
