Instructions on setting up SQL Server for Tosca in BSP:

1. Login to th SQL Server VM using a Windows user with sysadmin server role on SQL Server.

2. In Command Prompt run the create-databases.sql script:
  sqlcmd -C -i create-databases.sql

3. Change the password of tosca_app:
  sqlcmd -Command -Q "ALTER LOGIN [tosca_app] WITH PASSWORD = 'TheNewPassword';"

4. In Command Prompt run the create-procedures.sql script:
  sqlcmd -C -i create-procedures.sql

5. Check the schedule-database-backup.sql script to make sure the values are correct (especially the @backup_dir). Then in Command Prompt run the schedule-database-backup.sql script:
  sqlcmd -C -i schedule-database-backup.sql
