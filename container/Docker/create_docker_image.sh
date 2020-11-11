# Create Docker image locally from Dockerfile 
# $directory='...\mssql-bacpac-converter-container'
# $image_name='mdf-to-bacpac'

# docker build -t mssql-mdf-bacpac "...\mssql-bacpac-converter-container"
docker build -t mssql-mdf-bacpac "...\container"
# docker build -t mssql-mdf-bacpac $directory

docker run --name mdf-to-bacpac mssql-mdf-bacpac
# docker run --name $image_name mssql-mdf-bacpac