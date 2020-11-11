# Create Docker image locally from Dockerfile 

docker build -t mssql-bak-bacpac .

#docker run --name bak-to-bacpac mssql-bak-bacpac

# An SA_PASSWORD must be enetered here 
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=" `
-v C:/Docker/mdf:/mnt/external `
--name bak-to-bacpac mssql-bak-bacpac
