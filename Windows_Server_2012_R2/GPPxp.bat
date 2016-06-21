SET DC_NAME=alarasvr

rem Check to see this is Windows XP
ver | find "Windows XP" >NUL
if errorlevel 1 goto end

rem Check to see if the update is already installed
reg QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Updates\Windows XP\SP20\KB943729" >NUL 2>NUL
if errorlevel 1 goto install_update
goto end

:install_update
\\%DC_NAME%\netlogon\GPPxp\Windows-KB943729-x86-ENU.exe /quiet /norestart

:end