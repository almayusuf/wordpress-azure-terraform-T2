# wordpress-azure-terraform-T2
Use Terraform to provision an Azure virtual machine scale set running Wordpress.


## Prerequisites

* [Terraform](https://www.terraform.io)
* [Azure subscription](https://azure.microsoft.com/en-us/free)
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

* Amazon AMI bastion
* Login to your Azure Cloud Provider  
* Select Billing Account under hamburger menu 
* Create a Billing Account For ex: in this project we created  used Yusuf Acoount billing



## How to use

With Terraform and Azure CLI properly configured, you can run:

### `terraform init`

Prepare your working directory.

### `terraform plan`

Generate an execution plan.

### `terraform apply`

Apply changes to Azure cloud.



# Github 

Go to Github and create a repo for your project, dont forget to add .gitignore and README.md files 

This is group project, so add your collaborators into your project with their github names 

After adding them as collaborator, users will be able to add their SSH public keys to github successfully 

Users will be able to clone the project into their locals with git clone command 


# Documentation for .tf files

# RESOURCE GROUP + PROVIDER 
Create a resource group. Configure the Microsoft Azure Provider. 
Steps: 
Create Azure_Three_tier application Folder with .gitignore and README.md files
Under Azure_Three_tier Create a file  provider+rg.tf 
Use resource "azurerm_resource_group" "example"  to create resource group
Use resource provider "azurerm" features to create provider resource

```
# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.91.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "wordpress" {
  name     = "wordpressResourceGroup"
  location = var.location
  tags     = var.tags
}


# Generates a random permutation of alphanumeric characters
resource "random_string" "fqdn" {
  length  = 6
  special = false
  upper   = false
  number  = false
}
```

 

# VARIABLE.TF  
In this project we used variables to make our code more dynamic. Create a file variable.tf 
```
variable "location" {
  description = "The location where resources will be created"
  default     = "East US"
}

variable "tags" {
  description = "A map of the tags to use for the resources that are deployed"
  type        = map(string)

  default = {
    environment = "Test"
  }
}

variable "application_port" {
  description = "The port that you want to expose to the external load balancer"
  default     = 80
}

variable "admin_username" {
  description = "User name to use as the admin account on the VMs that will be part of the VM Scale Set"
  default     = "wordpress"
}

variable "admin_password" {
  description = "Default password for admin account"
  default     = "W0rdpr3ss@p4ss"
}

variable "database_admin_login" {
  default = "wordpress"
}

variable "database_admin_password" {
  default = "w0rdpr3ss@p4ss"
}
```

 

# Vnet 
Next we created vnet.tf configuration file. Vnet is the Virtual Network which will include subnet that will associated with public ip. 

Steps: 
Use resource "azurerm_network_security_group" "example" to create the Vnet
Create vnet.tf file in folder with .gitignore and README.md files 

```
resource "azurerm_virtual_network" "wordpress" {
  name                = "wordpress-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.wordpress.name
  tags                = var.tags
}

resource "azurerm_subnet" "wordpress" {
  name                 = "wordpress-subnet"
  resource_group_name  = azurerm_resource_group.wordpress.name
  virtual_network_name = azurerm_virtual_network.wordpress.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "wordpress" {
  name                = "wordpress-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.wordpress.name
  allocation_method   = "Static"
  domain_name_label   = random_string.fqdn.result
  tags                = var.tags
}
```


# MAIN.TF  
In Main. tf file we used below resources: 
resource "azurerm_lb" "example" https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule
When setting up an Azure Load Balancer, you configure a health probe that your load balancer can use to determine if your instance is healthy.
Use resource "resource "azurerm_lb_rule" "example"  to create load balancer Rule 

The backend pool is a critical component of the load balancer. The backend pool defines the group of resources that will serve traffic for a given load-balancing rule.
Use resource https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool to create backend pool


```
resource "azurerm_lb" "wordpress" {
  name                = "wordpress-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.wordpress.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.wordpress.id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id = azurerm_lb.wordpress.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "wordpress" {
  resource_group_name = azurerm_resource_group.wordpress.name
  loadbalancer_id     = azurerm_lb.wordpress.id
  name                = "ssh-running-probe"
  port                = var.application_port
}

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = azurerm_resource_group.wordpress.name
  loadbalancer_id                = azurerm_lb.wordpress.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = var.application_port
  backend_port                   = var.application_port
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.wordpress.id
}

resource "azurerm_linux_virtual_machine_scale_set" "wordpress" {
  name                            = "vmscaleset"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.wordpress.name
  sku                             = "Standard_DS1_v2"
  instances                       = 2
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  # custom_data                     = filebase64("/home/ec2-user/wordpress-azure-terraform-T3/wordpress.sh")
  custom_data = "IyEvYmluL2Jhc2gKc3VkbyB5dW0gaW5zdGFsbCBodHRwZCB3Z2V0IHVuemlwIGVwZWwtcmVsZWFzZSBteXNxbCAteQpzdWRvIHl1bSAteSBpbnN0YWxsIGh0dHA6Ly9ycG1zLnJlbWlyZXBvLm5ldC9lbnRlcnByaXNlL3JlbWktcmVsZWFzZS03LnJwbQpzdWRvIHl1bSAteSBpbnN0YWxsIHl1bS11dGlscwpzdWRvIHl1bS1jb25maWctbWFuYWdlciAtLWVuYWJsZSByZW1pLXBocDU2ICAgW0luc3RhbGwgUEhQIDUuNl0Kc3VkbyB5dW0gLXkgaW5zdGFsbCBwaHAgcGhwLW1jcnlwdCBwaHAtY2xpIHBocC1nZCBwaHAtY3VybCBwaHAtbXlzcWwgcGhwLWxkYXAgcGhwLXppcCBwaHAtZmlsZWluZm8Kc3VkbyB3Z2V0IGh0dHBzOi8vd29yZHByZXNzLm9yZy9sYXRlc3QudGFyLmd6CnN1ZG8gdGFyIC14ZiBsYXRlc3QudGFyLmd6IC1DIC92YXIvd3d3L2h0bWwvCnN1ZG8gbXYgL3Zhci93d3cvaHRtbC93b3JkcHJlc3MvKiAvdmFyL3d3dy9odG1sLwpzdWRvIGdldGVuZm9yY2UKc3VkbyBzZWQgJ3MvU0VMSU5VWD1wZXJtaXNzaXZlL1NFTElOVVg9ZW5mb3JjaW5nL2cnIC9ldGMvc3lzY29uZmlnL3NlbGludXggLWkKc3VkbyBzZXRlbmZvcmNlIDAKc3VkbyBjaG93biAtUiBhcGFjaGU6YXBhY2hlIC92YXIvd3d3L2h0bWwvCnN1ZG8gc3lzdGVtY3RsIHN0YXJ0IGh0dHBkCnN1ZG8gc3lzdGVtY3RsIGVuYWJsZSBodHRwZA=="

 source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "NetworkInterface"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = azurerm_subnet.wordpress.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      primary                                = true
    }
  }

  tags = var.tags
}

# data "template_file" "script" {
#   # template = filebase64("/home/ec2-user/wordpress-azure-terraform-T3/wordpress.sh")
#   template = file("wordpress.conf")
# }

# data "template_cloudinit_config" "config" {
#   gzip          = true
#   base64_encode = true

#   part {
#     # filename     = "wordpress.sh"
#     filename     = "wordpress.conf"
#     content_type = "text/cloud-config"
#     content      = data.template_file.script.rendered
#   }

#   depends_on = [azurerm_mysql_server.wordpress]
# }
```
 

 

 
# DATABASE.TF  

We used Azure Database for MySQL it's  a fully managed database service, which means that Microsoft automates the management and maintenance of your infrastructure and database server, including routine updates, backups and security.
Azure Database for MySQL is easy to set up, operate, and scale.
Use resource https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mysql_server to create Database. 

```
# Create MySQL Server
resource "azurerm_mysql_server" "wordpress" {
  resource_group_name = azurerm_resource_group.wordpress.name
  name                = "wordpress-mysql-server-${(random_string.fqdn.result)}"
  location            = azurerm_resource_group.wordpress.location
  version             = "5.7"

  administrator_login          = var.database_admin_login
  administrator_login_password = var.database_admin_password

  sku_name                     = "GP_Gen5_4"
  storage_mb                   = "102400"
  auto_grow_enabled            = false
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = false
  #ssl_minimal_tls_version_enforced = "TLS1_2"
}

# Create MySql DataBase
resource "azurerm_mysql_database" "wordpress" {
  name                = "wordpress-mysql-db-${(random_string.fqdn.result)}"
  resource_group_name = azurerm_resource_group.wordpress.name
  server_name         = azurerm_mysql_server.wordpress.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

# Config MySQL Server Firewall Rule
resource "azurerm_mysql_firewall_rule" "wordpress" {
  name                = "wordpress-mysql-firewall-rule-${(random_string.fqdn.result)}"
  resource_group_name = azurerm_resource_group.wordpress.name
  server_name         = azurerm_mysql_server.wordpress.name
  start_ip_address    = azurerm_public_ip.wordpress.ip_address
  end_ip_address      = azurerm_public_ip.wordpress.ip_address
}

data "azurerm_mysql_server" "wordpress" {
  name                = azurerm_mysql_server.wordpress.name
  resource_group_name = azurerm_resource_group.wordpress.name
}
```

 

# OUTPUT.TF
Output values make information about your infrastructure available on the command line, and can expose information for other Terraform configurations to use. Output values are similar to return values in programming languages.

```
output "application_public_address" {
  value = azurerm_public_ip.wordpress.fqdn
}
```

 

 
