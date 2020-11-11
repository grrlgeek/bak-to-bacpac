# Options for moving MDF into Azure SQL database 

One of the requirements for the RATOS project is to receive an MDF database file from a customer and move that data into an Azure SQL database. Azure SQL PaaS offerings don't allow a direct ATTACH operation to be performed. There are two options that can be used to transform the MDF into a BACPAC, which can be imported in a database: 
* SQL Server in Azure Virtual Machine 
* SQL Server in Azure Container Instance 

Long-term, having customers provide a BAK (backup) instead of MDF (data file) would allow for an easier, all-PaaS solution. 

## IaaS - SQL Server in Azure Virtual Machine 
A virtual machine running SQL Server could be used to convert the MDF to a BACPAC. The steps would be: 
* Use PowerShell or an ARM template to create a SQL Server VM. 
* Use AzCopy to move the MDF from an Azure blob storage container to VM storage. 
* Use T-SQL to attach the MDF. 
* Use sqlpackage.exe Export to create a BACPAC from the MDF. 
* Use AzCopy to move the BACPAC to blob storage. 
* Use PowerShell or sqlpackage.exe to import the BACPAC into the SQL database. 

### Pros 
* Full version of SQL Server can be used for other tasks as needed. 
* Can use any version of SQL Server. 

### Cons 
* Requires the most maintenance - OS patching, SQL Server patching, and scheduling of start-up and shut down. 
* VMs are the most complex solution to implement - compute, disk, NIC, and more must be managed. 

## PaaS - SQL Server in Azure Container Instance 
SQL Server can run on Linux or Windows containers. Implementing an Azure Container Instance running SQL Server on Ubuntu is quick and requires less maintenance than a VM. The steps to implement would be: 
* Use PowerShell or CLI to create a Container Instance using a SQL Server on Ubuntu image.  
* Use AzCopy to move the MDF from an Azure blob storage container to an Azure file share container. 
* Use PowerShell to attach the file share to the container. 
* Use T-SQL to attach the MDF. 
* Use sqlpackage.exe Export to create a BACPAC from the MDF. 
* Use AzCopy to move the BACPAC to blob storage. 
* Use PowerShell or sqlpackage.exe to import the BACPAC into the SQL database. 

### Pros  
* Containers are lightweight, so they are much faster to start up. 
* Instead of patching the OS or SQL Server like a VM, a container can be destroyed and recreated using the "latest" image tag, ensuring it is always up-to-date. 
* Attaching the file share to the container ensures that if the container experiences a shutdown, the data is not lost. 

### Cons 
* Still requires the MDF to BACPAC conversion. 

## Long-term - BAK instead of MDF 
Having a customer provide an MDF file presents technical difficulties and security issues. There are no options to restore an MDF to any Azure SQL Database PaaS offerings. It's also highly unusual to provide a copy of a database, rather than a backup of a point in time. 

If you were to change the file requirement to a backup (a SQL Server .bak file), it would be very simple to create an Azure SQL Managed Instance and restore the backup. See the details in [Native RESTORE from URL](https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/migrate-to-instance-from-sql-server#native-restore-from-url). 