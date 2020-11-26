<#
This script will create the Azure SQL Server if it does not exist and
import the bacpacs from Azure Storage and create the databases.

It will also create a firewall rule and store or update the sql server admin password in Key Vault

#>


# Make sure your prompt is at the root of the repository and run.

# Load Variables

. .\container\PowerShell\variables.ps1

#region Create Azure SQL Database
if (-not (Get-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -ErrorAction SilentlyContinue)) {
    $AzSQlParams = @{
        ResourceGroupName           = $ResourceGroupName
        ServerName                  = $SqlServerName
        Location                    = $Location
        SqlAdministratorCredentials = $SqlServerAdminCred
    }
    New-AzSqlServer @AzSQlParams

    Write-Host "SQL server ($SqlServerName) created."
}
else {
    Write-Host "SQL server ($SqlServerName) exists."
}
#endregion

#region Create firewall rule for Azure resources

$SqlFWRuleParams = @{
    ResourceGroupName = $ResourceGroupName
    ServerName        = $SqlServerName
    AllowAllAzureIPs  = $true
}

New-AzSqlServerFirewallRule @SqlFWRuleParams
#endregion

#region Store SQL server admin password in Key Vault
$SecretValueSecure = $SqlServerAdminCred.Password

$SetAzSecretParams = @{
    VaultName   = $KVName 
    Name        = $SqlServerAdminPwdSecretName
    SecretValue = $SecretValueSecure
}
Set-AzKeyVaultSecret @SetAzSecretParams
Write-Host "Secret ($SecretName) created or updated."
#endregion

#region Import .bacpac from File Share to Azure SQL Database

azcopy login --tenant-id $AZContext.Tenant.Id

$SqlAdminUser = (Get-AzSqlServer -ResourceGroup $ResourceGroupName -Name $SqlServerName).SqlAdministratorLogin
$SqlAdminPass = (Get-AzKeyVaultSecret -VaultName $KVName -Name "$SqlServerName-admin").SecretValue
$StorageAcctKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value 
$StorageContext = (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Context
$StorageFileShareObj = Get-AzStorageFile -ShareName $ShareName -Context $StorageContext
$Filtered = $StorageFileShareObj | Where-Object { $_.name -like '*.bacpac' }
foreach ($File in $Filtered) {
    #region copy file from File to Blob
    $FileName = $File.Name
    $SASToken = New-AzStorageAccountSASToken -Service Blob, File, Table, Queue -ResourceType Service, Container, Object -Permission "racwdlup" -Context $StorageContext
    $StorageUriFileShareSAS = "https://$StorageAccountName.file.core.windows.net/$ShareName/$FileName$SASToken"
    $StorageUriBlob = "https://$StorageAccountName.blob.core.windows.net/$ShareName/$FileName"
    $StorageUriBlobSAS = "https://$StorageAccountName.blob.core.windows.net/$ShareName/$FileName$SASToken"

    azcopy copy $StorageUriFileShareSAS $StorageUriBlobSAS 
    #endregion
    
    #region Import bacpac
    Write-Output "Importing bacpac  $FileName ..."
    $dbName = $FileName.Split('.')[0]
    $ImportBacPacParams = @{
        DatabaseName               = $dbName
        Edition                    = $sqlEdition
        ServiceObjectiveName       = $sqlSLO
        DatabaseMaxSizeBytes       = "$(10 * 1024 * 1024 * 1024)"
        ServerName                 = $SqlServerName
        StorageKeyType             = 'StorageAccessKey'
        StorageKey                 = $StorageAcctKey
        StorageUri                 = $StorageUriBlob
        AdministratorLogin         = $SqlAdminUser
        AdministratorLoginPassword = $SqlAdminPass
        ResourceGroupName          = $ResourceGroupName
    }
    $importRequest = New-AzSqlDatabaseImport @ImportBacPacParams
    do {
        $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
        Start-Sleep -s 10
    } while ($importStatus.Status -eq "InProgress")
    #endregion
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