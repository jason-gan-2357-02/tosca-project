USE [master];
GO

-- Create tosca_common repo database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'tosca_common')
BEGIN
    CREATE DATABASE [tosca_common];
    PRINT 'Database [tosca_common] created.';
END
ELSE
BEGIN
    PRINT 'Database [tosca_common] already exists.';
END
GO

-- Create tosca_services database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'tosca_services')
BEGIN
    CREATE DATABASE [tosca_services];
	ALTER DATABASE [tosca_services] SET READ_COMMITTED_SNAPSHOT ON;
    PRINT 'Database [tosca_services] created.';
END
ELSE
BEGIN
    PRINT 'Database [tosca_services] already exists.';
END
GO

-- Create tools database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'tools')
BEGIN
    CREATE DATABASE [tools];
    PRINT 'Database [tools] created.';
END
ELSE
BEGIN
    PRINT 'Database [tools] already exists.';
END
GO

-- Create server login
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'tosca_user')
BEGIN
    CREATE LOGIN [tosca_user] 
    WITH PASSWORD = 'ToscaUserPassword123$', 
    DEFAULT_DATABASE = [tosca_common],
    CHECK_EXPIRATION = OFF,
    CHECK_POLICY = ON;
    PRINT 'Login [tosca_user] created.';
END
ELSE
BEGIN
    PRINT 'Login [tosca_user] already exists.';
END
GO

-- Grant [tosca_user] full access to [tosca_common]
USE [tosca_common];
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'tosca_user')
BEGIN
    CREATE USER [tosca_user] FOR LOGIN [tosca_user];
    
    -- Add user to the db_owner role for full access
    ALTER ROLE [db_owner] ADD MEMBER [tosca_user];
    
    PRINT 'User [tosca_user] created in [tosca_common] and granted db_owner permissions.';
END
ELSE
BEGIN
    PRINT 'User [tosca_user] already exists in [tosca_common].';
END
GO

-- Grant [tosca_user] full access to [tosca_services]
USE [tosca_services];
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'tosca_user')
BEGIN
    CREATE USER [tosca_user] FOR LOGIN [tosca_user];
    
    -- Add user to the db_owner role for full access
    ALTER ROLE [db_owner] ADD MEMBER [tosca_user];
    
    PRINT 'User [tosca_user] created in [tosca_services] and granted db_owner permissions.';
END
ELSE
BEGIN
    PRINT 'User [tosca_user] already exists in [tosca_services].';
END
GO
