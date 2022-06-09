# terraform-azurerm-aks

This terraform module deploys a base AKS cluster with optional addons:

* If the the cluster and vnet do not share resource group, remember to follow: https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal?tabs=azure-cli#networking (1)
