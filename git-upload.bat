@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

echo ========================================
echo   Git 自動上傳工具 (通用網頁小工具版)
echo ========================================
echo.

:: 1. 檢查 Git 是否初始化
if not exist ".git" (
    echo [進度] 偵測到尚未初始化 Git，正在執行 git init...
    git init
    echo [完成] Git 初始化成功。
) else (
    echo [進度] Git 已在當前資料夾初始化。
)

:: 2. 提示輸入 GitHub Repo URL
echo.
set /p REPO_URL="請輸入 GitHub Repo URL (例如 https://github.com/user/my-tool.git): "
if "!REPO_URL!"=="" (
    echo [錯誤] 必須輸入 Repo URL！
    pause
    exit /b
)

:: 自動解析 URL 以獲得使用者名稱和倉庫名稱
:: 支援 https://github.com/user/repo.git 或 https://github.com/user/repo
set "URL_CLEAN=!REPO_URL!"
set "URL_CLEAN=!URL_CLEAN:.git=!"

for /f "tokens=4,5 delims=/" %%a in ("!URL_CLEAN!") do (
    set "GH_USER=%%a"
    set "GH_REPO=%%b"
)

:: 3. 設定 Remote (覆蓋舊的)
echo.
echo [進度] 正在設定遠端倉庫...
git remote remove origin >nul 2>&1
git remote add origin !REPO_URL!
echo [完成] 遠端倉庫已設定為: !REPO_URL!

:: 4. Git Add
echo.
echo [進度] 正在加入檔案變更...
git add .
echo [完成] 檔案已加入。

:: 5. 提示輸入 Commit Message
echo.
set "COMMIT_MSG=更新小工具"
set /p INPUT_MSG="請輸入 Commit Message [預設: 更新小工具]: "
if not "!INPUT_MSG!"=="" set "COMMIT_MSG=!INPUT_MSG!"

:: 執行 Commit
echo.
echo [進度] 正在提交變更...
git commit -m "!COMMIT_MSG!"
if %ERRORLEVEL% NEQ 0 (
    echo [資訊] 沒有新的變更需要提交。
) else (
    echo [完成] 變更已提交。
)

:: 6. 提示輸入 Username 和 Password (隱藏輸入)
echo.
set /p GH_USERNAME="請輸入 GitHub Username: "
echo 請輸入 GitHub Password 或 Personal Access Token (輸入時不會顯示內容):
for /f "delims=" %%i in ('powershell -Command "$p = read-host -assecurestring; $marshal = [System.Runtime.InteropServices.Marshal]; $marshal::PtrToStringAuto($marshal::SecureStringToBSTR($p))"') do set "GH_PASS=%%i"

:: 7. 推送到 Main Branch
echo.
echo [進度] 正在推送到 GitHub main 分支...
:: 使用憑證組合 URL 進行推送
set "PUSH_URL=!REPO_URL:https://=!"
git push -u "https://!GH_USERNAME!:!GH_PASS!@!PUSH_URL!" main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   上傳成功！
    echo ========================================
    echo 預覽網站網址: https://!GH_USER!.github.io/!GH_REPO!/
    echo.
    echo 提醒：請記得在 GitHub 倉庫的 [Settings] ^> [Pages] 
    echo       將 [Branch] 設定為 [main] 並存檔，才能啟用網頁。
) else (
    echo.
    echo [錯誤] 推送失敗，請檢查網路連線、憑證或 Repo 權限。
)

echo.
pause
