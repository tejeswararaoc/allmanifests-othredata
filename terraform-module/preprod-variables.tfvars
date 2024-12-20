resource_group_name         = "CMS_IAC_PREPROD-01"
resource_group_id           = "/subscriptions/c3d7eec8-0044-4040-b98f-b66627cfb27a/resourceGroups/CMS_IAC_PREPROD-01"
environment_name            = "preprod"
postfix                     = "01"
project_name                = "cms"
aks_vnet_address_space      = ["10.150.0.0/16"]
vm_subnet_address_prefix    = ["10.150.48.0/24"]
appgw_subnet_address_prefix = "10.150.64.0/20"
default_node_pool_subnet_address_prefix=["10.150.0.0/20"]
additional_node_pool_subnet_address_prefix=["10.150.16.0/20"]

azure_rbac_enabled          = true
kubernetes_version          = "1.29.4"
default_node_pool_vm_size   = "standard_d4s_v4"
default_node_pool_availability_zones = ["1", "2", "3"]
network_dns_service_ip      = "10.2.0.10"
network_service_cidr        = "10.2.0.0/24"
location                    = "centralindia"
default_node_pool_name      = "system"
default_node_pool_node_count = "2"
key_vault_secrets_provider_enabled = true
additional_node_pool_name   = "user"
additional_node_pool_vm_size = "standard_d4s_v4"
additional_node_pool_node_count = "2"

tags = {
    environment = "prod"
    ProjectName = "cms_prod"
}

