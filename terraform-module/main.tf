terraform {
  required_version = ">= 0.14.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.112.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.15.0"
    }
  }
}

provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

provider "azapi" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

variable "client_id" {
  description = "The Client ID of the Service Principal"
  type        = string
}

variable "client_secret" {
  description = "The Client Secret of the Service Principal"
  type        = string
}

variable "tenant_id" {
  description = "The Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "The Subscription ID"
  type        = string
}




locals {
  storage_account_prefix = "boot"
 # route_table_name       = "DefaultRouteTable"
 # route_name             = "RouteToAzureFirewall"
}
data "azurerm_client_config" "current" {}
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

module "aks_network" {
  source              = "./modules/virtual_network"
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_name           = "aks-vnet-${var.project_name}-${var.environment_name}-${var.postfix}"
  address_space       = var.aks_vnet_address_space
  subnet_nsg_id       = module.subnetnsg.id

  subnets = [
    {
      name : var.default_node_pool_subnet_name
      address_prefixes : var.default_node_pool_subnet_address_prefix
      private_link_service_network_policies_enabled : false
    },
    {
      name : var.additional_node_pool_subnet_name
      address_prefixes : var.additional_node_pool_subnet_address_prefix
      private_link_service_network_policies_enabled : false
    },
    {
      name : var.appgw_subnet_name
      address_prefixes : [var.appgw_subnet_address_prefix]
      private_link_service_network_policies_enabled : false
    },
    {
      name : var.vm_subnet_name
      address_prefixes : var.vm_subnet_address_prefix
      private_link_service_network_policies_enabled : false
    }
  ]
}

# NAT Gateway module
module "nat_gateway" {
  source              = "./modules/nat_gateway"
  nat_name            = "aks-vnet-${var.project_name}-${var.environment_name}-${var.postfix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  prefix_length       = var.prefix_length
  subnet_ids          = module.aks_network.subnet_ids
    depends_on = [
    module.aks_network,
  ]
}


module "subnetnsg" {
  source              = "./modules/network_security_group"
  name                = "subnet-nsg-${var.project_name}-${var.environment_name}-${var.postfix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  security_rules      = var.subnet_network_security_group_rules
}

module "container_registry" {
  source                   = "./modules/container_registry"
  name                     = "acr${var.project_name}${var.environment_name}${var.postfix}"
  acr_identity_name        = "acr${var.project_name}${var.environment_name}${var.postfix}identity"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = var.acr_sku
  admin_enabled            = var.acr_admin_enabled
  georeplication_locations = var.acr_georeplication_locations
  # log_analytics_workspace_id = module.log_analytics_workspace.id
}

module "aks_cluster" {
  source                                   = "./modules/aks"
  name                                     = "aks-${var.project_name}-${var.environment_name}-${var.postfix}"
  aks_identity_name                        = "aks-${var.project_name}-${var.environment_name}-${var.postfix}-identity"
  location                                 = var.location
  resource_group_name                      = var.resource_group_name
  resource_group_id                        = data.azurerm_resource_group.rg.id
  kubernetes_version                       = var.kubernetes_version
  dns_prefix                               = lower("aks-${var.project_name}-${var.environment_name}-${var.postfix}")
  private_cluster_enabled                  = true
  private_dns_zone_id                      = module.aks_private_dns_zone.id
  automatic_channel_upgrade                = var.automatic_channel_upgrade
  sku_tier                                 = var.sku_tier
  default_node_pool_name                   = var.default_node_pool_name
  default_node_pool_vm_size                = var.default_node_pool_vm_size
  vnet_subnet_id                           = module.aks_network.subnet_ids[var.default_node_pool_subnet_name]
  default_node_pool_availability_zones     = var.default_node_pool_availability_zones
  default_node_pool_node_labels            = var.default_node_pool_node_labels
  default_node_pool_node_taints            = var.default_node_pool_node_taints
  default_node_pool_enable_auto_scaling    = var.default_node_pool_enable_auto_scaling
  default_node_pool_enable_host_encryption = var.default_node_pool_enable_host_encryption
  default_node_pool_enable_node_public_ip  = var.default_node_pool_enable_node_public_ip
  default_node_pool_max_pods               = var.default_node_pool_max_pods
  default_node_pool_max_count              = var.default_node_pool_max_count
  default_node_pool_min_count              = var.default_node_pool_min_count
  default_node_pool_node_count             = var.default_node_pool_node_count
  default_node_pool_os_disk_type           = var.default_node_pool_os_disk_type
  tags                                     = var.tags
  network_dns_service_ip                   = var.network_dns_service_ip
  network_plugin                           = var.network_plugin
  outbound_type                            = var.outbound_type
  network_service_cidr                     = var.network_service_cidr
  role_based_access_control_enabled        = var.role_based_access_control_enabled
  tenant_id                                = data.azurerm_client_config.current.tenant_id
  admin_group_object_ids                   = var.admin_group_object_ids
  azure_rbac_enabled                       = var.azure_rbac_enabled
  admin_username                           = var.admin_username
  ssh_public_key                           = module.ssh_key.public_key_data
  keda_enabled                             = var.keda_enabled
  vertical_pod_autoscaler_enabled          = var.vertical_pod_autoscaler_enabled
  workload_identity_enabled                = var.workload_identity_enabled
  oidc_issuer_enabled                      = var.oidc_issuer_enabled
  open_service_mesh_enabled                = var.open_service_mesh_enabled
  image_cleaner_enabled                    = var.image_cleaner_enabled
  azure_policy_enabled                     = var.azure_policy_enabled
  http_application_routing_enabled         = var.http_application_routing_enabled
  key_vault_secrets_provider_enabled       = var.key_vault_secrets_provider_enabled
  secret_rotation_enabled                  = var.secret_rotation_enabled

  ingress_application_gateway = {
    enabled      = var.ingress_application_gateway_enabled
    gateway_name = "agic-${var.project_name}-${var.environment_name}-${var.postfix}"
    subnet_id    = module.aks_network.subnet_ids[var.appgw_subnet_name]
  }

  depends_on = [
    module.ssh_key,
    module.aks_private_dns_zone,
    module.aks_network
  ]
}

resource "azurerm_role_assignment" "network_contributor_ingress_application_gateway_identity" {
  scope                = data.azurerm_resource_group.rg.id
  principal_id         = module.aks_cluster.ingress_application_gateway_identity_object_id
  role_definition_name = "Network Contributor"

  depends_on = [
    module.aks_cluster
  ]
  count = var.ingress_application_gateway_enabled ? 1 : 0
}

resource "azurerm_role_assignment" "network_contributor_key_vault_secrets_provider_identity" {
  scope                = data.azurerm_resource_group.rg.id
  principal_id         = module.aks_cluster.key_vault_secrets_provider_identity_object_id
  role_definition_name = "Network Contributor"

  depends_on = [
    module.aks_cluster
  ]
  count = var.key_vault_secrets_provider_enabled ? 1 : 0
}

resource "azurerm_role_assignment" "network_contributor" {
  scope                            = data.azurerm_resource_group.rg.id
  role_definition_name             = "Network Contributor"
  principal_id                     = module.aks_cluster.aks_identity_principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_cluster_network_contributor" {
  scope                            = module.aks_network.subnet_ids[var.default_node_pool_subnet_name]
  role_definition_name             = "Network Contributor"
  principal_id                     = module.aks_cluster.kubelet_identity_object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_cluster1_network_contributor" {
  scope                            = module.aks_network.subnet_ids[var.additional_node_pool_subnet_name]
  role_definition_name             = "Network Contributor"
  principal_id                     = module.aks_cluster.kubelet_identity_object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "acr_pull" {
  role_definition_name             = "AcrPull"
  scope                            = module.container_registry.id
  principal_id                     = module.aks_cluster.kubelet_identity_object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_user_assigned_identity" "vm_identity" {
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  name = "vm-identity-${var.project_name}-${var.environment_name}-${var.postfix}"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}


resource "azurerm_role_assignment" "vm_acr_pull" {
  role_definition_name             = "AcrPush"
  scope                            = module.container_registry.id
  principal_id                     = azurerm_user_assigned_identity.vm_identity.principal_id
  skip_service_principal_aad_check = true
}

# Assign AcrPush role to the VM identity
resource "azurerm_role_assignment" "vm_acr_push" {
  role_definition_name = "AcrPush"
  scope                = module.container_registry.id
  principal_id         = azurerm_user_assigned_identity.vm_identity.principal_id
  skip_service_principal_aad_check = true

  depends_on = [
    module.container_registry,
    azurerm_user_assigned_identity.vm_identity
  ]
}

module "storage_account" {
  source                 = "./modules/storage_account"
  name                   = lower("sa01${var.project_name}${var.environment_name}")
  location               = var.location
  resource_group_name    = var.resource_group_name
  account_kind           = var.storage_account_kind
  account_tier           = var.storage_account_tier
  storage_container_name = "container-${var.project_name}-${var.environment_name}-${var.postfix}"
  # container_names         = ["container1", "container2", "container3"]
  # Include other required variables...
}





module "node_pool" {
  source                 = "./modules/node_pool"
  resource_group_name    = var.resource_group_name
  kubernetes_cluster_id  = module.aks_cluster.id
  name                   = var.additional_node_pool_name
  vm_size                = var.additional_node_pool_vm_size
  mode                   = var.additional_node_pool_mode
  node_labels            = var.additional_node_pool_node_labels
  node_taints            = var.additional_node_pool_node_taints
  availability_zones     = var.additional_node_pool_availability_zones
  vnet_subnet_id         = module.aks_network.subnet_ids[var.additional_node_pool_subnet_name]
  enable_auto_scaling    = var.additional_node_pool_enable_auto_scaling
  enable_host_encryption = var.additional_node_pool_enable_host_encryption
  enable_node_public_ip  = var.additional_node_pool_enable_node_public_ip
  orchestrator_version   = var.kubernetes_version
  max_pods               = var.additional_node_pool_max_pods
  max_count              = var.additional_node_pool_max_count
  min_count              = var.additional_node_pool_min_count
  node_count             = var.additional_node_pool_node_count
  os_type                = var.additional_node_pool_os_type
  os_disk_type = var.additional_node_pool_os_disk_type
  priority               = var.additional_node_pool_priority
  tags                   = var.tags
}


module "aks_private_dns_zone" {
  source              = "./modules/private_dns_zone"
  name                = "${var.project_name}-${var.environment_name}-${var.postfix}.privatelink.centralindia.azmk8s.io"
  resource_group_name = var.resource_group_name
  virtual_networks_to_link = {
    (module.aks_network.name) = {
      subscription_id     = data.azurerm_client_config.current.subscription_id
      resource_group_name = var.resource_group_name
    }
  }
}


module "ssh_key" {
  source              = "./modules/ssh_keys"
  resource_group_id   = data.azurerm_resource_group.rg.id
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = "sshkey-${var.project_name}-${var.environment_name}-${var.postfix}"
}
#----------------------------------------------------
# vm for accesing aks and also act as azure azent
#----------------------------------------------------
module "virtual_machine" {
  source         = "./modules/virtual_machine"
  name           = "vm-jumpbox-${var.project_name}-${var.environment_name}-${var.postfix}"
  vm_nsg_name    = "vm-jumpbox-${var.project_name}-${var.environment_name}-nsg-${var.postfix}"
  public_ip_name = "vm-jumpbox-${var.project_name}-pip-${var.postfix}"
  vm_disk_name   = "vm-jumpbox-${var.project_name}-disk-${var.postfix}"
  size           = var.vm_size
  location       = var.location
  public_ip      = var.vm_public_ip
  vm_user        = var.admin_username
  vm_identity    = [azurerm_user_assigned_identity.vm_identity.id]
  admin_password = var.admin_password
  os_disk_image  = var.vm_os_disk_image
  domain_name_label = "${var.project_name}-${var.environment_name}-${var.postfix}vm"
  resource_group_name = var.resource_group_name
  subnet_id      = module.aks_network.subnet_ids[var.vm_subnet_name]
  os_disk_storage_account_type = var.vm_os_disk_storage_account_type
  null_resource_count = 1
  depends_on = [
    module.ssh_key,
  ]
}
#---------------------------------------------------------------------------------------------------------------
# Assign roles to vm identiy created 
#--------------------------------------------------------------------------------------------------------------

resource "azurerm_role_assignment" "vm_network_contributor" {
  scope                            = data.azurerm_resource_group.rg.id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.vm_identity.principal_id
  skip_service_principal_aad_check = true
    depends_on = [
   module.virtual_machine
  ]
}

resource "azurerm_role_assignment" "vm_aks_get_credentials" {
  scope                            = module.aks_cluster.id
  role_definition_name             = "Azure Kubernetes Service Contributor Role"
  principal_id                     = azurerm_user_assigned_identity.vm_identity.principal_id
  skip_service_principal_aad_check = true
    depends_on = [
   module.virtual_machine
  ]
}
resource "azurerm_role_assignment" "admin" {
  scope                            = module.aks_cluster.id
  role_definition_name             = "Azure Kubernetes Service Cluster Admin Role"
  principal_id                     = azurerm_user_assigned_identity.vm_identity.principal_id
  skip_service_principal_aad_check = true
    depends_on = [
   module.virtual_machine
  ]
}
#------------------------------------------------------------------------------------------------------------
# vm provising using remote exec 
#----------------------------------------------------------------------------------------------------------

resource "null_resource" "provisioning_script" {
  provisioner "file" {
    source      = "setup.sh"
    destination = "/tmp/setup.sh"

    connection {
      type     = "ssh"
      host     = module.virtual_machine.public_ip  # Reference the output for public IP
      user     = module.virtual_machine.username   # Reference the output for username
      password = var.admin_password                # Or use another variable for password
    }
  }

  provisioner "file" {
    source      = "nginxingrss.yaml"
    destination = "/tmp/nginxingrss.yaml"

    connection {
      type     = "ssh"
      host     = module.virtual_machine.public_ip  # Reference the output for public IP
      user     = module.virtual_machine.username   # Reference the output for username
      password = var.admin_password                # Or use another variable for password
    }
  }

provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "/tmp/setup.sh ${var.resource_group_name} ${module.aks_cluster.name}"
    ]

    connection {
      type     = "ssh"
      host     = module.virtual_machine.public_ip  # Reference the output for public IP
      user     = module.virtual_machine.username   # Reference the output for username
      password = var.admin_password                # Or use another variable for password
    }
  }

  triggers = {
    always_run = timestamp()
  }

  depends_on = [
    azurerm_role_assignment.vm_network_contributor,
    azurerm_role_assignment.vm_aks_get_credentials
  ]
}


#------------------------------------------------------------------------------------------------------------
# azure frontdoor 
#------------------------------------------------------------------------------------------------------------
module "frontdoor" {
  source                     = "./modules/front_door"
  resource_group_name        = var.resource_group_name
  frontdoor_name             = "frontdoor-${var.project_name}-${var.environment_name}-${var.postfix}"
  frontend_endpoint_name     = "frontendendpointname"
  backend_pool_name          = "storgaeaccount"
  backend_host_header        = replace(replace(module.storage_account.primary_web_endpoint, "https://", ""), "/", "")
    backend_address          = replace(replace(module.storage_account.primary_web_endpoint, "https://", ""), "/", "")  
  backend_http_port          = 80
  backend_https_port         = 443
  load_balancing_name        = "loadbalancingname"
  health_probe_name          = "healthprobename"
  routing_rule_name          = "routingrulename"
  accepted_protocols         = ["Http", "Https"]
  patterns_to_match          = ["/*"]
}
#----------------------------------------------------
# key vault
#----------------------------------------------------
module "key_vault" {
  source              = "./modules/key_vault"
  resource_group_name = var.resource_group_name
  location            = var.location
  key_vault_name      = "keyvault-${var.project_name}-${var.environment_name}-${var.postfix}"
  tenant_id          =  data.azurerm_client_config.current.tenant_id
}
#----------------------------------------------------
# route table  
#----------------------------------------------------

resource "azurerm_route_table" "azurerm_route_table" {
  name                = "route-table"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "dev"
  }
}
#----------------------------------------------------
# route table asscation 
#----------------------------------------------------
resource "azurerm_subnet_route_table_association" "azurerm_subnet_route_table_association" {
  subnet_id      = module.aks_network.subnet_ids[var.default_node_pool_subnet_name] # Change to the correct subnet ID
  route_table_id = azurerm_route_table.azurerm_route_table.id
}
#------------------------------------------------------
#aks keyvault inegration
#-----------------------------------------------------
resource "azurerm_role_assignment" "aks_identity_keyvault_secrets_user" {
  scope                = module.key_vault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.aks_cluster.aks_identity_principal_id
}


