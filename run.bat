@echo off

setlocal enabledelayedexpansion

rem Specify the path to the var.env file
set env_file=app\var.env

rem Check if the file exists
if not exist "%env_file%" (
    echo File %env_file% not found!
    exit /b 1
)


rem Read the file line by line and set the variables
for /f "tokens=1,2 delims==" %%a in ('type "%env_file%"') do (
    SET %%a=%%b
    echo Setting %%a=%%b
)

SET "PROJECT_PATH=%cd%"
echo Setting PROJECT_PATH=%PROJECT_PATH%

IF NOT EXIST "app" (
    mkdir "app"
)

IF NOT EXIST "data" (
    mkdir "data"
)

IF NOT EXIST "log" (
    mkdir "log"
)

docker-compose down
docker-compose build
docker-compose up -d

set /p confirm="Do you want to enter the container shell? (y/n): "

if /i "%confirm%"=="y" (
    docker exec -it %COMICRACK_CONTAINER% /bin/bash
) else (
    echo Command canceled.
)

endlocal
