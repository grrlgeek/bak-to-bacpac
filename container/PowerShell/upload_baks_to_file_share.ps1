# Load Variables

. .\container\PowerShell\variables.ps1

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


