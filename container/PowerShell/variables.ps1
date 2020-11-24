#region local docker image variables

# this is the password for the sa account for the container
if(-not ($containerSaPassword)){
    $containerSaPassword = Get-Credential -Message "Enter a password for the sa account for the container"
}

# Set the temp area so this works x-plat

$dockertempdir = [system.io.path]::GetTempPath() + 'docker/'
if(-not(Test-Path $dockertempdir)){
    New-Item $dockertempdir -ItemType Directory
}
$dockertempcreateimage = "$dockertempdir\create_docker_image.sh"



# This is the path on the host to the directory for testing the image and container
# If you are on Windows and using WSL use the format /mnt/DRIVELETTER/Directory
# If you are using Windows use DRIVELETTER:\PathtoDirectory

$localDockerHostDirectory = '/mnt/f/BackupShare'

#endregion


$RGName = 'sqlcontainers' 
$Location = 'northeurope'
$KVName = 'beardkvsqlcontainers' # must be unique across Azure
$StorageAccountName = 'beardsqlbaks' # must be unique across Azure
$ShareName = 'baks'
$AcctKeySecretName = 'storage-acct-key'
$UserForKeyVault = 'mrrobsewell_gmail.com#EXT#@mrrobsewellgmail.onmicrosoft.com'
$ACRName = 'beardacrsqlcontainers'  # must be unique across Azure
$AcrUserSecretName = 'acr-pull-user'
$AcrPassSecretName = 'acr-pull-pass' 
$SqlServerName = 'beardsqldbsfrombak'
$SqlAdminUser = 'sql-admin'
$ACRPath = 'sql/bak-bacpac:latest'
$onprembackupdirectory = 'F:\BackupShare'
$ShareFolderPath = '\'
$ContainerGroupName = 'aci-sql-bak-bacpac'
$VolumeMountPath  = '/mnt/external'
$SQLDB = 'importedbak'
$sqlEdition = 'BusinessCritical'
$sqlSLO = 'BC_Gen5_2'

