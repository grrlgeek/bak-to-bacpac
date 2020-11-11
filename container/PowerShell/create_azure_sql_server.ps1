# Create SQL server for SQL Database to exist on 

$RGName = 'sqlcontainers' 
$Location = 'eastus'
$SqlServerName = 'customerdbsfrommdf'
$SqlAdminUser = 'sql-admin'
$SqlAdminPass = Read-Host -Prompt "Please enter an administrator password:" | ConvertTo-SecureString -AsPlainText -Force 
$SqlAdminCred = New-Object System.Management.Automation.PSCredential($SqlAdminUser, $SqlAdminPass)
$KVName = 'kvsqlcontainers20201012'

$SQLExists = Get-AzSqlServer -ResourceGroupName $RGName -ServerName $SqlServerName -ErrorAction SilentlyContinue
if ($SQLExists -eq $null) 
    {
        New-AzSqlServer `
            -ResourceGroupName $RGName `
            -ServerName $SqlServerName `
            -Location $Location `
            -SqlAdministratorCredentials $SqlAdminCred
                
        Write-Host "SQL server ($SqlServerName) created."
    }
else 
    {
        Write-Host "SQL server ($SqlServerName) exists."
    }

# Create firewall rule for Azure resources 
New-AzSqlServerFirewallRule `
    -ResourceGroupName $RGName `
    -ServerName $SqlServerName `
    -AllowAllAzureIPs

# Store SQL server admin password in Key Vault 
$SecretName = "$SqlServerName-admin" 
$SecretValueSecure = $SqlAdminPass

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
Remove-AzKeyVaultSecret `
    -VaultName $KVName `
    -Name 'sql-admin' `
    -InRemovedState

Remove-AzKeyVaultSecret `
    -VaultName $KVName `
    -Name 'customerdbsfrommdf-admin' `
    -InRemovedState
 #>