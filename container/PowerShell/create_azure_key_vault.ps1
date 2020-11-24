# Create Azure Key Vault to store secrets.

# Load Variables

. .\container\PowerShell\variables.ps1

if (-not (Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KVName -ErrorAction SilentlyContinue)) {
    $AzKVParams = @{
        Name              = $KVName
        ResourceGroupName = $ResourceGroupName
        Location          = $Location
    }
    New-AzKeyVault @AzKVParams -
    Write-Host "Key Vault ($KVName) created."
} else {
    Write-Host "Key Vault ($KVName) exists."
}

$SetAzKVAccessPolicy = @{
    VaultName = $KVName
    UserPrincipalName = $UserForKeyVault
    PermissionsToSecrets = 'get','set','delete'
}
Set-AzKeyVaultAccessPolicy @SetAzKVAccessPolicy
# Clean up 
<#
. .\container\PowerShell\variables.ps1
Remove-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KVName
#>