@echo off
setlocal enabledelayedexpansion
title Запуск RAG-стека (Qdrant + ngrok + n8n)

echo ============================================
echo   Запуск стека для кейса 11 (RAG)
echo   Docker Desktop -^> Qdrant -^> ngrok -^> n8n
echo ============================================
echo.
echo Нужны: docker, ngrok, n8n (или npx) в PATH.
echo Для обычного запуска n8n используй "Запуск n8n.bat".
echo.

where docker >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] Docker не найден в PATH.
    pause
    exit /b 1
)
where ngrok >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] ngrok не найден в PATH.
    pause
    exit /b 1
)

echo [1/4] Проверяю Docker...
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker не запущен, стартую Docker Desktop...
    if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" (
        start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
    ) else (
        echo [ОШИБКА] Не нашёл Docker Desktop.exe по стандартному пути.
        pause
        exit /b 1
    )
    echo Жду, пока Docker поднимется...
    :waitdocker
    timeout /t 3 >nul
    docker info >nul 2>&1
    if errorlevel 1 goto waitdocker
)
echo Docker готов.
echo.

echo [2/4] Включаю Qdrant...
docker start qdrant >nul 2>&1
if errorlevel 1 (
    echo Контейнер qdrant не найден, создаю новый...
    docker run -d --name qdrant -p 6333:6333 -p 6334:6334 -v qdrant_storage:/qdrant/storage qdrant/qdrant
)
echo Qdrant включён.
echo.

echo [3/4] Запускаю ngrok в отдельном окне...
start "ngrok" cmd /k ngrok http 5678

echo Жду публичный адрес от ngrok...
set NGROK_URL=
set /a TRIES=0
:waitngrok
timeout /t 2 >nul
set /a TRIES+=1
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "try { (Invoke-RestMethod http://localhost:4040/api/tunnels -TimeoutSec 2).tunnels[0].public_url } catch { '' }"`) do set NGROK_URL=%%A
if "!NGROK_URL!"=="" (
    if !TRIES! GEQ 30 (
        echo [ОШИБКА] ngrok не выдал адрес за 60 секунд.
        pause
        exit /b 1
    )
    goto waitngrok
)
echo Публичный адрес: !NGROK_URL!
echo.

echo [4/4] Запускаю n8n в отдельном окне (WEBHOOK_URL=!NGROK_URL!)...
set N8N_USER_FOLDER=D:\n8n-data
start "n8n" cmd /k "set N8N_USER_FOLDER=D:\n8n-data && set WEBHOOK_URL=!NGROK_URL! && n8n || npx n8n"

echo.
echo ============================================
echo   n8n локально:  http://localhost:5678
echo   n8n снаружи:    !NGROK_URL!
echo   Qdrant:         http://localhost:6333/dashboard
echo ============================================
pause
