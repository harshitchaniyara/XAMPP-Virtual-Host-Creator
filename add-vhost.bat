@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: AUTO-ELEVATE — Relaunch with Admin rights if needed
:: ============================================================
net session >nul 2>&1
if errorlevel 1 (
    echo [INFO] Requesting Administrator privileges...
    echo [INFO] A UAC prompt will appear. Please click Yes.
    timeout /t 2 >nul
    powershell -Command "Start-Process cmd.exe -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: ============================================================
:: STEP 1 — Confirm Admin
:: ============================================================
echo [OK]   Running as Administrator.

:: ============================================================
:: STEP 2 — Verify XAMPP Installation Path
:: ============================================================
set "XAMPP_PATH=C:\xampp"

if not exist "%XAMPP_PATH%\" (
    echo [FAIL] XAMPP not found at: %XAMPP_PATH%
    echo.
    echo  HOW TO FIX:
    echo  Open this script in Notepad and change XAMPP_PATH to your
    echo  actual XAMPP installation folder.
    echo.
    pause
    exit /b 1
)
echo [OK]   XAMPP found at: %XAMPP_PATH%

:: --- Define all file paths ---
set "VHOSTS_FILE=%XAMPP_PATH%\apache\conf\extra\httpd-vhosts.conf"
set "HTTPD_CONF=%XAMPP_PATH%\apache\conf\httpd.conf"
set "HOSTS_FILE=%SystemRoot%\System32\drivers\etc\hosts"

:: ============================================================
:: STEP 3 — Verify Required Files Exist
:: ============================================================
if not exist "%VHOSTS_FILE%" (
    echo [FAIL] vhosts config not found: %VHOSTS_FILE%
    pause & exit /b 1
)
echo [OK]   vhosts config found.

if not exist "%HTTPD_CONF%" (
    echo [FAIL] httpd.conf not found: %HTTPD_CONF%
    pause & exit /b 1
)
echo [OK]   httpd.conf found.

if not exist "%HOSTS_FILE%" (
    echo [FAIL] Hosts file not found: %HOSTS_FILE%
    pause & exit /b 1
)
echo [OK]   Hosts file found.

:: ============================================================
:: STEP 4 — Check httpd-vhosts.conf is Included in httpd.conf
:: ============================================================
findstr /i /c:"Include conf/extra/httpd-vhosts.conf" "%HTTPD_CONF%" >nul 2>&1
if errorlevel 1 (
    echo.
    echo [WARN] httpd-vhosts.conf is NOT included in httpd.conf.
    echo        Apache will IGNORE your virtual host entries.
    echo.
    echo  HOW TO FIX:
    echo  Open: %HTTPD_CONF%
    echo  Find and uncomment this line (remove the # at the start^):
    echo      # Include conf/extra/httpd-vhosts.conf
    echo.
    choice /c YN /m "Continue anyway (not recommended)?"
    if errorlevel 2 (
        echo Cancelled. Please fix httpd.conf first.
        pause & exit /b 0
    )
    echo.
) else (
    echo [OK]   httpd-vhosts.conf is included in httpd.conf.
)

:: ============================================================
:: STEP 5 — Get Project Directory from User
:: ============================================================
echo.
echo ------------------------------------------------------------
set /p "PROJECT_DIR=Enter full path to your project public folder: "
echo ------------------------------------------------------------

if not defined PROJECT_DIR (
    echo [FAIL] Project directory cannot be empty.
    pause & exit /b 1
)

:: Remove trailing backslash
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

if not exist "%PROJECT_DIR%\" (
    echo [FAIL] Directory does not exist: %PROJECT_DIR%
    pause & exit /b 1
)
echo [OK]   Project directory verified.

:: ============================================================
:: STEP 6 — Get Domain Name from User
:: ============================================================
echo.
echo ------------------------------------------------------------
set /p "DOMAIN_NAME=Enter local domain name (e.g., myproject.local): "
echo ------------------------------------------------------------

if not defined DOMAIN_NAME (
    echo [FAIL] Domain name cannot be empty.
    pause & exit /b 1
)

echo %DOMAIN_NAME% | findstr /r "\." >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Invalid domain. Must contain a dot e.g. myproject.local
    pause & exit /b 1
)
echo [OK]   Domain accepted: %DOMAIN_NAME%

:: ============================================================
:: STEP 7 — Duplicate Domain Check
:: ============================================================
findstr /i /c:"ServerName %DOMAIN_NAME%" "%VHOSTS_FILE%" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] '%DOMAIN_NAME%' already exists in vhosts config.
    pause & exit /b 1
)
echo [OK]   No duplicate in vhosts config.

findstr /i /c:" %DOMAIN_NAME%" "%HOSTS_FILE%" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] '%DOMAIN_NAME%' already exists in hosts file.
    pause & exit /b 1
)
echo [OK]   No duplicate in hosts file.

:: ============================================================
:: STEP 8 — Confirm Before Writing
:: ============================================================
echo.
echo ============================================================
echo   SUMMARY
echo ============================================================
echo   Directory : %PROJECT_DIR%
echo   Domain    : http://%DOMAIN_NAME%
echo   Alias     : http://www.%DOMAIN_NAME%
echo ============================================================
choice /c YN /m "Proceed and create virtual host?"
if errorlevel 2 (
    echo Cancelled. No files were modified.
    pause & exit /b 0
)

:: ============================================================
:: STEP 9 — Write to httpd-vhosts.conf
:: ============================================================
echo.
echo Writing virtual host entry...
(
    echo.
    echo # -----------------------------------------------
    echo # Virtual Host for %DOMAIN_NAME%
    echo # Created by XAMPP Virtual Host Creator
    echo # -----------------------------------------------
    echo ^<VirtualHost *:80^>
    echo     DocumentRoot "%PROJECT_DIR%"
    echo     ServerName %DOMAIN_NAME%
    echo     ServerAlias www.%DOMAIN_NAME%
    echo     ^<Directory "%PROJECT_DIR%"^>
    echo         Options Indexes FollowSymLinks
    echo         AllowOverride All
    echo         Require all granted
    echo     ^</Directory^>
    echo     ErrorLog "logs/%DOMAIN_NAME%-error.log"
    echo     CustomLog "logs/%DOMAIN_NAME%-access.log" combined
    echo ^</VirtualHost^>
) >> "%VHOSTS_FILE%"

findstr /i /c:"ServerName %DOMAIN_NAME%" "%VHOSTS_FILE%" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Vhosts entry was NOT written. Check permissions.
    pause & exit /b 1
)
echo [OK]   Vhosts entry written.

:: ============================================================
:: STEP 10 — Write to Hosts File
:: ============================================================
echo Writing hosts file entries...
(
    echo.
    echo # Added by XAMPP Virtual Host Creator
    echo 127.0.0.1       %DOMAIN_NAME%
    echo 127.0.0.1       www.%DOMAIN_NAME%
) >> "%HOSTS_FILE%"

findstr /i /c:" %DOMAIN_NAME%" "%HOSTS_FILE%" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Hosts entry was NOT written. Check permissions.
    pause & exit /b 1
)
echo [OK]   Hosts file u