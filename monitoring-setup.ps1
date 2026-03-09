# ---------------------------------------------------------------
# Azure Monitor Setup - CPU Alert Rules
# Matches infrastructure from infrastructure.sh
# ---------------------------------------------------------------

# Variables
$ResourceGroup    = "lab4-rg"
$Location         = "westeurope"
$AppServicePlan   = "myAppServicePlan"
$WebAppName       = "DennisWebApp123"
$AlertRuleName    = "HighCPUAlert"
$ActionGroupName  = "AppAlertActionGroup"
$ActionGroupShort = "AppAlerts"
$AlertEmail       = "dennis.nilsson1111@gmail.com"   # Replace with your email
$CpuThreshold     = 80    # Percentage
$WindowSizeMin    = 5     # Minutes
$FrequencyMin     = 1     # Evaluation frequency in minutes

# ---------------------------------------------------------------
# 1. Ensure the Az modules are available
# ---------------------------------------------------------------
$requiredModules = @("Az.Monitor", "Az.Insights", "Az.Resources")
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing module: $module" -ForegroundColor Yellow
        Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
    }
}

Import-Module Az.Monitor, Az.Insights, Az.Resources -ErrorAction Stop

# ---------------------------------------------------------------
# 2. Create an Action Group (email notification on alert)
# ---------------------------------------------------------------
Write-Host "`nCreating Action Group '$ActionGroupName'..." -ForegroundColor Cyan

$emailReceiver = New-AzActionGroupReceiver `
    -Name "EmailReceiver" `
    -EmailReceiver `
    -EmailAddress $AlertEmail

$actionGroup = Set-AzActionGroup `
    -ResourceGroupName $ResourceGroup `
    -Name $ActionGroupName `
    -ShortName $ActionGroupShort `
    -Receiver $emailReceiver

Write-Host "Action Group created: $($actionGroup.Id)" -ForegroundColor Green

# ---------------------------------------------------------------
# 3. Get the App Service Plan resource ID (metric source)
# ---------------------------------------------------------------
Write-Host "`nResolving App Service Plan resource ID..." -ForegroundColor Cyan

$asp = Get-AzResource `
    -ResourceGroupName $ResourceGroup `
    -ResourceType "Microsoft.Web/serverfarms" `
    -ResourceName $AppServicePlan

if (-not $asp) {
    Write-Error "App Service Plan '$AppServicePlan' not found in resource group '$ResourceGroup'."
    exit 1
}

$aspResourceId = $asp.ResourceId
Write-Host "Resource ID: $aspResourceId" -ForegroundColor Green

# ---------------------------------------------------------------
# 4. Create the CPU Metric Alert Rule
# ---------------------------------------------------------------
Write-Host "`nCreating CPU alert rule '$AlertRuleName'..." -ForegroundColor Cyan

$condition = New-AzMetricAlertRuleV2Criteria `
    -MetricName "CpuPercentage" `
    -MetricNamespace "Microsoft.Web/serverfarms" `
    -TimeAggregation "Average" `
    -Operator "GreaterThan" `
    -Threshold $CpuThreshold

$actionGroupId = New-AzMetricAlertRuleV2ActionGroup `
    -ActionGroupId $actionGroup.Id

Add-AzMetricAlertRuleV2 `
    -Name $AlertRuleName `
    -ResourceGroupName $ResourceGroup `
    -WindowSize (New-TimeSpan -Minutes $WindowSizeMin) `
    -Frequency (New-TimeSpan -Minutes $FrequencyMin) `
    -TargetResourceId $aspResourceId `
    -Condition $condition `
    -ActionGroup $actionGroupId `
    -Severity 2 `
    -Description "Alert when average CPU exceeds $CpuThreshold% over $WindowSizeMin minutes." `
    -Enabled $true

Write-Host "CPU alert rule '$AlertRuleName' created successfully." -ForegroundColor Green

# ---------------------------------------------------------------
# 5. Verify the alert rule
# ---------------------------------------------------------------
Write-Host "`nVerifying alert rule..." -ForegroundColor Cyan

$rule = Get-AzMetricAlertRuleV2 `
    -ResourceGroupName $ResourceGroup `
    -Name $AlertRuleName

Write-Host "Alert Rule: $($rule.Name) | Enabled: $($rule.Enabled) | Severity: $($rule.Severity)" -ForegroundColor Green
Write-Host "`nMonitoring setup complete." -ForegroundColor Cyan
