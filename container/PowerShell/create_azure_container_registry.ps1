# Create Azure Container Registry

# Load Variables

. .\container\PowerShell\variables.ps1

if (-not(Get-AzContainerRegistry -ResourceGroupName $RGName -Name $ACRName -ErrorAction SilentlyContinue)) {

    $AzContainerRegistryParams = @{
        ResourceGroupName = $RGName
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

$SecretValue = (Get-AzContainerRegistryCredential -ResourceGroupName $RGName -Name $ACRName).Username
$SecretValueSecure = ConvertTo-SecureString -String $SecretValue -AsPlainText -Force

$SetAzKVSecret = @{
    VaultName   = $KVName
    Name        = $AcrUserSecretName
    SecretValue = $SecretValueSecure
}
Set-AzKeyVaultSecret @SetAzKVSecret

Write-Host "Secret ($SecretName) created or updated"

# Container registry admin password 

$SecretValue = (Get-AzContainerRegistryCredential -ResourceGroupName $RGName -Name $ACRName).Password
$SecretValueSecure = ConvertTo-SecureString -String $SecretValue -AsPlainText -Force

$SetAzKVSecretParams = @{
    VaultName   = $KVName
    Name        = $AcrPassSecretName
    SecretValue = $SecretValueSecure
}

Set-AzKeyVaultSecret @SetAzKVSecretParams
Write-Host "Secret ($SecretName) created or updated."

<# 
# Clean up 
Remove-AzContainerRegistry -ResourceGroupName $RGName -Name $ACRName
#>
