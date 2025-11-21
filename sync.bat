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
echo    CLOUDFLARED INSTALLATION MANAGER
echo ============================================================
echo [i] Time: %TIME%
echo [i] Target: %FILENAME%

:: -----------------------------------------------------------------------------
:: CHECK 1: EXISTING INSTALLATION
:: -----------------------------------------------------------------------------
if exist "%FILENAME%" (
    echo [i] File found locally. Checking integrity...
    
    :: Attempt to run version command to verify binary works
    "%FILENAME%" --version >nul 2>&1
    
    if !errorlevel! equ 0 (
        echo [+] Integrity Check: PASSED.
        echo.
        echo ------------------------------------------------------------
        echo [i] CURRENT INSTALLED VERSION:
        "%FILENAME%" --version 2>&1
        echo ------------------------------------------------------------
        echo.
        echo [i] Cloudflared is already installed and valid.
        echo [i] Download sequence skipped.
        goto :FINISH
    ) else (
        echo [!] Integrity Check: FAILED.
        echo [!] Existing file is corrupt or invalid.
        echo [i] Proceeding to redownload...
    )
) else (
    echo [i] No existing installation found.
)

:: -----------------------------------------------------------------------------
:: CHECK 2: SYSTEM REQUIREMENTS
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
echo.
echo ============================================================
echo    STARTING DOWNLOAD SEQUENCE
echo ============================================================
echo [i] Source: %URL%
echo [i] Starting transfer...
echo     (Verbose logs and Progress Bar enabled)
echo ------------------------------------------------------------

:: CURL FLAGS:
:: -L : Follow redirects
:: -# : Hash-based Progress Bar (Visual)
:: -v : Verbose (Headers/Handshake for debugging)
:: -f : Fail silently (for error code handling)
:: -o : Output filename
:: -w : Write-out (Clean summary report)

curl -L -# -v -f -o "%FILENAME%" "%URL%" -w "\n[i] DOWNLOAD REPORT:\n    - Status: %%{http_code}\n    - Size:   %%{size_download} bytes\n    - Speed:  %%{speed_download} bps\n    - Time:   %%{time_total} sec\n" 2>&1

:: -----------------------------------------------------------------------------
:: VALIDATION PHASE
:: -----------------------------------------------------------------------------
echo.
echo ------------------------------------------------------------
if %errorlevel% neq 0 (
    echo [!] DOWNLOAD FAILED.
    echo [!] Exit Code: %errorlevel%
    exit /b %errorlevel%
)

if exist "%FILENAME%" (
    echo [+] File Download Verified.
    echo [+] New Version:
    "%FILENAME%" --version 2>&1
) else (
    echo [!] CRITICAL: File missing despite successful exit code.
    exit /b 1
)

:FINISH
echo.
echo ============================================================
echo    PROCESS COMPLETE
echo ============================================================
exit /b 0
