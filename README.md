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

These steps assume you have no resources created in Azure. If you have a resource group and a key vault, for example, replace the parameters in the following scripts with your values.

| Step                                          | File                                                                                                     |
|---------                                      |--------                                                                                                  |
|Create Dockerfile locally                      | [Dockerfile](Docker/Dockerfile)                                                                          |
|Create image                                   | [create_docker_image.sh](Docker/create_docker_image.sh)                                                  |
|Create container locally                       | [local_docker_run_command.sh](Docker/local_docker_run_command.sh)                                        |
|Create Azure Resource Group                    | [create_azure_resource_group.ps1](PowerShell/create_azure_resource_group.ps1)                            |
|Create Azure Key Vault                         | [create_azure_key_vault.ps1](PowerShell/create_azure_key_vault.ps1)                                      |
|Create Azure Storage function                  | [create_setupstorage_function.ps1](PowerShell/create_setupstorage_function.ps1)                          |
|Create Azure Storage File Share                | [create_azure_storage_account_file_share.ps1](PowerShell/create_azure_storage_account_file_share.ps1)    |
|Create Azure Container Registry                | [create_azure_container_registry.ps1](PowerShell/create_azure_container_registry.ps1)                    |
|Create Azure SQL server                        | [create_azure_sql_server.ps1](PowerShell/create_azure_sql_server.ps1)                                    |
|Push image to Azure Container Registry         | [push_image_to_azure_container_registry.ps1](PowerShell/push_image_to_azure_container_registry.ps1)      |
|Upload .bak to File Share                      |                                                                                                          |
|Create Azure Container Instance                | [deploy_container.ps1](PowerShell/deploy_container.ps1)                                                  |
|Import .bacpac into SQL Database               | [import_bacpac_sql_database.ps1](PowerShell/import_bacpac_sql_database.ps1)                              |

## Future Enhancements

This code is complete but several enhancements could be made in the future to improve it, including:

* Create an Azure Function to run the scripts when a .bak lands in the File Share.
* Modify create_azure_sql_server.ps1 to create a Network Security Group and use that, rather than "Allow all IPS".
* Detach database after .bacpac is created.
* Build in monitoring to determine when the process is finished and send a notification, using something like Write-Host.
