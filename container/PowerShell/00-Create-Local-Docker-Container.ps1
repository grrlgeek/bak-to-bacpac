<# 
A Script to create the container image and then to run a test if you wish (or for demos)

This will create an image called mssql-bak-bacpac and using the values set in the local 
docker region of the variables file run the container and process any .bak files that you 
have placed in the directory referenced in $localDockerHostDirectory

#>
# First Set the variables in the variables.ps1 file to the required values
# This will provide a credential prompt, the user is not important, the password will
# be the SA password for the container

# Make sure your prompt is at the root of the repository and run.

. ./container/PowerShell/variables.ps1 

# This will build the image and name it mssql-bak-bacpac

Set-Location ./container/Docker

docker build -t mssql-bak-bacpac .

# This will create a local container named bak-to-bacpac from the mssql-bak-bacpac image and run it
# This will process any .bak files in the localDockerHostDirectory

$localdockerrun = ('docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=__SA_PASSWORD__" -v __LOCAL_HOST_DIRECTORY__:/mnt/external  --name bak-to-bacpac mssql-bak-bacpac' -replace '__SA_PASSWORD__', $containerSaPassword.GetNetworkCredential().Password -replace '__LOCAL_HOST_DIRECTORY__',$localDockerHostDirectory)

Invoke-Expression $localdockerrun

<#
To remove the container
docker container rm bak-to-bacpac
#>