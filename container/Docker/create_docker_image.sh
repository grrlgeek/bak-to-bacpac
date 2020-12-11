docker build -t mssql-bak-bacpac .

# docker run --name bak-to-bacpac mssql-bak-bacpac

# An SA_PASSWORD must be entered here and 
# and the directory where the bak files are on your PC
# If running in WSL use the format /mnt/DRIVELETTER/Directory

 docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=__SA_PASSWORD__" -v __LOCAL_HOST_DIRECTORY__:/mnt/external  --name bak-to-bacpac mssql-bak-bacpac