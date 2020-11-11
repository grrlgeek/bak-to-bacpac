RESTORE FILELISTONLY 
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\AdventureWorks2019.bak';

--Need to provide database name, backup location and name, data file logical name, data file physical location and name, log file logical name, log file physical location and name 
RESTORE DATABASE AdventureWorks2019 
FROM DISK='C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\AdventureWorks2019.bak'
WITH 
MOVE 'AdventureWorks2017' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\\AdventureWorks2019.mdf', 
MOVE 'AdventureWorks2017_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\\AdventureWorks2019_log.ldf',
NORECOVERY; 

RESTORE DATABASE ImportedDB FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\AdventureWorks2019.bak' WITH   MOVE 'AdventureWorks2017' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\AdventureWorks2017.mdf', MOVE 'AdventureWorks2017_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\AdventureWorks2017_log.ldf'



RESTORE DATABASE AdventureWorks2014 
WITH RECOVERY; 

-----------------------------------------------------

USE master; 
GO 

-- Create the stored procedure to create the headeronly output 
SET NOCOUNT ON 
GO 
CREATE PROCEDURE dbo.restoreheaderonly 
	@backuplocation VARCHAR(MAX)  
AS 
	BEGIN
		RESTORE FILELISTONLY 
		FROM DISK = @backuplocation 
	END
GO



-- Create the stored procedure to create and execute the restore statement

CREATE PROCEDURE dbo.restoredatabase 
		@backuplocation VARCHAR(MAX) 
AS 
BEGIN 
	DECLARE @restorelocation VARCHAR(255), @sql VARCHAR(MAX), @dbname VARCHAR(255) 

	SET @restorelocation = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\' -- Replace with destination data folder location 
	SET @dbname = 'ImportedDB' 

	CREATE TABLE #tblBackupFiles
		(
		LogicalName VARCHAR(255),
		PhysicalName VARCHAR(255),
		[Type] CHAR(1),
		FileGroupName VARCHAR(50),
		Size BIGINT,
		MaxSize BIGINT,
		FileId INT,
		CreateLSN NUMERIC(30,2),
		DropLSN NUMERIC(30,2),
		UniqueId UNIQUEIDENTIFIER,
		ReadOnlyLSN NUMERIC(30,2),
		ReadWriteLSN NUMERIC(30,2),
		BackupSizeInBytes BIGINT,
		SourceBlockSize INT,
		FileGroupId INT,
		LogGroupGUID UNIQUEIDENTIFIER,
		DifferentialBaseLSN NUMERIC(30,2),
		DifferentialBaseGUID UNIQUEIDENTIFIER,
		IsReadOnly INT,
		IsPresent INT,
		TDEThumbprint VARCHAR(10), 
		SnapshotUrl VARCHAR(255)
		)

		-- Execute above created SP to get the RESTORE FILELISTONLY output into a table
		INSERT INTO #tblBackupFiles
		EXEC dbo.restoreheaderonly @backuplocation

		-- Build the T-SQL RESTORE statement
		SET @sql = 'RESTORE DATABASE ' + @dbname + ' FROM DISK = ''' + @backuplocation +  ''' WITH  '

		SELECT @sql = @sql + char(13) + ' MOVE ''' + LogicalName + ''' TO ''' + @restorelocation + LogicalName + '.' + RIGHT(PhysicalName,CHARINDEX('\',PhysicalName)) + ''','
		FROM #tblBackupFiles
		WHERE IsPresent = 1

		SET @sql = SUBSTRING(@sql,1,LEN(@sql)-1)

		-- Get the RESTORE DATABASE command
		PRINT @sql

		-- Execute RESTORE DATABASE command 
		EXEC (@sql)

		-- Cleanup temp objects
		DROP TABLE #tblBackupFiles

END 

-----------------------------------------------------
EXEC dbo.restoreheaderonly 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\AdventureWorks2019.bak'

EXEC dbo.restoredatabase 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\AdventureWorks2019.bak'