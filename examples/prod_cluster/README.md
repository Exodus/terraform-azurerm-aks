# Prod Cluster

In a production scenario, you would ideally separate concerns and have the base network infrastructure in another terraform code, either due to another team owning this, or simply because many multiple other things will want to be created in this network, and it's lifetime should not live with the kubernetes cluster.

This is a non-working example as it makes these assumptions that other terraform code has created/separated the creation of the base network infrastructure, and uses those as data instead of resources.