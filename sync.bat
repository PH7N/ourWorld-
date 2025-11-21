@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: CONFIGURATION
:: ============================================================
set "FILENAME=cloudflared.exe"
set "URL=https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"

:: Get the full path of the directory where this script is running
set "INSTALL_DIR=%~dp0"
:: Remove trailing backslash for cleaner PATH manipulation
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

echo.
echo ============================================================
echo    CLOUDFLARED INSTALLER + PATH CONFIG
echo ============================================================
echo [i] Install Location: %INSTALL_DIR%

:: ============================================================
:: STEP 1: CHECK & DOWNLOAD
:: ============================================================
if exist "%INSTALL_DIR%\%FILENAME%" (
    echo [i] Found existing binary. Checking integrity...
    "%INSTALL_DIR%\%FILENAME%" --version >nul 2>&1
    if !errorlevel! equ 0 (
        echo [+] Integrity Check: PASSED.
        goto :CHECK_PATH
    ) else (
        echo [!] Integrity Check: FAILED. Redownloading...
    )
)

echo [i] Downloading Cloudflared...
echo     (Verbose Output Enabled)
echo ------------------------------------------------------------

:: Download with curl (Visual + Verbose)
curl -L -# -v -f -o "%INSTALL_DIR%\%FILENAME%" "%URL%" -w "\n[i] DOWNLOAD REPORT:\n    - Status: %%{http_code}\n    - Size:   %%{size_download} bytes\n" 2>&1

if %errorlevel% neq 0 (
    echo [!] CRITICAL: Download failed.
    exit /b %errorlevel%
)

:: ============================================================
:: STEP 2: ADD TO WINDOWS PATH (The "Install" Part)
:: ============================================================
:CHECK_PATH
echo.
echo ============================================================
echo    PATH ENVIRONMENT SETUP
echo ============================================================
echo [i] Checking if install directory is in User PATH...

:: We use PowerShell to check and set the path because it is safer than setx
:: This avoids the 1024 character limit truncation bug common in Batch files.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$target = '%INSTALL_DIR%'; " ^
    "$currentPath = [Environment]::GetEnvironmentVariable('Path', 'User'); " ^
    "if ($currentPath -split ';' -contains $target) { " ^
    "    Write-Host '[+] Path already configured.'; " ^
    "    exit 0; " ^
    "} else { " ^
    "    Write-Host '[i] Adding directory to User Path...'; " ^
    "    $newPath = $currentPath + ';' + $target; " ^
    "    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User'); " ^
    "    exit 1; " ^
    "}"

:: Capture the result of the PowerShell script
set "PATH_RESULT=%errorlevel%"

if %PATH_RESULT% equ 1 (
    echo [+] SUCCESS: Directory added to PATH.
    echo [!] NOTE: You must RESTART your app/terminal to see changes globally.
) else (
    echo [i] Path is already correct. No changes needed.
)

:: ============================================================
:: STEP 3: VERIFICATION
:: ============================================================
echo.
echo ============================================================
echo    FINAL VERIFICATION
echo ============================================================

:: Temporarily add to current session path so we can test immediately without restart
set "PATH=%PATH%;%INSTALL_DIR%"

echo [i] Running 'cloudflared --version' from command line...
cloudflared --version 2>&1

if %errorlevel% equ 0 (
    echo.
    echo [+] INSTALLATION SUCCESSFUL.
    echo [i] You can now use 'cloudflared' in any new CMD window.
) else (
    echo [!] Something went wrong verify the binary.
    exit /b 1
)

exit /b 0
