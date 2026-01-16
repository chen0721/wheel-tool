@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

echo ========================================
echo   Git 自動上傳工具 (通用網頁小工具版)
echo ========================================
echo.
echo [建立新 Repo 說明]
echo 1. 前往 https://github.com/new
echo 2. Repository name: [輸入小工具名稱] (例如 wheel-tool)
echo 3. 設定為 Public，建議勾選 "Add a README file"
echo 4. 點擊 "Create repository"
echo 5. 複製 [Code] 按鈕下的 HTTPS 網址
echo.
echo [輸入範例]
echo Repo URL: https://github.com/username/wheel-tool.git
echo.

:: 1. Check Git Init
if not exist ".git" (
    echo [進度] 偵測到尚未初始化 Git，正在執行 git init...
    git init
    git branch -M main
    echo [完成] Git 初始化成功。
) else (
    echo [進度] Git 已在當前資料夾初始化。
    git branch -M main
)

:: 2. Input Repo URL
echo.
set "EXISTING_URL="
for /f "tokens=*" %%i in ('git remote get-url origin 2^>nul') do set "EXISTING_URL=%%i"

if not "!EXISTING_URL!"=="" (
    echo 偵測到現有的遠端網址: !EXISTING_URL!
    set /p REPO_URL="請確認或輸入新的 Repo URL [直接按 Enter 使用現有]: "
    if "!REPO_URL!"=="" set "REPO_URL=!EXISTING_URL!"
) else (
    set /p REPO_URL="請輸入 GitHub Repo URL (例如 https://github.com/user/my-tool.git): "
)

if "!REPO_URL!"=="" (
    echo [錯誤] 必須輸入 Repo URL！
    pause
    exit /b
)

:: Clean URL (Remove trailing slash and .git)
set "URL_CLEAN=!REPO_URL!"
if "!URL_CLEAN:~-1!"=="/" set "URL_CLEAN=!URL_CLEAN:~0,-1!"
set "URL_CLEAN=!URL_CLEAN:.git=!"

for /f "tokens=4,5 delims=/" %%a in ("!URL_CLEAN!") do (
    set "GH_USER=%%a"
    set "GH_REPO=%%b"
)

:: 3. Set Remote
echo.
if not "!REPO_URL!"=="!EXISTING_URL!" (
    echo [進度] 正在更新遠端倉庫設定...
    git remote remove origin >nul 2>&1
    git remote add origin !REPO_URL!
    echo [完成] 遠端倉庫已更新。
) else (
    echo [資訊] 使用現有的遠端位址。
)

:: 4. Git Add
echo.
echo [進度] 正在加入檔案變更...
git add .
echo [完成] 檔案已加入。

:: 5. Commit Message
echo.
set "COMMIT_MSG=更新小工具"
set /p INPUT_MSG="請輸入 Commit Message [預設: 更新小工具]: "
if not "!INPUT_MSG!"=="" set "COMMIT_MSG=!INPUT_MSG!"

echo.
echo [進度] 正在提交變更...
git commit -m "!COMMIT_MSG!"
if %ERRORLEVEL% NEQ 0 (
    echo [資訊] 沒有新的變更需要提交。
) else (
    echo [完成] 變更已提交。
)

:PUSH_RETRY
:: 6. Credentials
echo.
set /p GH_USERNAME="請輸入 GitHub Username: "
echo 請輸入 GitHub Personal Access Token (PAT):
echo (注意: 請勿輸入登入密碼，請使用 Token)
echo (輸入時不會顯示內容)
for /f "delims=" %%i in ('powershell -Command "$p = read-host -assecurestring; $marshal = [System.Runtime.InteropServices.Marshal]; $marshal::PtrToStringAuto($marshal::SecureStringToBSTR($p))"') do set "GH_PASS=%%i"

:: 7. Push to Main
echo.
echo [進度] 正在推送到 GitHub main 分支...
echo --------------------------------------------------
:: URL Format: https://user:token@github.com/user/repo
set "PUSH_DOMAIN=!REPO_URL:https://=!"
git push -u "https://!GH_USERNAME!:!GH_PASS!@!PUSH_DOMAIN!" main

if %ERRORLEVEL% EQU 0 (
    echo --------------------------------------------------
    echo.
    echo ****************************************
    echo   上傳成功！
    echo ****************************************
    echo.
    echo [預覽網站網址] 
    echo https://!GH_USER!.github.io/!GH_REPO!/
    echo.
    echo [提醒] 
    echo 記得 GitHub Settings ^> Pages 啟用 main branch
    echo.
    echo ========================================
    echo 操作已完成，請按任意鍵關閉視窗。
) else (
    echo --------------------------------------------------
    echo.
    echo [錯誤] 推送失敗！
    echo 請檢查:
    echo 1. Username 或 Token 是否正確
    echo 2. 網路連線是否正常
    echo.
    set /p RETRY_CHOICE="是否重試？ (Y/N): "
    if /i "!RETRY_CHOICE!"=="Y" (
        goto PUSH_RETRY
    ) else (
        echo [資訊] 操作已結束。
    )
)

echo.
pause
