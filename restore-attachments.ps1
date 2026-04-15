[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Please provide backup file.")]
    [ValidateNotNullOrEmpty()]
    # This block ensures the path actually exists and is a file
    [ValidateScript({
        if (Test-Path $_ -PathType Leaf) {
            $true
        } else {
            throw "The path '$_' does not exist or is not a file."
        }
    })]
    [string]$BackupFile
)

$storageDir = "F:\Tosca_Storage"
$tempDir = "F:\AttachmentsTemp"

if (Test-Path -Path $tempDir) {
    Write-Host "Directory $($tempDir) exists. Deleting it..."
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force
Expand-Archive -Path $backupFile -DestinationPath $tempDir -Force
robocopy $tempDir $storageDir /MIR /R:3 /W:5
Remove-Item -Path $tempDir -Recurse -Force

