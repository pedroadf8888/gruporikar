@echo off
:: ============================================
:: Solicita elevação automática (UAC)
:: ============================================
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

if '%errorlevel%' NEQ '0' (
    echo Solicitando permissao de administrador...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

:: ============================================
:: Execução do instalador
:: ============================================
title WallSync - Instalador
echo ============================================
echo    WALLSYNC - INSTALADOR (ADMINISTRADOR)
echo ============================================
echo.
echo Executando instalador...
echo.
powershell -ExecutionPolicy Bypass -File "C:\scripts\instalar_wallsync.ps1"
pause