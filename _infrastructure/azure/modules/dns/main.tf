resource "azurerm_dns_zone" "zone" {
  name                = var.name
  resource_group_name = var.resource_group.name
}

resource "azurerm_dns_a_record" "root" {
  name                = "@"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = var.resource_group.name
  ttl                 = 3600
  records             = [var.ip_address]
}

resource "azurerm_dns_a_record" "wildcard" {
  name                = "*"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = var.resource_group.name
  ttl                 = 3600
  records             = [var.ip_address]
}