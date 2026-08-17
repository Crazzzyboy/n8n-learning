@echo off
set N8N_USER_FOLDER=D:\n8n-data
n8n
if errorlevel 1 (
    echo Команда "n8n" не найдена напрямую, пробую через npx...
    npx n8n
)
pause
