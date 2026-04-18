USE [tools];
GO

CREATE OR ALTER PROCEDURE [backup_databases] 
	@backup_dir VARCHAR(100)
AS
BEGIN
	DECLARE @dbname           VARCHAR(100);
	DECLARE @filepath         VARCHAR(100);
	DECLARE @rightnow         DATETIME = GETDATE();

	SET @backup_dir = @backup_dir + '\' + FORMAT(GETDATE(), 'yyyy-MMdd-HHmmss');

	EXEC master.sys.xp_create_subdir @backup_dir;

	SET @dbname = 'master';
	SET @filepath = @backup_dir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'model';
	SET @filepath = @backup_dir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'msdb';
	SET @filepath = @backup_dir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'tools';
	SET @filepath = @backup_dir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'tosca_common';
	SET @filepath = @backup_dir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'tosca_test_data';
	SET @filepath = @backup_dir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;
END;
GO

PRINT 'Stored procedure [backup_databases] created.';
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

CREATE OR ALTER PROCEDURE [create_daily_backup_job] 
	@job_name VARCHAR(50),
	@backup_dir VARCHAR(100),
	@retention INT,
	@time INT,
	@sunday BIT = 1,
	@monday BIT = 1,
	@tuesday BIT = 1,
	@wednesday BIT = 1,
	@thursday BIT = 1,
	@friday BIT = 1,
	@saturday BIT = 1
AS
BEGIN

	DECLARE @job_id BINARY(16);
	DECLARE @schedule_name VARCHAR(50) = @job_name + ' Schedule';
	DECLARE @step_name VARCHAR(50) = @job_name + ' Step';
	DECLARE @days_of_week INT = 0;

	IF @sunday = 1 BEGIN SET @days_of_week = @days_of_week + 1; END;
	IF @monday = 1 BEGIN SET @days_of_week = @days_of_week + 2; END;
	IF @tuesday = 1 BEGIN SET @days_of_week = @days_of_week + 4; END;
	IF @wednesday = 1 BEGIN SET @days_of_week = @days_of_week + 8; END;
	IF @thursday = 1 BEGIN SET @days_of_week = @days_of_week + 16; END;
	IF @friday = 1 BEGIN SET @days_of_week = @days_of_week + 32; END;
	IF @saturday = 1 BEGIN SET @days_of_week = @days_of_week + 64; END;

	EXEC dbo.delete_schedule_if_exists @schedule_name = @schedule_name;
	EXEC dbo.delete_job_if_exists @job_name = @job_name;

	-- 1. Create the Job
	EXEC msdb.dbo.sp_add_job 
		@job_name = @job_name, 
		@enabled = 1, 
		@description = @job_name,
		@job_id = @job_id OUTPUT;

	DECLARE @backup_command VARCHAR(MAX) =
		CONCAT('EXEC dbo.backup_databases @backup_dir = "', @backup_dir, '"');

	-- 2.a. Add backup step
	EXEC msdb.dbo.sp_add_jobstep 
		@job_id = @job_id, 
		@step_name = 'Backup Step', 
		@subsystem = 'TSQL', 
		@command = @backup_command, 
		@database_name = 'tools',
		@retry_attempts = 2,
		@retry_interval = 5,
		@on_success_action = 3; -- on success, go to next step

	DECLARE @cleanup_command VARCHAR(MAX) = CONCAT(
		'$BackupDir = "', @backup_dir, '"', CHAR(13), CHAR(10),
		'$Retention = ', @retention, CHAR(13), CHAR(10),
		'Get-ChildItem $BackupDir -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).Date.AddDays(-$Retention) } | Remove-Item -Recurse -Force', CHAR(13), CHAR(10)
	);

	-- 2.b. Add cleanup step
	EXEC msdb.dbo.sp_add_jobstep 
		@job_id = @job_id, 
		@step_name = 'Cleanup Step', 
		@subsystem = 'PowerShell', 
		@command = @cleanup_command, 
		@database_name = 'tools',
		@retry_attempts = 2,
		@retry_interval = 5;		

	-- 3. Create the Schedule
	EXEC msdb.dbo.sp_add_schedule 
		@schedule_name = @schedule_name, 
		@freq_type = 8,
		@freq_recurrence_factor = 1,
		@freq_interval = @days_of_week, 
		@active_start_time = @time;

	-- 4. Attach the Schedule to the Job
	EXEC msdb.dbo.sp_attach_schedule 
		@job_id = @job_id, 
		@schedule_name = @schedule_name;

	-- 5. Target the Job to the local server
	EXEC msdb.dbo.sp_add_jobserver 
		@job_id = @job_id, 
		@server_name = '(local)';

	PRINT 'Job [' + @job_name + '] created.';

END;
GO

PRINT 'Stored procedure [create_daily_backup_job] created.';
GO
