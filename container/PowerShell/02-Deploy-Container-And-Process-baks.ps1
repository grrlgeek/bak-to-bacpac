<#
This will deploy the image to an Azure Container Instance Group 

which will process the backups in the storage account and create the bacpacs

It also has the code to upload the files from the onprem backup store to the fileshare for demos
#>

# Load Variables

# Make sure your prompt is at the root of the repository and run.

. .\container\PowerShell\variables.ps1

#region For demos to upload files to storage account

<#

$Files = Get-ChildItem $onprembackupdirectory\*.bak

$ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Context

foreach ($file in $files) {
    Write-Host "Uploading $($File.FullName)"
    $SetAzFileContentParams = @{
        Context   = $ctx
        ShareName = $ShareName
        Source    = $file.FullName
        Path      = "$ShareFolderPath\$($File.Name)"
        Force     = $true
    }
    Set-AzStorageFileContent @SetAzFileContentParams
}

#>

#endregion


#region Create a new Azure Container Instance group 

#region Variables
$SA_PASSWORD = $containerSaPassword.GetNetworkCredential().Password
$ACRLoginServer = (Get-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Name $ACRName).LoginServer 
$ACRUser = (Get-AzKeyVaultSecret -VaultName $KVName  -Name 'acr-pull-user').SecretValueText 
$ACRPass = (Get-AzKeyVaultSecret -VaultName $KVName -Name 'acr-pull-pass').SecretValue 
$ACRCred = New-Object System.Management.Automation.PSCredential ($ACRUser, $ACRPass) 
$EnvVariables = @{ ACCEPT_EULA = "Y"; SA_PASSWORD = $SA_PASSWORD; MSSQL_PID = "Enterprise"; }
$StorageAcctKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value | ConvertTo-SecureString -AsPlainText -Force 
$StorageAcctCred = New-Object System.Management.Automation.PSCredential($StorageAccountName, $StorageAcctKey)
#endregion

if (-not(Get-AzContainerGroup -ResourceGroupName $ResourceGroupName -Name $ContainerGroupName -ErrorAction SilentlyContinue)) {
    $NewContainerGroupParams = @{
        Name                             = $ContainerGroupName
        ResourceGroupName                = $ResourceGroupName
        Image                            = "$ACRLoginServer/$ACRPath"
        RegistryServerDomain             = $ACRLoginServer
        RegistryCredential               = $ACRCred
        DnsNameLabel                     = $ContainerGroupName
        IpAddressType                    = 'Public'
        EnvironmentVariable              = $EnvVariables
        AzureFileVolumeAccountCredential = $StorageAcctCred
        AzureFileVolumeShareName         = $ShareName
        AzureFileVolumeMountPath         = $VolumeMountPath
        OsType                           = 'Linux'
        Cpu                              = 2
        MemoryInGB                       = 4
    }
    New-AzContainerGroup @NewContainerGroupParams

    Write-Host "Container group ($ContainerGroupName) created."
}else {
    Write-Host "Container group ($ContainerGroupName) exists."
}

#endregion
<#
# Clean up 
Remove-AzContainerGroup `
    -ResourceGroupName $ResourceGroupName `
    -Name $ContainerGroupName
#>