@echo off
title WallSync - Enviar Wallpaper
echo ============================================
echo        WALLSYNC - ENVIAR WALLPAPER
echo ============================================
echo.
echo Iniciando envio do wallpaper para GitHub...
echo.
powershell -ExecutionPolicy Bypass -File "C:\scripts\sender_github.ps1"
pause