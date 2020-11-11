# Create function to create storage account and file share, and generate key 

function SetupStorage {
    param( [string]$StorageResourceGroupName, 
           [string]$StorageAccountName, 
           [string]$ShareName,
           [string]$Location)

    # check if storage account exists
    $StorageAccount = Get-AzStorageAccount `
        -ResourceGroupName $StorageResourceGroupName `
        -Name $StorageAccountName `
        -ErrorAction SilentlyContinue

    if ($StorageAccount -eq $null) {
        # create the storage account
        $StorageAccount = New-AzStorageAccount `
            -ResourceGroupName $StorageResourceGroupName `
            -Name $StorageAccountName `
            -SkuName Standard_LRS `
            -Location $Location
    }

    # check if the file share already exists
    $Share = Get-AzStorageShare `
        -Name $ShareName -Context $StorageAccount.Context `
        -ErrorAction SilentlyContinue

    if ($Share -eq $null) {
        # create the share
        $Share = New-AzStorageShare `
            -Name $ShareName `
            -Context $StorageAccount.Context
    }

    <# Add a container for blob storage also, same name #>
    # check if the file share already exists
    $Container = Get-AzStorageContainer `
    -Name $ShareName -Context $StorageAccount.Context `
    -ErrorAction SilentlyContinue

    if ($Container -eq $null) {
        # create the container
        $Container = New-AzStorageContainer `
            -Name $ShareName `
            -Context $StorageAccount.Context
    }
    <# End blob storage #>

    # get the credentials
    $StorageAccountKeys = Get-AzStorageAccountKey `
        -ResourceGroupName $StorageResourceGroupName `
        -Name $StorageAccountName

    $StorageAccountKey = $StorageAccountKeys[0].Value
    $StorageAccountKeySecureString = ConvertTo-SecureString $StorageAccountKey -AsPlainText -Force
    $StorageAccountCredentials = New-Object System.Management.Automation.PSCredential ($StorageAccountName, $StorageAccountKeySecureString)
    
    return $StorageAccountCredentials
}
