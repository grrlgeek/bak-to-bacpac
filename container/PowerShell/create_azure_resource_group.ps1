# Connect to Azure

Connect-AzAccount

#Get available subscriptions
# Get-AzSubscription

# Set the subscription using the subscription name

$AZContext = Set-AzContext -SubscriptionName $SubscriptionName
$AZContext.Subscription.Name

# Load Variables

. .\container\PowerShell\variables.ps1

# Create Azure Resource Group

if (-not (Get-AzResourceGroup -Name $RGName -ErrorAction SilentlyContinue)) {

        New-AzResourceGroup -Name $RGName -Location $Location     
        Write-Host "Resource group ($RGName) created."

    } else {
        Write-Host "Resource group ($RGName) exists."
    }

<#
# Clean up 
Remove-AzResourceGroup -Name $RGName 
#>
