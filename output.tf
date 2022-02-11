output "application_public_address" {
  value = azurerm_public_ip.wordpress.fqdn
}
# output "application_public_address" {
#   value = azurerm_public_ip.wordpress.fqdn
# }