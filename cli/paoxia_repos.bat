@echo off
setlocal enabledelayedexpansion

set GITHUB_USER=paoxia
set GITHUB_API=https://api.github.com/users/%GITHUB_USER%/repos
set TARGET_DIR=%~1
if "%TARGET_DIR%"=="" set TARGET_DIR=%cd%

echo ============================================================
echo   Paoxia GitHub Repositories Clone Tool
echo ============================================================
echo.

echo Target directory: %TARGET_DIR%
echo Fetching repositories for user: %GITHUB_USER%
echo.

if "%~2"=="" goto :menu

if /i "%~2"=="-l" goto :list_repos
if /i "%~2"=="--list" goto :list_repos
if /i "%~2"=="-c" goto :clone_repos
if /i "%~2"=="--clone" goto :clone_repos
if /i "%~2"=="-h" goto :show_usage
if /i "%~2"=="--help" goto :show_usage

:show_usage
echo Usage: %~nx0 [target_directory] [options]
echo.
echo Options:
echo   -l, --list      List all repositories
echo   -c, --clone     Clone all repositories
echo   -h, --help      Show this help message
echo.
echo Examples:
echo   %~nx0 C:\projects -l          List all repos
echo   %~nx0 C:\projects -c          Clone all repos to C:\projects
echo.
exit /b 0

:menu
echo Select action:
echo   1) List repositories
echo   2) Clone all repositories
echo   3) Exit
echo.
set /p action="Enter choice (1-3): "

if "%action%"=="1" goto :list_repos
if "%action%"=="2" goto :clone_repos
if "%action%"=="3" exit /b 0
echo Invalid choice
exit /b 1

:list_repos
echo Repositories for %GITHUB_USER%:
echo ----------------------------------------

set count=0
for /f "tokens=* delims=" %%i in ('curl -s "%GITHUB_API%?type=all&per_page=100" ^| jq -r ".[].name" 2^>nul') do (
    set /a count+=1
    echo   !count!. %%i
)

echo.
echo Total: !count! repositories
goto :end

:clone_repos
echo Cloning repositories...
echo ----------------------------------------

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

for /f "tokens=* delims=" %%i in ('curl -s "%GITHUB_API%?type=all&per_page=100" ^| jq -r ".[].name" 2^>nul') do (
    set repo=%%i
    set repo_url=https://github.com/%GITHUB_USER%/!repo!.git
    set target_path=%TARGET_DIR%\!repo!

    if exist "!target_path!" (
        echo   [SKIP] !repo! (already exists^)
    ) else (
        echo   [CLONE] !repo!
        git clone !repo_url! "!target_path!" 2>nul
        if errorlevel 1 echo   [ERROR] Failed to clone !repo!
    )
)

echo.
echo Done!
goto :end

:end
echo.
echo ============================================================
echo   GitHub: https://github.com/%GITHUB_USER%
echo ============================================================

endlocal
