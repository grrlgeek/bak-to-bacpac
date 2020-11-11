# Create Azure Container Registry 

$RGName = 'sqlcontainers' 
$Location = 'eastus'
$ACRName = 'acrsqlcontainers'
$KVName = 'kvsqlcontainers'

$ACRExists = Get-AzContainerRegistry -ResourceGroupName $RGName -Name $ACRName -ErrorAction SilentlyContinue
if ($ACRExists -eq $null)
    {
        New-AzContainerRegistry `
            -ResourceGroupName $RGName `
            -Name $ACRName `
            -Location $Location `
            -Sku "Basic" `
            -EnableAdminUser

        Write-Host "Container registry ($ACRName) created."
    }
else 
    {
        Write-Host "Container registry ($ACRName) exists."
    }

# Store admin username and password in Key Vault 
# Container registry admin username 
$SecretName = 'acr-pull-user' 
$SecretValue = (Get-AzContainerRegistryCredential -ResourceGroupName $RGName -Name $ACRName).Username 
$SecretValueSecure = ConvertTo-SecureString -String $SecretValue -AsPlainText -Force

$SecretExists = Get-AzKeyVaultSecret -VaultName $KVName -Name $SecretName 
if ($SecretExists -eq $null)
    {
        Set-AzKeyVaultSecret `
            -VaultName $KVName `
            -Name $SecretName `
            -SecretValue $SecretValueSecure
        
        Write-Host "Secret ($SecretName) created."
    }
else 
{
    Write-Host "Secret ($SecretName) exists."
}


# Container registry admin password 
$SecretName = 'acr-pull-pass' 
$SecretValue = (Get-AzContainerRegistryCredential -ResourceGroupName $RGName -Name $ACRName).Password
$SecretValueSecure = ConvertTo-SecureString -String $SecretValue -AsPlainText -Force

$SecretExists = Get-AzKeyVaultSecret -VaultName $KVName -Name $SecretName 
if ($SecretExists -eq $null)
    {
        Set-AzKeyVaultSecret `
            -VaultName $KVName `
            -Name $SecretName `
            -SecretValue $SecretValueSecure
        
        Write-Host "Secret ($SecretName) created."
    }
else 
{
    Write-Host "Secret ($SecretName) exists."
}

<# 
# Clean up 
Remove-AzContainerRegistry -ResourceGroupName $RGName -Name $ACRName
#>
