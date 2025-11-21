@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: CONFIGURATION
:: ============================================================
set "TARGET_DIR=%ProgramFiles%\Cloudflared"
set "FILENAME=cloudflared.exe"
set "FULL_PATH=%TARGET_DIR%\%FILENAME%"
set "URL=https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"

:: Command arguments (Customized for your request)
set "ARGS=access tcp --hostname mc.sians.pk --url localhost:25565"

:: ============================================================
:: STEP 1: CHECK ADMINISTRATOR PRIVILEGES
:: ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [i] Requesting Administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c, %~dpnx0' -Verb RunAs"
    exit /b
)

:: ============================================================
:: STEP 2: DIRECTORY SETUP
:: ============================================================
echo.
echo ============================================================
echo    CLOUDFLARED SETUP ^& BACKGROUND TASK
echo ============================================================
echo [i] Time: %TIME%
echo [i] Destination: "%TARGET_DIR%"

if not exist "%TARGET_DIR%" (
    echo [i] Creating directory...
    mkdir "%TARGET_DIR%"
    if !errorlevel! neq 0 (
        echo [!] CRITICAL: Failed to create directory.
        exit /b 1
    )
)

:: ============================================================
:: STEP 3: CHECK EXISTING INSTALLATION
:: ============================================================
if exist "%FULL_PATH%" (
    echo [i] File found. Checking integrity...
    "%FULL_PATH%" --version >nul 2>&1
    
    if !errorlevel! equ 0 (
        echo [+] Integrity Check: PASSED.
        goto :EXECUTE_LOGIC
    ) else (
        echo [!] Integrity Check: FAILED. Redownloading...
    )
)

:: ============================================================
:: STEP 4: DOWNLOAD SEQUENCE
:: ============================================================
echo.
echo [i] Downloading Cloudflared...
echo     (Verbose Output Enabled)
echo ------------------------------------------------------------

curl -L -# -v -f -o "%FULL_PATH%" "%URL%" -w "\n[i] DOWNLOAD REPORT:\n    - Status: %%{http_code}\n    - Size:   %%{size_download} bytes\n" 2>&1

if %errorlevel% neq 0 (
    echo [!] CRITICAL: Download failed with code %errorlevel%.
    exit /b %errorlevel%
)

:: ============================================================
:: STEP 5: VERIFICATION
:: ============================================================
echo.
echo ------------------------------------------------------------
echo [i] Verifying binary...
"%FULL_PATH%" --version 2>&1

if %errorlevel% neq 0 (
    echo [!] Download finished but binary is invalid.
    exit /b 1
)

:: ============================================================
:: STEP 6: EXECUTION (BACKGROUND)
:: ============================================================
:EXECUTE_LOGIC
echo.
echo ============================================================
echo    STARTING BACKGROUND SERVICE
echo ============================================================

:: 1. Clean up old processes to prevent duplicates
echo [i] Checking for existing Cloudflared processes...
tasklist /FI "IMAGENAME eq cloudflared.exe" 2>NUL | find /I /N "cloudflared.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [i] Stopping existing instances...
    taskkill /F /IM cloudflared.exe >nul 2>&1
    echo [+] Cleanup complete.
)

:: 2. Launch in Background (Hidden Window)
echo [i] Launching Cloudflared in HIDDEN mode...
echo [i] Command: access tcp --hostname mc.sians.pk --url localhost:25565

:: Use PowerShell Start-Process with -WindowStyle Hidden to detach it
powershell -Command "Start-Process -FilePath '%FULL_PATH%' -ArgumentList '%ARGS%' -WindowStyle Hidden"

:: 3. Verification that it launched
timeout /t 2 /nobreak >nul
tasklist /FI "IMAGENAME eq cloudflared.exe" 2>NUL | find /I /N "cloudflared.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo.
    echo [+] SUCCESS: Cloudflared is running in the background.
    echo [i] It will continue running until you restart the PC.
) else (
    echo.
    echo [!] ERROR: Process failed to start or crashed immediately.
)

:FINISH
echo.
echo ============================================================
echo    PROCESS COMPLETE
echo ============================================================
exit /b 0
