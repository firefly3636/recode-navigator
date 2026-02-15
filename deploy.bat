@echo off
chcp 65001 >nul
echo ============================================
echo   リコード法ナビゲーター デプロイツール
echo ============================================
echo.

:: PATH更新
set "PATH=%PATH%;C:\Program Files\Git\cmd;C:\Program Files\GitHub CLI"

:: GitHub認証チェック
gh auth status >nul 2>&1
if %errorlevel% neq 0 (
    echo [1] まずGitHubにログインします...
    echo     ブラウザが開いたら、表示されるコードを入力してください。
    echo.
    gh auth login --web --git-protocol https
    if %errorlevel% neq 0 (
        echo.
        echo エラー: GitHubログインに失敗しました。
        echo 手動デプロイの手順は DEPLOY_README.txt を参照してください。
        pause
        exit /b 1
    )
)

echo.
echo [2] GitHubにログイン済みです。
echo.

:: リポジトリの存在確認
gh repo view recode-navigator >nul 2>&1
if %errorlevel% neq 0 (
    echo [3] GitHubリポジトリを作成します...
    gh repo create recode-navigator --public --description "リコード法ナビゲーター - 認知症予防・改善の包括的ガイド" --clone
    cd recode-navigator
) else (
    echo [3] 既存のリポジトリを使用します...
    if not exist recode-navigator (
        gh repo clone recode-navigator
    )
    cd recode-navigator
)

:: ファイルをコピー
echo [4] ファイルをコピーしています...
copy /Y "%~dp0index.html" . >nul
copy /Y "%~dp0manifest.json" . >nul
copy /Y "%~dp0sw.js" . >nul
copy /Y "%~dp0icon-192.svg" . >nul
copy /Y "%~dp0icon-512.svg" . >nul
copy /Y "%~dp0favicon.svg" . >nul

:: Git操作
echo [5] GitHubにプッシュしています...
git add -A
git commit -m "Deploy recode-navigator app"
git push origin main

:: GitHub Pages有効化
echo [6] GitHub Pagesを有効化しています...
gh api repos/{owner}/recode-navigator/pages -X POST -f build_type=legacy -f source[branch]=main -f source[path]="/" 2>nul
if %errorlevel% neq 0 (
    gh api repos/{owner}/recode-navigator/pages -X PUT -f build_type=legacy -f source[branch]=main -f source[path]="/" 2>nul
)

:: URL取得
echo.
echo ============================================
echo   デプロイ完了！
echo ============================================
echo.
echo   数分後に以下のURLでアクセスできます：
for /f "tokens=*" %%a in ('gh api "repos/{owner}/recode-navigator/pages" --jq ".html_url" 2^>nul') do echo   %%a
echo.
echo   （GitHub Pagesの反映に1〜2分かかる場合があります）
echo ============================================
pause
