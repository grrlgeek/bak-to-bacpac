# Create function to create storage account and file share, and generate key 

function New-ContainerStorageSetUp {
    param( [string]$StorageResourceGroupName, 
        [string]$StorageAccountName, 
        [string]$ShareName,
        [string]$Location)

    # check if storage account exists

    $StorageAcctParams = @{
        ResourceGroupName = $StorageResourceGroupName
        Name              = $StorageAccountName
        ErrorAction       = 'SilentlyContinue'
    }
    $StorageAccount = Get-AzStorageAccount @StorageAcctParams

    if ($null -eq $StorageAccount) {
        # create the storage account
        $StorageAccount = New-AzStorageAccount @StorageAcctParams -Location $Location -SkuName Standard_LRS
    }

    # check if the file share already exists

    $AzShareParams = @{
        Name        = $ShareName
        Context     = $StorageAccount.Context
        ErrorAction = 'SilentlyContinue'
    }

    $Share = Get-AzStorageShare @AzShareParams

    if ($null -eq $Share) {
        # create the share
        $Share = New-AzStorageShare @AzShareParams
    }

    <# Add a container for blob storage also, same name #>
    # check if the file share already exists

    $AzStorageContainerParams = @{
        Name        = $ShareName
        Context     = $StorageAccount.Context
        ErrorAction = 'SilentlyContinue'
    }
    $Container = Get-AzStorageContainer @AzStorageContainerParams

    if ($null -eq $Container) {
        # create the container
        $Container = New-AzStorageContainer @AzStorageContainerParams
    }
    <# End blob storage #>

    # get the credentials
    $StorageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName $StorageResourceGroupName -Name $StorageAccountName
    $StorageAccountKey = $StorageAccountKeys[0].Value
    $StorageAccountKeySecureString = ConvertTo-SecureString $StorageAccountKey -AsPlainText -Force
    $StorageAccountCredentials = New-Object System.Management.Automation.PSCredential ($StorageAccountName, $StorageAccountKeySecureString)

    $StorageAccountCredentials
}
