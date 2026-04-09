-- Create backup_all_databases stored procedure in [tools]
USE [tools];
GO

CREATE OR ALTER PROCEDURE [backup_all_databases]
AS
BEGIN

	DECLARE @backuproot VARCHAR(40);
	DECLARE @backupdir  VARCHAR(40);
	DECLARE @dbname     VARCHAR(40);
	DECLARE @filepath   VARCHAR(100);
	DECLARE @rightnow   DATETIME = GETDATE();

	SET @backuproot = 'C:\Backup';

	IF DATEPART(HOUR, @rightnow) = 0
	BEGIN
		SET @backupdir = @backuproot + '\Daily\' + FORMAT(@rightnow, 'yyyy-MMdd-HHmmss');
	END
	ELSE
	BEGIN
		SET @backupdir = @backuproot + '\Hourly\' + FORMAT(@rightnow, 'yyyy-MMdd-HHmmss');
	END

	EXEC master.sys.xp_create_subdir @backupdir;

	SET @dbname = 'master';
	SET @filepath = @backupdir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'msdb';
	SET @filepath = @backupdir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'model';
	SET @filepath = @backupdir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'tools';
	SET @filepath = @backupdir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'tosca_common';
	SET @filepath = @backupdir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

	SET @dbname = 'tosca_services';
	SET @filepath = @backupdir + '\' + @dbname + '.bak';
	BACKUP DATABASE @dbname TO DISK = @filepath WITH INIT, COMPRESSION, STATS = 10;

END;
GO

PRINT 'Stored procedure [backup_all_databases] created.';

-- Create job for automated backup of all databases
USE [msdb];
GO

DECLARE @jobId BINARY(16);
DECLARE @jobName NVARCHAR(50);
DECLARE @schedId INT;
DECLARE @schedName NVARCHAR(50);

SET @jobName = N'Automated_Backups';
SET @schedName = N'Schedule_Every_4_Hours';

-- Check if schedule already exists and delete it
IF EXISTS (SELECT schedule_id FROM dbo.sysschedules WHERE name = @schedName)
BEGIN
    PRINT 'Schedule [' + @schedName + '] already exists. Deleting...';
END	

DECLARE sched_cursor CURSOR FOR 
    SELECT schedule_id 
    FROM dbo.sysschedules 
    WHERE name = @schedName;

OPEN sched_cursor;
FETCH NEXT FROM sched_cursor INTO @schedId;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC dbo.sp_delete_schedule 
        @schedule_id = @schedId, 
        @force_delete = 1; 
    FETCH NEXT FROM sched_cursor INTO @schedId;
END

CLOSE sched_cursor;
DEALLOCATE sched_cursor;

-- Check if the job already exists and delete it
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = @jobName)
BEGIN
    PRINT 'Job [' + @jobName + '] already exists. Deleting...';
    EXEC sp_delete_job @job_name = @jobName, @delete_unused_schedule = 1;
END

-- 1. Create the Job
EXEC sp_add_job 
    @job_name = @jobName, 
    @enabled = 1, 
    @description = N'Executes the backup_databases procedure every 4 hours.',
    @job_id = @jobId OUTPUT;

-- 2. Add the Step
EXEC sp_add_jobstep 
    @job_id = @jobId, 
    @step_name = N'Run Backup Stored Procedure', 
    @subsystem = N'TSQL', 
    @command = N'EXEC dbo.backup_all_databases;', 
    @database_name = N'tools',
    @retry_attempts = 1,
    @retry_interval = 5;

-- 3. Create the Schedule (Every day, every 4 hours)
-- freq_type 4 = Daily
-- freq_subday_type 8 = Hours
-- freq_subday_interval 4 = Every 4 hours
EXEC sp_add_schedule 
    @schedule_name = @schedName, 
    @freq_type = 4, 
    @freq_interval = 1, 
    @freq_subday_type = 8, 
    @freq_subday_interval = 4, 
    @active_start_time = 000000; -- Start at midnight (HHMMSS)

-- 4. Attach the Schedule to the Job
EXEC sp_attach_schedule 
    @job_id = @jobId, 
    @schedule_name = @schedName;

-- 5. Target the Job to the local server
EXEC sp_add_jobserver 
    @job_id = @jobId, 
    @server_name = N'(local)';

PRINT 'Job [' + @jobName + '] with schedule [' + @schedName + '] created.';
