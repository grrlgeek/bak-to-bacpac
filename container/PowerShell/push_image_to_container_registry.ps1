# Push the local Docker image to the Azure Container Registry 

$RGName = 'sqlcontainers' 
$ACRName = 'acrsqlcontainers'
$ACRPath = 'sql/mdf-bacpac:latest'

# Log in to registry 
$ACRNameObj = Get-AzContainerRegistry -ResourceGroupName $RGName -Name $ACRName
$ACRCred = Get-AzContainerRegistryCredential -Registry $ACRNameObj

# Call docker login, passing in password 
$ACRCred.Password | docker login $ACRNameObj.LoginServer --username $ACRCred.Username --password-stdin

# Tag image 
$ImagePath = $ACRNameObj.LoginServer + '/' + $ACRPath
docker tag mssql-mdf-bacpac $ImagePath

# Push image to repository 
docker push $ImagePath
