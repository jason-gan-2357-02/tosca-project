[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Please provide backup file.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if (Test-Path $_ -PathType Leaf) {
            $true
        } else {
            throw "The backup file '$_' does not exist or is not a file."
        }
    })]
    [string]$BackupFile
)

$TargetDirectory = "F:\Tosca_Storage"
$StagingDirectory = "F:\Tosca_Storage_Staging"

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
