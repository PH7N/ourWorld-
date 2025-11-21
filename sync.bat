@echo off
setlocal EnableDelayedExpansion

:: Configuration
set "FILENAME=cloudflared.exe"
set "URL=https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"

:: -----------------------------------------------------------------------------
:: SETUP: CONSOLE UI
:: -----------------------------------------------------------------------------
echo.
echo ============================================================
echo    CLOUDFLARED INSTALLER SEQUENCE
echo ============================================================
echo [i] Time: %TIME%
echo [i] Dest: %~dp0%FILENAME%
echo [i] Source: %URL%
echo.

:: -----------------------------------------------------------------------------
:: PRE-CHECK
:: -----------------------------------------------------------------------------
where curl >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] CRITICAL ERROR: 'curl' not found.
    echo     This script requires Windows 10 ^(1803+^) or Windows 11.
    exit /b 1
)

:: -----------------------------------------------------------------------------
:: DOWNLOAD PHASE
:: -----------------------------------------------------------------------------
echo [i] Starting Download...
echo     (Verbose logs and Progress Bar enabled)
echo ------------------------------------------------------------

:: CURL FLAGS EXPLAINED:
:: -L  : Follow redirects (GitHub -> S3)
:: -#  : Display simple "Hash" Progress Bar (Intuitive UI)
:: -v  : Verbose (Prints Handshake/Headers for your App Logs)
:: -f  : Fail silently on HTTP errors (allows capturing exit code)
:: -o  : Output file
:: -w  : Write-out (Prints a clean Summary Report at the end)

curl -L -# -v -f -o "%FILENAME%" "%URL%" -w "\n[i] DOWNLOAD REPORT:\n    - Status: %%{http_code}\n    - Size:   %%{size_download} bytes\n    - Speed:  %%{speed_download} bps\n    - Time:   %%{time_total} sec\n" 2>&1

:: -----------------------------------------------------------------------------
:: VALIDATION PHASE
:: -----------------------------------------------------------------------------
echo.
echo ------------------------------------------------------------
if %errorlevel% neq 0 (
    echo [!] DOWNLOAD FAILED.
    echo [!] Exit Code: %errorlevel%
    echo [!] Check the verbose logs above for connection details.
    exit /b %errorlevel%
)

if exist "%FILENAME%" (
    echo [+] File Download Verified.
    echo [+] Integrity Check (Version):
    "%FILENAME%" --version 2>&1
    echo.
    echo ============================================================
    echo    INSTALLATION COMPLETE
    echo ============================================================
) else (
    echo [!] CRITICAL: File missing despite successful exit code.
    exit /b 1
)

exit /b 0
