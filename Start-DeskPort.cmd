@echo off
setlocal DisableDelayedExpansion
set "checkout_open="
pushd "%~dp0" || goto error
set "checkout_open=1"
set "DESKPORT_WINDOWS_LAUNCH_ROOT=%LOCALAPPDATA%\DeskPortSource"
set "image="
if /I "%~1"=="--build" goto build
call :read_image
if defined image if exist "%image%" goto launch

:build
where wsl.exe >nul 2>nul
if errorlevel 1 (
    echo Building DeskPort for Windows requires an x64 WSL distribution with Nix.
    goto error
)
if defined WSLENV (
    set "WSLENV=%WSLENV%:DESKPORT_WINDOWS_LAUNCH_ROOT/p"
) else (
    set "WSLENV=DESKPORT_WINDOWS_LAUNCH_ROOT/p"
)
wsl.exe --exec bash -l ./scripts/build-source-windows.sh
if errorlevel 1 goto error
call :read_image
if not defined image goto error
if not exist "%image%" goto error

:launch
for %%I in ("%image%") do start "" /D "%%~dpI." "%%~fI"
if errorlevel 1 goto error
popd
exit /b 0

:read_image
set "image="
set "relative_image="
if not exist "build\windows-source.path" exit /b 0
set /p "relative_image=" < "build\windows-source.path"
if defined relative_image set "image=%DESKPORT_WINDOWS_LAUNCH_ROOT%\%relative_image%"
exit /b 0

:error
if defined checkout_open popd
echo DeskPort could not be started. See the messages above and docs\SOURCE_LAUNCH.md.
pause
exit /b 1
