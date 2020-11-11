# Use function SetupStorage to create Storage Account, File Share, and Account Key 

$RGName = 'sqlcontainers' 
$Location = 'eastus'
$StorageAccountName = 'customersqlbaks' # must be unique across Azure
$ShareName = 'baks'
$KVName = 'kvsqlcontainers'

$StorageAccountCredentials = SetupStorage `
    -StorageResourceGroupName $RGName `
    -StorageAccountName $StorageAccountName `
    -ShareName $ShareName `
    -Location $Location

# Put storage account key in key vault 

# Storage account key 
$SecretName = 'storage-acct-key' 
$SecretValue = (Get-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAccountName)[0].Value
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
