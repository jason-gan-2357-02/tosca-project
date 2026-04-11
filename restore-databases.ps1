$BackupDir = "F:\Backup\Hourly\2026-0411-232459"

function Restore-Database {
    param(
        [string]$DatabaseName
    )
    Write-Host "Restoring database $DatabaseName..."
    $FilePath = "$BackupDir\$DatabaseName.bak"
    if ($DatabaseName -eq "master") {
        sqlcmd -C -Q "RESTORE DATABASE $DatabaseName FROM DISK = '$FilePath' WITH RECOVERY, REPLACE"
    } else {
        sqlcmd -C -Q "ALTER DATABASE $DatabaseName SET SINGLE_USER WITH ROLLBACK IMMEDIATE; RESTORE DATABASE $DatabaseName FROM DISK = '$FilePath' WITH RECOVERY, REPLACE; ALTER DATABASE $DatabaseName SET MULTI_USER"
    }
}

function Stop-SQLServer-Instances {
    $SQLServices = Get-Service -Name $Pattern | Where-Object { 
        $_.Name -like "MSSQL$*" -or $_.Name -eq "MSSQLSERVER" 
    }
    foreach ($Service in $SQLServices) {
        Write-Host "Stopping $($Service.Name)..."
        Stop-Service -InputObject $Service -Force
        $Service.WaitForStatus('Stopped', '00:00:30')
    }
}

function Start-SQLServer-Instances {
    param(
        [switch]$SingleUser
    )
    $SQLServices = Get-Service -Name $Pattern | Where-Object { 
        $_.Name -like "MSSQL$*" -or $_.Name -eq "MSSQLSERVER" 
    }
    foreach ($Service in $SQLServices) {
        Write-Host "Starting $($Service.Name)..."
        if ($SingleUser) {
            net start $Service /m
        }
        else {
            Start-Service -InputObject $Service
        }
        $Service.WaitForStatus('Running', '00:00:30')
    }
    Start-Sleep -Seconds 5
}

function Stop-SQLServer-Agents {
    $Services = Get-Service -Name $Pattern | Where-Object { 
        $_.Name -like "SQLAgent$*" -or $_.Name -eq "SQLSERVERAGENT" 
    }
    foreach ($Service in $Services) {
        Write-Host "Stopping $($Service.Name)..."
        Stop-Service -InputObject $Service -Force
        $Service.WaitForStatus('Stopped', '00:00:30')
    }
}

function Start-SQLServer-Agents {
    $Services = Get-Service -Name $Pattern | Where-Object { 
        $_.Name -like "SQLAgent$*" -or $_.Name -eq "SQLSERVERAGENT" 
    }
    foreach ($Service in $Services) {
        Write-Host "Starting $($Service.Name)..."
        Start-Service -InputObject $Service
        $Service.WaitForStatus('Running', '00:00:30')
    }
}

Stop-SQLServer-Agents
Stop-SQLServer-Instances 
Start-SQLServer-Instances -SingleUser
Restore-Database -DatabaseName "master"
Stop-SQLServer-Instances
Start-SQLServer-Instances
Restore-Database -DatabaseName "model"
Restore-Database -DatabaseName "msdb"
Restore-Database -DatabaseName "tools"
Restore-Database -DatabaseName "tosca_common"
Restore-Database -DatabaseName "tosca_test_data"
Start-SQLServer-Agents
