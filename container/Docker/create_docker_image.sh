# Create Docker image locally from Dockerfile 

docker build -t mssql-bak-bacpac .

docker run --name bak-to-bacpac mssql-bak-bacpac
