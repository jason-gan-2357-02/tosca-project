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

-- Create tosca_test_data database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'tosca_test_data')
BEGIN
    CREATE DATABASE [tosca_test_data];
    PRINT 'Database [tosca_test_data] created.';
END
ELSE
BEGIN
    PRINT 'Database [tosca_test_data] already exists.';
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
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'tosca_app')
BEGIN
    CREATE LOGIN [tosca_app] 
    WITH PASSWORD = 'ToscaUserPassword123$', 
    DEFAULT_DATABASE = [tosca_common],
    CHECK_EXPIRATION = OFF,
    CHECK_POLICY = ON;
    PRINT 'Login [tosca_app] created.';
END
ELSE
BEGIN
    PRINT 'Login [tosca_app] already exists.';
END
GO

-- Grant [tosca_app] full access to [tosca_common]
USE [tosca_common];
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'tosca_app')
BEGIN
    CREATE USER [tosca_app] FOR LOGIN [tosca_app];
    
    -- Add user to the db_owner role for full access
    ALTER ROLE [db_owner] ADD MEMBER [tosca_app];
    
    PRINT 'User [tosca_app] created in [tosca_common] and granted db_owner permissions.';
END
ELSE
BEGIN
    PRINT 'User [tosca_app] already exists in [tosca_common].';
END
GO

-- Grant [tosca_app] full access to [tosca_test_data]
USE [tosca_test_data];
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'tosca_app')
BEGIN
    CREATE USER [tosca_app] FOR LOGIN [tosca_app];
    
    -- Add user to the db_owner role for full access
    ALTER ROLE [db_owner] ADD MEMBER [tosca_app];
    
    PRINT 'User [tosca_app] created in [tosca_test_data] and granted db_owner permissions.';
END
ELSE
BEGIN
    PRINT 'User [tosca_app] already exists in [tosca_test_data].';
END
GO
