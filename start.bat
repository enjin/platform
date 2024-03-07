@echo off
setlocal enabledelayedexpansion

goto :MAIN

:: Function to check if the APP_URL is set and prompt the user if not
:check_has_app_url
:: Check if APP_URL is already set
set "APP_URL="
for /f "tokens=2 delims==" %%i in ('findstr /r /c:"APP_URL=" configs\core\.env') do (
    set "APP_URL=%%i"
)
:: If not set, prompt the user
if "%APP_URL%"=="" (
    echo For a few things to work, we need to know your platform URL
    set /p APP_URL="Please input the URL: (e.g. http://127.0.0.1:8000) "
    if "%APP_URL%"=="" (
        set "APP_URL=http://127.0.0.1:8000"
    )
    powershell -Command "(Get-Content 'configs\core\.env') | ForEach-Object {$_ -replace '\bAPP_URL=.*', 'APP_URL=!APP_URL!'} | Set-Content 'configs\core\.env'"
)
goto :EOF

:: Function to generate a new basic auth token and set it in the .env file
:generate_basic_token
:: Generate a new basic auth token
set "BASIC_TOKEN="
for /l %%i in (1,1,64) do (
    set /a "rand=!random! %% 16"
    for %%x in (!rand!) do (
        set "hexDigit=0123456789ABCDEF"
        for /f %%d in ("!hexDigit:~%%x,1!") do (
            set "BASIC_TOKEN=!BASIC_TOKEN!%%d"
        )
    )
)
echo Done, your basic static token is: !BASIC_TOKEN!
:: Replace the BASIC_AUTH_TOKEN in the .env file
powershell -Command "(Get-Content 'configs\core\.env') | ForEach-Object {$_ -replace '\bBASIC_AUTH_TOKEN=.*', 'BASIC_AUTH_TOKEN=!BASIC_TOKEN!'} | Set-Content 'configs\core\.env'"
powershell -Command "(Get-Content 'configs\daemon\.env') | ForEach-Object {$_ -replace '\bPLATFORM_KEY=.*', 'PLATFORM_KEY=!BASIC_TOKEN!'} | Set-Content 'configs\daemon\.env'"
goto :EOF

:: Function to check if the BASIC_AUTH_TOKEN is set and prompt the user if not
:check_has_basic_token
:: Check if BASIC_AUTH_TOKEN is already set
set "AUTH_TOKEN="
for /f "tokens=2 delims==" %%i in ('findstr /r /c:"BASIC_AUTH_TOKEN=" configs\core\.env') do (
    set "AUTH_TOKEN=%%i"
)
:: If not set, prompt the user
if "%AUTH_TOKEN%"=="" (
    echo We also use a static token to protect your platform from unauthorized access
    set /p generate_token="Your BASIC_AUTH_TOKEN is not set, do you want to generate one? (y/n) "
    if /i "!generate_token!"=="n" (
        echo Please set BASIC_AUTH_TOKEN in configs\core\.env and run this script again
        exit /b 1
    ) else (
        call :generate_basic_token
    )
)
goto :EOF

:: Function to check if the $APP_KEY is set and generate a new one if not
:check_and_generate_app_key
:: Check if $APP_KEY is already set
set "APP_KEY="
for /f "tokens=2 delims==" %%i in ('findstr /r /c:"APP_KEY=" configs\core\.env') do (
    set "APP_KEY=%%i"
)
:: If not set, generate a new key automatically
if "%APP_KEY%"=="" (
    echo No application key set. A new key will be generated automatically.

    for /f "delims=" %%i in ('powershell -Command "$RandomBytes = New-Object byte[] 32; [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($RandomBytes); $Base64String = [Convert]::ToBase64String($RandomBytes); Write-Output $Base64String"') do (
        set "APP_KEY=%%i"
    )

    powershell -Command "(Get-Content 'configs\core\.env') | ForEach-Object {$_ -replace '\bAPP_KEY=.*', 'APP_KEY=base64:!APP_KEY!'} | Set-Content 'configs\core\.env'"
)
goto :EOF

:: Function to generate a daemon password and set it in the .env file
:generate_daemon_password
:: Generate a new daemon password
set "WALLET_PASSWORD="
for /l %%i in (1,1,64) do (
    set /a "rand=!random! %% 16"
    for %%x in (!rand!) do (
        set "hexDigit=0123456789ABCDEF"
        for /f %%d in ("!hexDigit:~%%x,1!") do (
            set "WALLET_PASSWORD=!WALLET_PASSWORD!%%d"
        )
    )
)
echo Done, your daemon password is: !WALLET_PASSWORD!
:: Replace the KEY_PASS in the .env file
powershell -Command "(Get-Content 'configs\daemon\.env') | ForEach-Object {$_ -replace '\bKEY_PASS=.*', 'KEY_PASS=!WALLET_PASSWORD!'} | Set-Content 'configs\daemon\.env'"
goto :EOF

:: Function to check if the KEY_PASS is set and prompt the user if not
:check_has_daemon_password
:: Check if KEY_PASS is already set
set "KEY_PASS="
for /f "tokens=2 delims==" %%i in ('findstr /r /c:"KEY_PASS=" configs\daemon\.env') do (
    set "KEY_PASS=%%i"
)
:: If not set, prompt the user
if "%KEY_PASS%"=="" (
    echo Finally, we also use a password to protect your wallet daemon
    set /p generate_daemon="Your KEY_PASS is not set, do you want to generate one? (y/n) "
    if /i "!generate_daemon!"=="n" (
        echo Please set KEY_PASS in configs\daemon\.env and run this script again
        exit /b 1
    ) else (
        call :generate_daemon_password
    )
)
goto :EOF

:: Function to get the wallet daemon address
:get_daemon_address
:: Check if DAEMON_ACCOUNT is already set
set "DAEMON_ACCOUNT="
for /f "tokens=2 delims==" %%i in ('findstr /r /c:"DAEMON_ACCOUNT=" configs\core\.env') do (
    set "DAEMON_ACCOUNT=%%i"
)
:: If not set, get the address
if "%DAEMON_ACCOUNT%"=="" (
    echo Let's get your wallet daemon address, please wait...
    (docker compose up -d daemon)
    for /f "delims=" %%a in ('docker compose logs daemon 2^>^&1 ^| findstr /r /c:"Efinity:"') do (
        for %%w in (%%a) do set "WALLET_ADDRESS=%%w" 
    )
    echo Your wallet daemon address is: !WALLET_ADDRESS!
    powershell -Command "(Get-Content 'configs\core\.env') | ForEach-Object {$_ -replace '\bDAEMON_ACCOUNT=.*', 'DAEMON_ACCOUNT=!WALLET_ADDRESS!'} | Set-Content 'configs\core\.env'"
) else (
    echo Your wallet daemon address is: %DAEMON_ACCOUNT%
)
goto :EOF

:: Function to check if Docker is installed
:check_docker_is_installed
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo Please install Docker and run this script again
    exit /b 1
)
goto :EOF

:: Function to check if Docker Compose is installed
:check_compose_is_installed
docker compose --version >nul 2>nul
if %errorlevel% neq 0 (
    echo Please install Docker Compose and run this script again
    exit /b 1
)
goto :EOF

:: Function to check if Docker is running
:check_docker_is_running
docker ps >nul 2>nul
if %errorlevel% neq 0 (
    echo Please start Docker and run this script again
    exit /b 1
)
goto :EOF

:: Function to check if OpenSSL is installed
:check_openssl_is_installed
where openssl >nul 2>nul
if %errorlevel% neq 0 (
    echo Please install OpenSSL and run this script again
    exit /b 1
)
goto :EOF

:: Function to check if Git is installed
:check_git_is_installed
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo Please install Git and run this script again
    exit /b 1
)
goto :EOF


:MAIN
echo Welcome to Enjin Platform, this script will help you start it up
call :check_git_is_installed

:: Initialize Git submodules
git submodule update --init

call :check_has_app_url
call :check_has_basic_token
call :check_has_daemon_password
call :check_and_generate_app_key

:: Build the daemon container
docker compose build daemon
call :get_daemon_address

:: Prompt the user to start platform services
set /p start_services=Do you want to start all platform services? (y/n)
if /i "%start_services%"=="y" (
    docker compose build
    docker compose up -d
    echo Your Enjin Platform is now running, please visit: http://127.0.0.1:8000
) else (
    docker compose down
    echo Please run this script again when you are ready
    exit /b 1
)
