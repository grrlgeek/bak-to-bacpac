# Create SQL server for SQL Database to exist on 

#region Variables - These are the things to alter for your own system
$RGName = 'sqlcontainers' 
$Location = 'eastus'
$SqlServerName = 'customerdbsfrombak'
$SqlAdminUser = 'sql-admin'
$SqlAdminPass = Read-Host -Prompt "Please enter an administrator password:" | ConvertTo-SecureString -AsPlainText -Force 
$SqlAdminCred = New-Object System.Management.Automation.PSCredential($SqlAdminUser, $SqlAdminPass)
$KVName = 'kvsqlcontainers'

#endregion

#region Create Resources - This will create the resources if they do not exist

if (-not(Get-AzSqlServer -ResourceGroupName $RGName -ServerName $SqlServerName -ErrorAction SilentlyContinue)) {
    $AzSQLServerParams = @{
        ResourceGroupName           = $RGName
        ServerName                  = $SqlServerName
        Location                    = $Location
        SqlAdministratorCredentials = $SqlAdminCred
    }
    New-AzSqlServer @$AzSQLServerParams

    Write-Host "SQL server ($SqlServerName) created."
}
else {
    Write-Host "SQL server ($SqlServerName) exists."
}

# Create firewall rule for Azure resources 

$AzSqlServerFirewallRuleParams = @(
    ResourceGroupName =  $RGName 
    ServerName =  $SqlServerName 
    AllowAllAzureIPs = $true
)
New-AzSqlServerFirewallRule @AzSqlServerFirewallRuleParams

# Store SQL server admin password in Key Vault 
$SecretName = "$SqlServerName-admin" 
$SecretValueSecure = $SqlAdminPass

$SecretExists = Get-AzKeyVaultSecret -VaultName $KVName -Name $SecretName 
if ($SecretExists -eq $null) {
    Set-AzKeyVaultSecret `
        -VaultName $KVName `
        -Name $SecretName `
        -SecretValue $SecretValueSecure
        
    Write-Host "Secret ($SecretName) created."
}
else {
    Write-Host "Secret ($SecretName) exists."
}

#endregion
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