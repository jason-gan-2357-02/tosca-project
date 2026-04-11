USE [tools];
GO

CREATE OR ALTER PROCEDURE [backup_all_databases] AS
BEGIN
	DECLARE @dailyBackupDir   VARCHAR(100) = 'F:\Backup\Daily';
	DECLARE @hourlyBackupDir  VARCHAR(100) = 'F:\Backup\Hourly';
	DECLARE @backupdir        VARCHAR(100);
	DECLARE @dbname           VARCHAR(100);
	DECLARE @filepath         VARCHAR(100);
	DECLARE @rightnow         DATETIME = GETDATE();

	IF DATEPART(HOUR, @rightnow) = 0 
	BEGIN
		SET @backupdir = @dailyBackupDir + '\' + FORMAT(@rightnow, 'yyyy-MMdd-HHmmss');
	END 
	ELSE
	BEGIN
		SET @backupdir = @hourlyBackupDir + '\' + FORMAT(@rightnow, 'yyyy-MMdd-HHmmss');
	END

	EXEC master.sys.xp_create_subdir @backupdir;

	SET @dbname = 'master';
	SET @filepath = @backupdir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'model';
	SET @filepath = @backupdir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'msdb';
	SET @filepath = @backupdir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'tools';
	SET @filepath = @backupdir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'tosca_common';
	SET @filepath = @backupdir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'tosca_test_data';
	SET @filepath = @backupdir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;
END;
GO

PRINT 'Stored procedure [backup_all_databases] created.';
GO

CREATE OR ALTER PROCEDURE [delete_schedule_if_exists] 
	@schedule_name NVARCHAR(50)
AS
BEGIN
	IF NOT EXISTS (SELECT schedule_id FROM msdb.dbo.sysschedules WHERE name = @schedule_name)
	BEGIN
		RETURN;
	END	

	PRINT 'Schedule [' + @schedule_name + '] already exists. Deleting...';

	DECLARE @schedId INT;

	DECLARE schedCursor CURSOR FOR 
    	SELECT schedule_id 
    	FROM msdb.dbo.sysschedules 
    	WHERE name = @schedule_name;

	OPEN schedCursor;
	FETCH NEXT FROM schedCursor INTO @schedId;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC msdb.dbo.sp_delete_schedule @schedule_id = @schedId, @force_delete = 1; 
		FETCH NEXT FROM schedCursor INTO @schedId;
	END

	CLOSE schedCursor;
	DEALLOCATE schedCursor;
END;
GO

PRINT 'Stored procedure [delete_schedule_if_exists] created.';
GO

CREATE OR ALTER PROCEDURE [delete_job_if_exists] 
	@job_name NVARCHAR(50)
AS
BEGIN
	IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = @job_name)
	BEGIN
    	PRINT 'Job [' + @job_name + '] already exists. Deleting...';
    	EXEC msdb.dbo.sp_delete_job @job_name = @job_name, @delete_unused_schedule = 1;
	END
END;
GO

PRINT 'Stored procedure [delete_job_if_exists] created.';
GO

CREATE OR ALTER PROCEDURE [create_job] 
	@job_name NVARCHAR(50),
	@description NVARCHAR(255),
	@subsystem NVARCHAR(50),
	@command NVARCHAR(MAX),
	@freq_type INT, -- daily
	@freq_interval INT, 
	@freq_subday_type INT,
	@freq_subday_interval INT,
	@active_start_time INT
AS
BEGIN

	DECLARE @job_id BINARY(16);
	DECLARE @schedule_name NVARCHAR(50) = @job_name + ' Schedule';
	DECLARE @stepName NVARCHAR(50) = @job_name + ' Step';

	EXEC dbo.delete_schedule_if_exists @schedule_name = @schedule_name;
	EXEC dbo.delete_job_if_exists @job_name = @job_name;

	-- 1. Create the Job
	EXEC msdb.dbo.sp_add_job 
		@job_name = @job_name, 
		@enabled = 1, 
		@description = @description,
		@job_id = @job_id OUTPUT;

	-- 2. Add the Step
	EXEC msdb.dbo.sp_add_jobstep 
		@job_id = @job_id, 
		@step_name = @stepName, 
		@subsystem = @subsystem, 
		@command = @command, 
		@database_name = N'tools',
		@retry_attempts = 0,
		@retry_interval = 5;

	-- 3. Create the Schedule
	EXEC msdb.dbo.sp_add_schedule 
		@schedule_name = @schedule_name, 
		@freq_type = @freq_type,
		@freq_interval = @freq_interval, 
		@freq_subday_type = @freq_subday_type,
		@freq_subday_interval = @freq_subday_interval,
		@active_start_time = @active_start_time;

	-- 4. Attach the Schedule to the Job
	EXEC msdb.dbo.sp_attach_schedule 
		@job_id = @job_id, 
		@schedule_name = @schedule_name;

	-- 5. Target the Job to the local server
	EXEC msdb.dbo.sp_add_jobserver 
		@job_id = @job_id, 
		@server_name = N'(local)';

	PRINT 'Job [' + @job_name + '] created.';

END;
GO

PRINT 'Stored procedure [create_job] created.';
GO


EXEC dbo.create_job 
	@job_name = N'Backup Databases',
	@description = N'Backup databases every 4 hours',
	@subsystem = N'TSQL', 
	@command = N'EXEC dbo.backup_all_databases;', 
	@freq_type = 4, -- daily
	@freq_interval = 1, 
	@freq_subday_type = 8, -- hours
	@freq_subday_interval = 4, -- every 4 hours
	@active_start_time = 000000; -- Start at midnight (HHMMSS)

EXEC dbo.create_job 
	@job_name = N'Cleanup Old Backups',
	@description = N'Cleanup old backups everyday at 2 AM',
	@subsystem = N'PowerShell', 
	@command = N'
		$DailyBackupDir = "F:\Backup\Daily"
		$HourlyBackupDir = "F:\Backup\Hourly"
		$DailyBackupRetention = 2 # number of days
		$HourlyBackupRetention = 2 # number of days
		Get-ChildItem $DailyBackupDir -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DailyBackupRetention) } | Remove-Item -Recurse -Force
		Get-ChildItem $HourlyBackupDir -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$HourlyBackupRetention) } | Remove-Item -Recurse -Force
	',
	@freq_type = 4, -- daily
	@freq_interval = 1, 
	@freq_subday_type = 1, -- At the specified time
	@freq_subday_interval = 0,
	@active_start_time = 020000; -- 2 AM