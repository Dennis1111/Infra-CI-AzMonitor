# Variables
$ResourceGroup   = "lab4-rg"
$Location        = "westeurope"
$AppServicePlan  = "myAppServicePlan"
$WebAppName      = "DennisWebApp123"   # Must be globally unique
$Sku             = "B1"
$Runtime         = "NODE:20-lts"

# Create Resource Group
Write-Host "Creating Resource Group '$ResourceGroup'..." -ForegroundColor Cyan
az group create `
  --name $ResourceGroup `
  --location $Location

# Create App Service Plan
Write-Host "Creating App Service Plan '$AppServicePlan'..." -ForegroundColor Cyan
az appservice plan create `
  --name $AppServicePlan `
  --resource-group $ResourceGroup `
  --location $Location `
  --sku $Sku `
  --is-linux

# Create Web App
Write-Host "Creating Web App '$WebAppName'..." -ForegroundColor Cyan
az webapp create `
  --name $WebAppName `
  --resource-group $ResourceGroup `
  --plan $AppServicePlan `
  --runtime "$Runtime"

Write-Host "`nWeb App URL: https://$WebAppName.azurewebsites.net" -ForegroundColor Green
