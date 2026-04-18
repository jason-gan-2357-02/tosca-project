function Main {
    Add-Backup-Job `
        -TaskName "Backup Day" `
        -SourceDirectory "F:\Tosca_Storage" `
        -MirrorDirectory "F:\Tosca_Storage_Mirror" `
        -BackupDirectory "F:\Backup\Day" `
        -DaysOfWeek "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" `
        -Time "12:30PM" `
        -Retention 2

    Add-Backup-Job `
        -TaskName "Backup Night" `
        -SourceDirectory "F:\Tosca_Storag" `
        -MirrorDirectory "F:\Tosca_Storage_Mirror" `
        -BackupDirectory "F:\Backup\Night" `
        -DaysOfWeek "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" `
        -Time "7:30PM" `
        -Retention 15
}

function Add-Backup-Job {
    param(
        [string]$TaskName,
        [string]$SourceDirectory,
        [string]$MirrorDirectory,
        [string]$BackupDirectory,
        [string[]]$DaysOfWeek,
        [string]$Time,
        [int]$Retention
    )

    $Command = @"

        `$timestamp = Get-Date -Format "yyyy-MMdd-HHmmss"
        robocopy "$SourceDirectory" "$MirrorDirectory" /MIR /R:3 /W:5
        Compress-Archive -Path "$MirrorDirectory\*" -DestinationPath "$BackupDirectory\`$timestamp.zip"    
		Get-ChildItem "$BackupDirectory" -File | Where-Object { `$_.LastWriteTime -lt (Get-Date).Date.AddDays(-$Retention) } | Remove-Item -Force
"@

    $Action = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command $Command"

    $Trigger = New-ScheduledTaskTrigger -Weekly `
        -DaysOfWeek $DaysOfWeek `
        -At $Time

    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest

    Register-ScheduledTask -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $Settings `
        -Description $TaskName `
        -Principal $Principal `
        -Force

    Write-Host "Task '$TaskName' has been created successfully." -ForegroundColor Green
}

Main
