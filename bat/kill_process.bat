@echo off

set port=8080

echo finding process on port %port%...

for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%port%') do (
    set pid=%%a
)

if defined pid (
    echo found process PID：%pid%
    tasklist /FI "PID eq %pid%"
    echo killing process on port...
    taskkill /PID %pid% /F
    echo success killed process on port %port%
) else (
    echo no process found on port %port%.
)

pause
