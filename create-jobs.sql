USE [tools];
GO

DECLARE @hourlyBackupDir  VARCHAR(100) = 'H:\Backup\Hourly';
DECLARE @dailyBackupDir   VARCHAR(100) = 'H:\Backup\Daily';
DECLARE @firstBackupTime  INT          = 123000; -- 12:30 PM
DECLARE @backupInterval   INT          = 7;      -- every 7 hours
DECLARE @lastBackupHour   INT          = 19;     -- 7 PM

DECLARE @command VARCHAR(MAX) = CONCAT('EXEC dbo.backup_all_databases ',
	'@hourlyBackupDir = "', @hourlyBackupDir, '", ',
	'@dailyBackupDir = "', @dailyBackupDir, '", ',
	'@lastBackupHour = ', @lastBackupHour);

EXEC dbo.create_job 
	@job_name = N'Backup Databases',
	@description = N'Backup databases',
	@subsystem = N'TSQL', 
	@command = @command,
	@freq_type = 4, -- daily
	@freq_interval = 1, 
	@freq_subday_type = 8, -- hours
	@freq_subday_interval = @backupInterval,
	@active_start_time = @firstBackupTime;

EXEC dbo.create_job 
	@job_name = N'Cleanup Old Backups',
	@description = N'Cleanup old backups everyday at 2 AM',
	@subsystem = N'PowerShell', 
	@command = N'
		$DailyBackupDir = "H:\Backup\Daily"
		$HourlyBackupDir = "H:\Backup\Hourly"
		$DailyBackupRetention = 15 # number of days
		$HourlyBackupRetention = 2 # number of days
		Get-ChildItem $DailyBackupDir -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).Date.AddDays(-$DailyBackupRetention) } | Remove-Item -Recurse -Force
		Get-ChildItem $HourlyBackupDir -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).Date.AddDays(-$HourlyBackupRetention) } | Remove-Item -Recurse -Force
	',
	@freq_type = 4, -- daily
	@freq_interval = 1, 
	@freq_subday_type = 1, -- At the specified time
	@freq_subday_interval = 0,
	@active_start_time = 020000; -- 2 AM