-- Create the stored procedure to create and execute the restore statement

CREATE PROCEDURE dbo.restoredatabase 
		@backuplocation VARCHAR(MAX), @dbname VARCHAR(255)
AS 
BEGIN 
	DECLARE @restorelocation VARCHAR(255), @sql VARCHAR(MAX)

	SET @restorelocation = '/var/opt/mssql/data' -- Replace with destination data folder location 

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
		SET @sql = 'RESTORE DATABASE [' + @dbname + '] FROM DISK = ''' + @backuplocation +  ''' WITH  '

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