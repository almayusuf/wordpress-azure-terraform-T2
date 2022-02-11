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
  custom_data = "IyEvYmluL2Jhc2gKCnN1ZG8geXVtIGluc3RhbGwgaHR0cGQgd2dldCB1bnppcCBlcGVsLXJlbGVhc2UgbXlzcWwgLXkKc3VkbyB5dW0gLXkgaW5zdGFsbCBodHRwOi8vcnBtcy5yZW1pcmVwby5uZXQvZW50ZXJwcmlzZS9yZW1pLXJlbGVhc2UtNy5ycG0Kc3VkbyB5dW0gLXkgaW5zdGFsbCB5dW0tdXRpbHMKc3VkbyB5dW0tY29uZmlnLW1hbmFnZXIgLS1lbmFibGUgcmVtaS1waHA1NiAgIFtJbnN0YWxsIFBIUCA1LjZdCnN1ZG8geXVtIC15IGluc3RhbGwgcGhwIHBocC1tY3J5cHQgcGhwLWNsaSBwaHAtZ2QgcGhwLWN1cmwgcGhwLW15c3FsIHBocC1sZGFwIHBocC16aXAgcGhwLWZpbGVpbmZvCnN1ZG8gd2dldCBodHRwczovL3dvcmRwcmVzcy5vcmcvbGF0ZXN0LnRhci5negpzdWRvIHRhciAteGYgbGF0ZXN0LnRhci5neiAtQyAvdmFyL3d3dy9odG1sLwpzdWRvIG12IC92YXIvd3d3L2h0bWwvd29yZHByZXNzLyogL3Zhci93d3cvaHRtbC8Kc3VkbyBnZXRlbmZvcmNlCnN1ZG8gc2VkICdzL1NFTElOVVg9cGVybWlzc2l2ZS9TRUxJTlVYPWVuZm9yY2luZy9nJyAvZXRjL3N5c2NvbmZpZy9zZWxpbnV4IC1pCnN1ZG8gc2V0ZW5mb3JjZSAwCnN1ZG8gY2hvd24gLVIgYXBhY2hlOmFwYWNoZSAvdmFyL3d3dy9odG1sLwpzdWRvIHN5c3RlbWN0bCBzdGFydCBodHRwZApzdWRvIHN5c3RlbWN0bCBlbmFibGUgaHR0cGQKCgpleHBvcnQgV09SRFBSRVNTX0RCX0hPU1Q9d29yZHByZXNzLW15c3FsLXNlcnZlci5teXNxbC5kYXRhYmFzZS5henVyZS5jb20KZXhwb3J0IFdPUkRQUkVTU19EQl9VU0VSPXdvcmRwcmVzcwpleHBvcnQgV09SRFBSRVNTX0RCX1BBU1NXT1JEPVcwcmRwcjNzc0BwNHNzCmV4cG9ydCBXT1JEUFJFU1NfREJfTkFNRT13b3JkcHJlc3M="
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
