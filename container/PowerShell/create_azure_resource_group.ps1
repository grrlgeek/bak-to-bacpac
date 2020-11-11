# Get current subscription 
$AZContext = Get-AzContext
$AZContext.Subscription.Name

# Set subscription to use 
Set-AzContext -SubscriptionName $AZContext.Subscription.Name

# Create Azure Resource Group 
$RGName = 'sqlcontainers' 
$Location = 'eastus'

$RGExists = Get-AzResourceGroup -Name $RGName -ErrorAction SilentlyContinue
if ($RGExists -eq $null) 
    {
        New-AzResourceGroup `
                -Name $RGName `
                -Location $Location 
                
        Write-Host "Resource group ($RGName) created."
    }
else 
    {
        Write-Host "Resource group ($RGName) exists."
    }

<#
# Clean up 
Remove-AzResourceGroup -Name $RGName 
#>
