forfiles /p "H:\Backup\Hourly" /d -2 /c "cmd /c if @isdir==TRUE (echo Deleting folder: @path && rd /s /q @path)"
forfiles /p "H:\Backup\Daily" /d -15 /c "cmd /c if @isdir==TRUE (echo Deleting folder: @path && rd /s /q @path)"
if %errorlevel% equ 1 exit /b 0
