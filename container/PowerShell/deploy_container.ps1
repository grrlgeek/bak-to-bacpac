# Create a new Azure Container Instance group 

# Load Variables

. .\container\PowerShell\variables.ps1

$SA_PASSWORD = Read-Host -Prompt "Please enter the SA password:"

$ACRLoginServer = (Get-AzContainerRegistry -ResourceGroupName $RGName -Name $ACRName).LoginServer 
$ACRUser = (Get-AzKeyVaultSecret -VaultName $KVName  -Name 'acr-pull-user').SecretValueText 
$ACRPass = (Get-AzKeyVaultSecret -VaultName $KVName -Name 'acr-pull-pass').SecretValue 
$ACRCred = New-Object System.Management.Automation.PSCredential ($ACRUser, $ACRPass) 
$EnvVariables = @{ ACCEPT_EULA = "Y"; SA_PASSWORD = $SA_PASSWORD; MSSQL_PID = "Enterprise"; }
$StorageAcctKey = (Get-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAccountName)[0].Value | ConvertTo-SecureString -AsPlainText -Force 
$StorageAcctCred = New-Object System.Management.Automation.PSCredential($StorageAccountName, $StorageAcctKey)


# Run

if (-not(Get-AzContainerGroup -ResourceGroupName $RGName -Name $ContainerGroupName -ErrorAction SilentlyContinue)) {
    $NewContainerGroupParams = @{
        Name                             = $ContainerGroupName
        ResourceGroupName                = $RGName
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


<#
# Clean up 
Remove-AzContainerGroup `
    -ResourceGroupName $RGName `
    -Name $ContainerGroupName
#>