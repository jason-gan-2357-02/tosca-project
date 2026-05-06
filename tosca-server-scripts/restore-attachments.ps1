[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Please provide backup file yyyy-mm-dd-hhmmss_FILE.zip.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if (Test-Path $_ -PathType Leaf) {
            $true
        } else {
            throw "The backup file '$_' does not exist or is not a file."
        }
    })]
    [string]$BackupFile,
	
    [Parameter(Mandatory = $true, HelpMessage = "Please provide backup file yyyy-mm-dd-hhmmss _FS.zip.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if (Test-Path $_ -PathType Leaf) {
            $true
        } else {
            throw "The backup file '$_' does not exist or is not a file."
        }
    })]
    [string]$BackupFileFS
)

$TargetDirectory = "G:\Tosca_Storage"
$StagingDirectory = "G:\Restore_Staging\File"
$TargetFSDirectory = "G:\ProgramData\TRICENTIS\ToscaServer\FileService"
$StagingFSDirectory = "G:\Restore_Staging\FS"  

if (Test-Path $TargetDirectory -PathType Container) {
    $true
} else {
    throw "The target directory '$TargetDirectory' does not exist or is not a directory."
}

New-Item -Path $StagingDirectory -ItemType Directory -Force
Remove-Item -Path $StagingDirectory\* -Recurse -Force
Expand-Archive -Path $BackupFile -DestinationPath $StagingDirectory -Force
robocopy $StagingDirectory $TargetDirectory /MIR /R:3 /W:5
Remove-Item -Path $StagingDirectory\* -Recurse -Force

if (Test-Path $TargetFSDirectory -PathType Container) {
    $true
} else {
    throw "The target directory '$TargetFSDirectory' does not exist or is not a directory."
}

New-Item -Path $StagingFSDirectory -ItemType Directory -Force
Remove-Item -Path $StagingFSDirectory\* -Recurse -Force
Expand-Archive -Path $BackupFileFS -DestinationPath $StagingFSDirectory -Force
robocopy $StagingFSDirectory $TargetFSDirectory /MIR /R:3 /W:5
Remove-Item -Path $StagingFSDirectory\* -Recurse -Force