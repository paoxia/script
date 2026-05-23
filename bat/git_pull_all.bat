@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo Git Repository Batch Update Tool
echo ============================================================
echo.

REM Check if git is installed
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git not found. Please install Git and add to PATH.
    echo.
    pause
    exit /b 1
)

echo Current directory: %cd%
echo.

set "success=0"
set "fail=0"
set "found=0"

REM Loop through all subdirectories
for /d %%d in (*) do (
    if exist "%%d\.git" (
        set /a found+=1
        echo --------------------------------------------------
        echo Updating: %%d
        echo --------------------------------------------------
        pushd "%%d"
        git pull
        if !errorlevel! equ 0 (
            set /a success+=1
            echo [SUCCESS] %%d
        ) else (
            set /a fail+=1
            echo [FAILED] %%d
        )
        popd
        echo.
    )
)

echo ============================================================
if %found% equ 0 (
    echo [INFO] No git repository found.
    echo Make sure there are subdirectories with .git folder.
) else (
    echo Done: Success=%success%, Failed=%fail%, Total=%found%
)
echo ============================================================
echo.
pause
