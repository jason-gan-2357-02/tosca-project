USE [tools];
GO

EXEC dbo.create_daily_backup_job 
	@job_name = 'Backup Day',
	@backup_dir = 'G:\Backup\Day',
	@time = 123000, -- 12:30 PM,
	@retention = 2, -- 2 days
	@sunday = 0; -- exclude Sunday

EXEC dbo.create_daily_backup_job 
	@job_name = 'Backup Night',
	@backup_dir = 'G:\Backup\Night',
	@time = 193000, -- 7:30 PM
	@retention = 15, -- 15 days
	@sunday = 0; -- exclude Sunday
