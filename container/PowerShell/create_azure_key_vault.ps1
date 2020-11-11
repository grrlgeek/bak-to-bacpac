# Create Azure Key Vault to store secrets. 

$RGName = 'sqlcontainers' 
$Location = 'eastus'
$KVName = 'kvsqlcontainers'

$KVExists = Get-AzKeyVault -ResourceGroupName $RGName -VaultName $KVName -ErrorAction SilentlyContinue
if ($KVExists -eq $null) 
    {
        New-AzKeyVault `
            -Name $KVName `
            -ResourceGroupName $RGName `
            -Location $Location 

        Write-Host "Key Vault ($KVName) created."
    }
else 
    {
        Write-Host "Key Vault ($KVName) exists."
    }

# Clean up 
<#
Remove-AzKeyVault `
    -ResourceGroupName $RGName `
    -VaultName $KVName
#>