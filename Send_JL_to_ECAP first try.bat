@echo off
setlocal EnableExtensions
title ECAP - Prepare JL Database
color 1F
echo ============================================================
echo    ECAP Processing Services - JL Database Export Tool
echo ============================================================
echo.

REM ---- 1. Find the JL database path in the registry ----
set "DBPATH="
for /f "tokens=2,*" %%A in ('reg query "HKCU\Software\VB and VBA Program Settings\Tuition\Databases" /v Master 2^>nul ^| find /i "Master"') do set "DBPATH=%%B"

if not defined DBPATH (
    color 4F
    echo  ERROR: The JL program was not found for this user.
    echo.
    echo  This tool must be run on a computer where JL is installed,
    echo  while logged in as the Windows user who uses JL.
    goto :fail
)

if not exist "%DBPATH%" (
    color 4F
    echo  ERROR: JL is installed, but the database file was not found:
    echo     %DBPATH%
    echo.
    echo  Please contact ECAP for assistance.
    goto :fail
)

echo  JL database found:
echo     %DBPATH%
echo.

REM ---- 2. Build file names (date is locale-independent) ----
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"`) do set "TODAY=%%D"
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESKTOP=%%D"
for %%F in ("%DBPATH%") do set "DBNAME=%%~nxF"

set "WORKDIR=%TEMP%\ECAP_JL_Export"
set "ZIPNAME=%TODAY% JL For ECAP.zip"
set "ZIPPATH=%DESKTOP%\%ZIPNAME%"

REM ---- 3. Copy database to a temporary folder ----
echo  Copying database...
if exist "%WORKDIR%" rd /s /q "%WORKDIR%"
md "%WORKDIR%"
copy /y "%DBPATH%" "%WORKDIR%\%DBNAME%" >nul
if errorlevel 1 (
    color 4F
    echo.
    echo  ERROR: Could not copy the database.
    echo  Please close the JL program on ALL computers and try again.
    rd /s /q "%WORKDIR%" 2>nul
    goto :fail
)

REM ---- 4. Zip the copy to the Desktop ----
echo  Creating zip file...
if exist "%ZIPPATH%" del /f /q "%ZIPPATH%"
powershell -NoProfile -Command "Compress-Archive -LiteralPath '%WORKDIR%\%DBNAME%' -DestinationPath '%ZIPPATH%' -Force"
if not exist "%ZIPPATH%" (
    color 4F
    echo.
    echo  ERROR: The zip file could not be created.
    rd /s /q "%WORKDIR%" 2>nul
    goto :fail
)

REM ---- 5. Clean up temporary copy ----
rd /s /q "%WORKDIR%" 2>nul

REM ---- 6. Done - show the user ----
color 2F
echo.
echo ============================================================
echo  DONE!
echo.
echo  A file named:
echo       %ZIPNAME%
echo  was saved to your Desktop.
echo.
echo  Please send this file to ECAP.
echo ============================================================
echo.
explorer /select,"%ZIPPATH%"
pause
exit /b 0

:fail
echo.
echo  Questions? Contact ECAP: 347-598-8798 / ibreuerfa@gmail.com
echo.
pause
exit /b 1