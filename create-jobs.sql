USE [tools];
GO

DECLARE @dayBackupDir         VARCHAR(100) = 'H:\Backup\Day';
DECLARE @dayBackupTime        INT          = 123000; -- 12:30 PM
DECLARE @dayBackupRetention   INT          = 2;      --  2 days

DECLARE @nightBackupDir       VARCHAR(100) = 'H:\Backup\Night';
DECLARE @nightBackupTime      INT          = 193000; --  7:30 PM
DECLARE @nightBackupRetention INT          = 15;     -- 15 days

DECLARE @cleanupTime          INT          = 223000; -- 10:30 PM

DECLARE @dayBackupCommand VARCHAR(MAX) =
	CONCAT('EXEC dbo.backup_databases @backup_dir = "', @dayBackupDir, '"');

EXEC dbo.create_daily_job 
	@job_name = 'Backup Day',
	@subsystem = 'TSQL', 
	@command = @dayBackupCommand,
	@time = @dayBackupTime,
	@sunday = 0; -- exclude Sunday

DECLARE @nightBackupCommand VARCHAR(MAX) = 
	CONCAT('EXEC dbo.backup_databases @backup_dir = "', @nightBackupDir, '"');

EXEC dbo.create_daily_job 
	@job_name = 'Backup Night',
	@subsystem = 'TSQL', 
	@command = @nightBackupCommand,
	@time = @nightBackupTime,
	@sunday = 0; -- exclude Sunday

DECLARE @cleanupCommand VARCHAR(MAX) = CONCAT(
	'$DayBackupDir = "', @dayBackupDir, '"', CHAR(13), CHAR(10),
	'$DayBackupRetention = ', @dayBackupRetention, CHAR(13), CHAR(10),
	'$NightBackupDir = "', @nightBackupDir, '"', CHAR(13), CHAR(10),
	'$NightBackupRetention = ', @nightBackupRetention, CHAR(13), CHAR(10),
	'Get-ChildItem $DayBackupDir -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).Date.AddDays(-$DayBackupRetention) } | Remove-Item -Recurse -Force', CHAR(13), CHAR(10),
	'Get-ChildItem $NightBackupDir -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).Date.AddDays(-$NightBackupRetention) } | Remove-Item -Recurse -Force', CHAR(13), CHAR(10)
);

EXEC dbo.create_daily_job 
	@job_name = 'Cleanup Old Backups',
	@subsystem = 'PowerShell', 
	@command = @cleanupCommand,
	@time = @cleanupTime,
	@sunday = 0; -- exclude Sunday
