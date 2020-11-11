# This script will create a docker container using the mssql-mdf-bacpac image 
# An SA_PASSWORD must be enetered here 
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=" `
-v C:/Docker/mdf:/mnt/external `
--name mdf-to-bacpac mssql-mdf-bacpac