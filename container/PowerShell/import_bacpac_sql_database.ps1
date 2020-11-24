# Import .bacpac from File Share to Azure SQL Database

# Load Variables

. .\container\PowerShell\variables.ps1

azcopy login --tenant-id $AZContext.Tenant.Id

$SqlAdminUser = (Get-AzSqlServer -ResourceGroup $ResourceGroupName -Name $SqlServerName).SqlAdministratorLogin
$SqlAdminPass = (Get-AzKeyVaultSecret -VaultName $KVName -Name "$SqlServerName-admin").SecretValue
$StorageAcctKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value 
$StorageContext = (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Context
$StorageFileShareObj = Get-AzStorageFile -ShareName $ShareName -Context $StorageContext
$Filtered = $StorageFileShareObj | Where-Object { $_.name -like '*.bacpac' }
foreach ($File in $Filtered) {
    $FileName = $File.Name
    $SASToken = New-AzStorageAccountSASToken -Service Blob, File, Table, Queue -ResourceType Service, Container, Object -Permission "racwdlup" -Context $StorageContext
    $StorageUriFileShareSAS = "https://$StorageAccountName.file.core.windows.net/$ShareName/$FileName$SASToken"
    $StorageUriBlob = "https://$StorageAccountName.blob.core.windows.net/$ShareName/$FileName"
    $StorageUriBlobSAS = "https://$StorageAccountName.blob.core.windows.net/$ShareName/$FileName$SASToken"

    azcopy copy $StorageUriFileShareSAS $StorageUriBlobSAS 

    
Write-Output "Importing bacpac  $FileName ..."
$Random = Get-Random -Minimum 1 -Maximum 99999
$ImportBacPacParams = @{
    DatabaseName =  "$SQLDB-$Random"
    Edition =  $sqlEdition
    ServiceObjectiveName =  $sqlSLO
    DatabaseMaxSizeBytes =  "$(10 * 1024 * 1024 * 1024)"
    ServerName =  $SqlServerName
    StorageKeyType =  'StorageAccessKey'
    StorageKey =  $StorageAcctKey
    StorageUri =  $StorageUriBlob
    AdministratorLogin =  $SqlAdminUser
    AdministratorLoginPassword =  $SqlAdminPass
    ResourceGroupName =  $ResourceGroupName
}
$importRequest = New-AzSqlDatabaseImport @ImportBacPacParams
do {
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    Start-Sleep -s 10
} while ($importStatus.Status -eq "InProgress")
}


Write-Output "Importing bacpac..."
$ImportBacPacParams = @{
    DatabaseName =  $SQLDB
    Edition =  $sqlEdition
    ServiceObjectiveName =  $sqlSLO
    DatabaseMaxSizeBytes =  "$(10 * 1024 * 1024 * 1024)"
    ServerName =  $SqlServerName
    StorageKeyType =  'StorageAccessKey'
    StorageKey =  $StorageAcctKey
    StorageUri =  $StorageUriBlob
    AdministratorLogin =  $SqlAdminUser
    AdministratorLoginPassword =  $SqlAdminPass
    ResourceGroupName =  $ResourceGroupName
}
$importRequest = New-AzSqlDatabaseImport @ImportBacPacParams
do {
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    Start-Sleep -s 10
} while ($importStatus.Status -eq "InProgress")

