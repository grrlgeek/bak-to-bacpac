# Using an Azure Container Instance to convert BAK to BACPAC for Import into Azure SQL Database 
Importing an existing SQL Server database into an Azure SQL Database is not a trivial task. You can only import a .bacpac file - you can't attach a database or restore a backup. In some cases, you may not have direct access to the database to create a .bacpac, but you have the database .mdf or a .bak backup file available. This project will ingest a SQL Server .bak file into Azure File Share, create an Azure Container Instance running SQL Server, restore the database, and create a bacpac for import into Azure SQL Database.

## Overview

This code will create a Docker container based on the mssql-latest image. The container is modified to include the mssql-tools and sqlpackage.exe. The container then executes a script to find a .bak in a directory, restore it to the SQL Server engine, and run sqlpackage.exe Export to convert it to a .bacpac. Once the container is created locally, it is pushed to an Azure Container Registry. Then an Azure Container Instance is created, an Azure Storage File Share containing the .bak is mounted, and the script to convert the .bak to a .bacpac is executed. Then the .bacpac is copied from the File Share to a Blob Container, and is imported into a new Azure SQL Database.

## Prerequisites

* [Docker Desktop](https://www.docker.com/products/docker-desktop) (for testing containers locally)
* [Azure subscription](https://azure.microsoft.com/en-us/free/)
* [Azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* [Azure PowerShell - Az module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.5.0)

If you would like a .bak file to test with, go to [AdventureWorks sample databases](https://github.com/Microsoft/sql-server-samples/releases/tag/adventureworks).

## Steps

These steps assume you have no resources created in Azure. If you have a resource group and a key vault, for example, replace the parameters in the [variables.ps1](container/PowerShell/variables.ps1) with your values.

Start by filling in the [variables.ps1](container/PowerShell/variables.ps1) file with the names that you want to use for the resources that will be created.

There are 4 scripts that will perform the actions using the values in the variables file.

- [00-Create-Local-Docker-Container.ps1](container\PowerShell\00-Create-Local-Docker-Container.ps1) This will build the image with all the required files and scripts. It also has the script to run the image locally and process bak files in the localDockerHostDirectory

- [01-Create-Azure-Resources.ps1](container\PowerShell\01-Create-Azure-Resources.ps1) This will create the Azure Resources using the values in the variables file.

- [02-Deploy-Container-And-Process-baks.ps1](container\PowerShell\02-Deploy-Container-And-Process-baks.ps1) This will deploy the image to an Azure Container Instance Group,
which will process the backups in the storage account and create the bacpacs.
It also has the code to upload the files from the onprem backup store to the fileshare for demos.

- [03-Create-AzureSQLServer-And-Import-BacPacs.ps1](container\PowerShell\03-Create-AzureSQLServer-And-Import-BacPacs.ps1) This script will create the Azure SQL Server if it does not exist and
import the bacpacs from Azure Storage and create the databases.

It will also create a firewall rule and store or update the sql server admin password in Key Vault

## Future Enhancements

This code is complete but several enhancements could be made in the future to improve it, including:

* Create an Azure Function to run the scripts when a .bak lands in the File Share. There does not appear to be a FileWatcher event handler available for Azure File Share which means options could be attach the share to a VM and then use Windows to listen for the file, or poll for new files.
* Modify 01-Create-Azure-Resources.ps1 to create a Network Security Group and use that, rather than "Allow all IPS".
* Detach database after .bacpac is created.
* Build in monitoring to determine when the process is finished and send a notification.
