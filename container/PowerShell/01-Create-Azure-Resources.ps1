<#
This file will create the required Azure Resources

Resource Group
Key Vault
Storage Account
Azure Container Registry
and
push the image to the registry
#>

# First Set the variables in the variables.ps1 file to the required values
# This will provide a credential prompt, the user is not important, the password will
# be the SA password for the container

# Make sure your prompt is at the root of the repository and run.

. ./container/PowerShell/variables.ps1 

#region Connect to Azure

# Connect to Azure

Connect-AzAccount

#Get available subscriptions
Get-AzSubscription

# Set the subscription using the subscription name

$AZContext = Set-AzContext -SubscriptionName 'Microsoft Azure Sponsorship'
$AZContext.Subscription.Name

#endregion

#region Create Resource Group
# Create Azure Resource Group

if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {

        New-AzResourceGroup -Name $ResourceGroupName -Location $Location     
        Write-Host "Resource group ($ResourceGroupName) created."

    } else {
        Write-Host "Resource group ($ResourceGroupName) exists."
    }

#endregion

#region Create Key Vault

# Create Azure Key Vault to store secrets.

if (-not (Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KVName -ErrorAction SilentlyContinue)) {
    $AzKVParams = @{
        Name              = $KVName
        ResourceGroupName = $ResourceGroupName
        Location          = $Location
    }
    New-AzKeyVault @AzKVParams 
    Write-Host "Key Vault ($KVName) created."
} else {
    Write-Host "Key Vault ($KVName) exists."
}

# Create Access Policy for the user specified in the UserForKeyVault variable 

$SetAzKVAccessPolicy = @{
    VaultName = $KVName
    UserPrincipalName = $UserForKeyVault
    PermissionsToSecrets = 'get','set','delete'
}
Set-AzKeyVaultAccessPolicy @SetAzKVAccessPolicy

#endregion

#region Create Storage Account

# Use function  to create Storage Account, File Share, and Account Key 

# Create function to create storage account and file share, and generate key 

function New-ContainerStorageSetUp {
    param( [string]$StorageResourceGroupName, 
        [string]$StorageAccountName, 
        [string]$ShareName,
        [string]$Location)

    # check if storage account exists

    $StorageAcctParams = @{
        ResourceGroupName = $StorageResourceGroupName
        Name              = $StorageAccountName
        ErrorAction       = 'SilentlyContinue'
    }
    $StorageAccount = Get-AzStorageAccount @StorageAcctParams

    if ($null -eq $StorageAccount) {
        # create the storage account
        $StorageAccount = New-AzStorageAccount @StorageAcctParams -Location $Location -SkuName Standard_LRS
    }

    # check if the file share already exists

    $AzShareParams = @{
        Name        = $ShareName
        Context     = $StorageAccount.Context
        ErrorAction = 'SilentlyContinue'
    }

    $Share = Get-AzStorageShare @AzShareParams

    if ($null -eq $Share) {
        # create the share
        $Share = New-AzStorageShare @AzShareParams
    }

    <# Add a container for blob storage also, same name #>
    # check if the file share already exists

    $AzStorageContainerParams = @{
        Name        = $ShareName
        Context     = $StorageAccount.Context
        ErrorAction = 'SilentlyContinue'
    }
    $Container = Get-AzStorageContainer @AzStorageContainerParams

    if ($null -eq $Container) {
        # create the container
        $Container = New-AzStorageContainer @AzStorageContainerParams
    }
    <# End blob storage #>

    # get the credentials
    $StorageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName $StorageResourceGroupName -Name $StorageAccountName
    $StorageAccountKey = $StorageAccountKeys[0].Value
    $StorageAccountKeySecureString = ConvertTo-SecureString $StorageAccountKey -AsPlainText -Force
    $StorageAccountCredentials = New-Object System.Management.Automation.PSCredential ($StorageAccountName, $StorageAccountKeySecureString)

    $StorageAccountCredentials
}


$ContainerStorageSetUpParams = @{
    StorageResourceGroupName = $ResourceGroupName
    StorageAccountName       = $StorageAccountName
    ShareName                = $ShareName
    Location                 = $Location
}
$StorageAccountCredentials = New-ContainerStorageSetUp @ContainerStorageSetUpParams


# Put storage account key in key vault

# Storage account key

$SecretValue = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$SecretValueSecure = ConvertTo-SecureString -String $SecretValue -AsPlainText -Force

$SecretSetParams = @{
    VaultName   = $KVName
    Name        = $AcctKeySecretName
    SecretValue = $SecretValueSecure
}
Set-AzKeyVaultSecret @SecretSetParams

Write-Host "Secret ($AcctKeySecretName) created or updated."

#endregion

#region Create Azure Container Registry

if (-not(Get-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Name $ACRName -ErrorAction SilentlyContinue)) {

    $AzContainerRegistryParams = @{
        ResourceGroupName = $ResourceGroupName
        Name              = $ACRName
        Location          = $Location
        Sku               = "Basic"
        EnableAdminUser   = $true
    }
    New-AzContainerRegistry @AzContainerRegistryParams
    Write-Host "Container registry ($ACRName) created."
}else {
    Write-Host "Container registry ($ACRName) exists."
}

# Store admin username and password in Key Vault
# Container registry admin username

$SecretValue = (Get-AzContainerRegistryCredential -ResourceGroupName $ResourceGroupName -Name $ACRName).Username
$SecretValueSecure = ConvertTo-SecureString -String $SecretValue -AsPlainText -Force

$SetAzKVSecret = @{
    VaultName   = $KVName
    Name        = $AcrUserSecretName
    SecretValue = $SecretValueSecure
}
Set-AzKeyVaultSecret @SetAzKVSecret

Write-Host "Secret ($SecretName) created or updated"

# Container registry admin password 

$SecretValue = (Get-AzContainerRegistryCredential -ResourceGroupName $ResourceGroupName -Name $ACRName).Password
$SecretValueSecure = ConvertTo-SecureString -String $SecretValue -AsPlainText -Force

$SetAzKVSecretParams = @{
    VaultName   = $KVName
    Name        = $AcrPassSecretName
    SecretValue = $SecretValueSecure
}

Set-AzKeyVaultSecret @SetAzKVSecretParams
Write-Host "Secret ($SecretName) created or updated."


#endregion

#region Push Image to the ACR

# Push the local Docker image to the Azure Container Registry 

# Log in to registry 
$ACRNameObj = Get-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Name $ACRName
$ACRCred = Get-AzContainerRegistryCredential -Registry $ACRNameObj

# Call docker login, passing in password 
$ACRCred.Password | docker login $ACRNameObj.LoginServer --username $ACRCred.Username --password-stdin

# Tag image 
$ImagePath = $ACRNameObj.LoginServer + '/' + $ACRPath
docker tag mssql-bak-bacpac $ImagePath

# Push image to repository 
docker push $ImagePath


#endregion

<#
# Clean up
Remove-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Name $ACRName
#>

# Clean up 
<#
. .\container\PowerShell\variables.ps1
Remove-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KVName
#>


<#
# Clean up 
Remove-AzResourceGroup -Name $ResourceGroupName 
#>
