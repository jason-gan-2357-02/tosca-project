$storageDir = "F:\Tosca_Storage"
$mirrorDir = "F:\FileServiceMirror"
$backupDir = "F:\FileServiceBackup"

$timestamp = Get-Date -Format "yyyy-MMdd-HHmmss"
robocopy $storageDir $mirrorDir /MIR /R:3 /W:5
Compress-Archive -Path "$mirrorDir\*" -DestinationPath "$backupDir\$timestamp.zip"