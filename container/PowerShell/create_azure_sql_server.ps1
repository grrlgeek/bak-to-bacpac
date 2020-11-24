# Create SQL server for SQL Database to exist on 

# Load Variables

. .\container\PowerShell\variables.ps1

$SqlAdminPass = Read-Host -Prompt "Please enter an administrator password:" | ConvertTo-SecureString -AsPlainText -Force 
$SqlAdminCred = New-Object System.Management.Automation.PSCredential($SqlAdminUser, $SqlAdminPass)

if (-not (Get-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -ErrorAction SilentlyContinue)) {
    $AzSQlParams = @{
        ResourceGroupName           = $ResourceGroupName
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

    New-AzSqlServer @AzSQlParams

    Write-Host "SQL server ($SqlServerName) created."
} else {
    Write-Host "SQL server ($SqlServerName) exists."
}

# Create firewall rule for Azure resources

$SqlFWRuleParams = @{
    ResourceGroupName = $ResourceGroupName
    ServerName        = $SqlServerName
    AllowAllAzureIPs  = $true
}

New-AzSqlServerFirewallRule @SqlFWRuleParams

# Store SQL server admin password in Key Vault
$SecretName = "$SqlServerName-admin"
$SecretValueSecure = $SqlAdminPass

$SetAzSecretParams = @{
    VaultName   = $KVName 
    Name        = $SecretName 
    SecretValue = $SecretValueSecure
}
Set-AzKeyVaultSecret @SetAzSecretParams
Write-Host "Secret ($SecretName) created or updated."

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