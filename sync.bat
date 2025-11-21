@echo off
setlocal EnableDelayedExpansion

set "FILENAME=cloudflared.exe"
set "URL=https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"

echo [%TIME%] [INFO] Initializing download sequence...
echo [%TIME%] [INFO] Target File: %FILENAME%
echo [%TIME%] [INFO] Target URL: %URL%

where curl >nul 2>nul
if %errorlevel% neq 0 (
    echo [%TIME%] [ERROR] 'curl' is not found on this system.
    exit /b 1
)

echo [%TIME%] [INFO] Starting download process via CURL...
echo [%TIME%] [INFO] Verbose mode ENABLED.

curl -L -v -f -o "%FILENAME%" "%URL%" 2>&1

if %errorlevel% neq 0 (
    echo.
    echo [%TIME%] [CRITICAL] Download command failed with exit code %errorlevel%.
    exit /b %errorlevel%
)

if exist "%FILENAME%" (
    echo.
    echo [%TIME%] [SUCCESS] File downloaded successfully.
    echo [%TIME%] [INFO] Verifying file existence... OK.
    echo [%TIME%] [INFO] Fetching cloudflared version...
    "%FILENAME%" --version 2>&1
) else (
    echo.
    echo [%TIME%] [CRITICAL] Download appeared to finish, but file is missing.
    exit /b 1
)

echo [%TIME%] [DONE] Process finished.
exit /b 0
