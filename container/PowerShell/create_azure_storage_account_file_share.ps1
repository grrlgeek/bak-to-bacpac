# Use function SetupStorage to create Storage Account, File Share, and Account Key 

# Load Variables

. .\container\PowerShell\variables.ps1
. .\container\PowerShell\create_setupstorage_function.ps1

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

