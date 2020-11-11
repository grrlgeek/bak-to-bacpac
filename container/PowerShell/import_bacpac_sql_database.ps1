# Import .bacpac from File Share to Azure SQL Database

$RGName = 'sqlcontainers'
$KVName = 'kvsqlcontainers20201026'
$StorageAcctName = 'customersqlmdfs'
$StorageAcctKey = (Get-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAcctName)[0].Value 
$StorageAcctFileShareName = 'mdfs'
$StorageContext = (Get-AzStorageAccount -ResourceGroupName $RGName -Name $StorageAcctName).Context
$StorageFileShareObj = Get-AzStorageFile -ShareName $StorageAcctFileShareName -Context $StorageContext
$Filtered = $StorageFileShareObj | Where-Object {$_.name -like '*.bacpac'}
$FileName = $Filtered.Name
$SASToken = New-AzStorageAccountSASToken -Service Blob,File,Table,Queue -ResourceType Service,Container,Object -Permission "racwdlup" -Context $StorageContext
#$StorageUriFileShare = "https://$StorageAcctName.file.core.windows.net/$StorageAcctFileShareName/$FileName"
$StorageUriFileShareSAS = "https://$StorageAcctName.file.core.windows.net/$StorageAcctFileShareName/$FileName$SASToken"
$StorageUriBlob = "https://$StorageAcctName.blob.core.windows.net/$StorageAcctFileShareName/$FileName"
$StorageUriBlobSAS = "https://$StorageAcctName.blob.core.windows.net/$StorageAcctFileShareName/$FileName$SASToken"
$SqlServerName = 'customerdbsfrommdf'
$SqlAdminUser = (Get-AzSqlServer -ResourceGroup $RGName -Name $SqlServerName).SqlAdministratorLogin
$SqlAdminPass =  (Get-AzKeyVaultSecret -VaultName $KVName -Name "$SqlServerName-admin").SecretValue 
$SQLDB = 'importedmdf'
$sqlEdition = 'BusinessCritical'
$sqlSLO = 'BC_Gen5_2'

#Move file using azcopy 
azcopy login
azcopy copy $StorageUriFileShareSAS $StorageUriBlobSAS 

Write-Output "Importing bacpac..."
$importRequest = New-AzSqlDatabaseImport `
    -DatabaseName $SQLDB `
    -Edition $sqlEdition `
    -ServiceObjectiveName $sqlSLO `
    -DatabaseMaxSizeBytes "$(10 * 1024 * 1024 * 1024)" `
    -ServerName $SqlServerName `
    -StorageKeyType 'StorageAccessKey' `
    -StorageKey $StorageAcctKey `
    -StorageUri $StorageUriBlob `
    -AdministratorLogin $SqlAdminUser `
    -AdministratorLoginPassword $SqlAdminPass `
    -ResourceGroupName $RGName 
do {
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    Start-Sleep -s 10
} while ($importStatus.Status -eq "InProgress")

