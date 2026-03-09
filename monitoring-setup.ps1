# ---------------------------------------------------------------
# Azure Monitor Setup - CPU Alert Rules (Azure CLI)
# No extra modules needed — uses existing az login session
# ---------------------------------------------------------------

# Variables
$ResourceGroup   = "lab4-rg"
$AppServicePlan  = "myAppServicePlan"
$AlertRuleName   = "HighCPUAlert"
$ActionGroupName = "AppAlertActionGroup"
$AlertEmail      = "dennis.nilsson1111@gmail.com"
$CpuThreshold    = 30    # Percentage
$WindowSize      = "PT1M"  # ISO 8601: 1 minute
$Frequency       = "PT1M"  # Evaluation frequency: 1 minute

# ---------------------------------------------------------------
# 1. Get the App Service Plan resource ID
# ---------------------------------------------------------------
Write-Host "Resolving App Service Plan resource ID..." -ForegroundColor Cyan

$aspResourceId = az resource show `
    --resource-group $ResourceGroup `
    --resource-type "Microsoft.Web/serverfarms" `
    --name $AppServicePlan `
    --query id --output tsv

if (-not $aspResourceId) {
    Write-Error "App Service Plan '$AppServicePlan' not found in '$ResourceGroup'. Run infrastructure.ps1 first."
    exit 1
}
Write-Host "Resource ID: $aspResourceId" -ForegroundColor Green

# ---------------------------------------------------------------
# 2. Create Action Group (email notification)
# ---------------------------------------------------------------
Write-Host "`nCreating Action Group '$ActionGroupName'..." -ForegroundColor Cyan

az monitor action-group create `
    --resource-group $ResourceGroup `
    --name $ActionGroupName `
    --short-name "AppAlerts" `
    --location "global" `
    --action email EmailReceiver $AlertEmail

Write-Host "Action Group created." -ForegroundColor Green

# ---------------------------------------------------------------
# 3. Get the Action Group resource ID
# ---------------------------------------------------------------
$actionGroupId = az monitor action-group show `
    --resource-group $ResourceGroup `
    --name $ActionGroupName `
    --query id --output tsv

if (-not $actionGroupId) {
    Write-Error "Failed to retrieve Action Group ID. Cannot create alert rule."
    exit 1
}

# ---------------------------------------------------------------
# 4. Create CPU Metric Alert Rule
# ---------------------------------------------------------------
Write-Host "`nCreating CPU alert rule '$AlertRuleName'..." -ForegroundColor Cyan

az monitor metrics alert create `
    --name $AlertRuleName `
    --resource-group $ResourceGroup `
    --scopes $aspResourceId `
    --condition "avg CpuPercentage > $CpuThreshold" `
    --window-size $WindowSize `
    --evaluation-frequency $Frequency `
    --action $actionGroupId `
    --severity 2 `
    --description "Alert when average CPU exceeds $CpuThreshold% over 1 minute."

Write-Host "CPU alert rule '$AlertRuleName' created." -ForegroundColor Green

# ---------------------------------------------------------------
# 5. Verify
# ---------------------------------------------------------------
Write-Host "`nVerifying alert rule..." -ForegroundColor Cyan

az monitor metrics alert show `
    --resource-group $ResourceGroup `
    --name $AlertRuleName `
    --query "{Name:name, Enabled:enabled, Severity:severity}" `
    --output table

Write-Host "`nMonitoring setup complete." -ForegroundColor Cyan
