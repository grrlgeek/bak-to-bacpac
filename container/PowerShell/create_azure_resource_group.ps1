# Connect to Azure

Connect-AzAccount

#Get available subscriptions
Get-AzSubscription

# Set the subscription using the subscription name

$AZContext = Set-AzContext -SubscriptionName 'Microsoft Azure Sponsorship'
$AZContext.Subscription.Name

# Load Variables

. .\container\PowerShell\variables.ps1

# Create Azure Resource Group

if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {

        New-AzResourceGroup -Name $ResourceGroupName -Location $Location     
        Write-Host "Resource group ($ResourceGroupName) created."

    } else {
        Write-Host "Resource group ($ResourceGroupName) exists."
    }

<#
# Clean up 
Remove-AzResourceGroup -Name $ResourceGroupName 
#>
