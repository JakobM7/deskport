@echo off
call "%~dp0Start-DeskPort.cmd" --build
exit /b %errorlevel%
