#----Creating a resourceGroup for network resources
resource "azurerm_resource_group" "rg_1" {
  name     = "rg-we-viki-github-deployments01"
  location = "westeurope"
}
