# Create a new Azure Container Instance group 

$SA_PASSWORD = Read-Host -Prompt "Please enter the SA password:"
$RGName = 'sqlcontainers' 
$KVName = 'kvsqlcontainers20201026'
$ContainerGroupName = 'aci-sql-mdf-bacpac'
$ACRName = 'acrsqlcontainers'
$ACRLoginServer = (Get-AzContainerRegistry -ResourceGroupName $RGName -Name $ACRName).LoginServer 
$ACRUser = (Get-AzKeyVaultSecret -VaultName $KVName  -Name 'acr-pull-user').SecretValueText 
$ACRPass = (Get-AzKeyVaultSecret -VaultName $KVName -Name 'acr-pull-pass').Secre 6yutValue 
$ACRCred = New-Object System.Management.Automation.PSCredential ($ACRUser, $ACRPass) 
$ACRPath = 'sql/mdf-bacpac:latest'
# $EnvVariables = @{ ACCEPT_EULA="Y"; SA_PASSWORD=""; MSSQL_PID="Enterprise";}
$EnvVariables = @{ ACCEPT_EULA="Y"; SA_PASSWORD=$SA_PASSWORD; MSSQL_PID="Enterprise";}
$StorageAcctName = 'customersqlmdfs'
$StorageAcctKey = (Get-AzStorageAccountKey -ResourceGroupName $RGName -Name $StorageAcctName)[0].Value | ConvertTo-SecureString -AsPlainText -Force 
$StorageAcctCred = New-Object System.Management.Automation.PSCredential($StorageAcctName, $StorageAcctKey)
$StorageAcctFileShareName = 'mdfs'
$VolumeMountPath  = '/mnt/external'

# Run 
$CGExists = Get-AzContainerGroup -ResourceGroupName $RGName -Name $ContainerGroupName -ErrorAction SilentlyContinue
if ($CGExists -eq $null)
    {
        New-AzContainerGroup `
            -Name $ContainerGroupName `
            -ResourceGroupName $RGName `
            -Image $ACRLoginServer/$ACRPath  `
            -RegistryServerDomain $ACRLoginServer `
            -RegistryCredential $ACRCred `
            -DnsNameLabel $ContainerGroupName `
            -IpAddressType Public `
            -EnvironmentVariable $EnvVariables `
            -AzureFileVolumeAccountCredential $StorageAcctCred `
            -AzureFileVolumeShareName $StorageAcctFileShareName `
            -AzureFileVolumeMountPath $VolumeMountPath `
            -OsType Linux `
            -Cpu 2 `
            -MemoryInGB 4 

        Write-Host "Container group ($ContainerGroupName) created."
    }
else 
    {
        Write-Host "Container group ($ContainerGroupName) exists."
    }


<#
# Clean up 
Remove-AzContainerGroup `
    -ResourceGroupName $RGName `
    -Name $ContainerGroupName
#>