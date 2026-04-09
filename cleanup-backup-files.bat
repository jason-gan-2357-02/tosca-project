forfiles /p "C:\Backup\Hourly" /d -2 /c "cmd /c if @isdir==TRUE (echo Deleting folder: @path && rd /s /q @path)"
forfiles /p "C:\Backup\Daily" /d -15 /c "cmd /c if @isdir==TRUE (echo Deleting folder: @path && rd /s /q @path)"
if %errorlevel% equ 1 exit /b 0
