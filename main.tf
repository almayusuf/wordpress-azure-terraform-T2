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
