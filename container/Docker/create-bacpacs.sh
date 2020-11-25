# loop until SQL is ready
echo "SELECT * FROM SYS.DATABASES" | dd of=testsqlconnection.sql
for i in {1..60};
do
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SApassword -d master -i testsqlconnection.sql
    if [ $? -eq 0 ]
    then
        echo "sql server ready"
        break
    else
        echo "not ready yet..."
        sleep 1
    fi
done
rm testsqlconnection.sql

/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d master -i "/create_procedure_restoreheaderonly.sql"
/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d master -i "/create_procedure_restoredatabase.sql"
#run the setup script to create the DB and the schema in the DB
#do this in a loop because the timing for when the SQL instance is ready is indeterminate
for f in /mnt/external/*.bak;
do
    s=${f##*/}
    name="${s%.*}"
    extension="${s#*.}"
    echo "Restoring $f..."
    /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d master -q "EXEC dbo.restoredatabase '/mnt/external/$name.$extension', '$name'"
    echo "Creating bacpac..."
    /sqlpackage/sqlpackage -a:"Export" -ssn:"localhost" -su:"sa" -sp:"$SA_PASSWORD" -sdn:"$name" -tf:"/mnt/external/$name.bacpac"
done