# dotnet-skills 本地 Git Pre-commit Hook 安裝腳本
# 使用方式：.\scripts\setup-git-hooks.ps1

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$RepoRoot = Split-Path $PSScriptRoot -Parent
$HooksDir = Join-Path $RepoRoot ".git/hooks"

if (-not (Test-Path $HooksDir)) {
    Write-Host "❌ 錯誤：找不到 .git/hooks 目錄。請確認您是在 Git 專案根目錄下執行此腳本。" -ForegroundColor Red
    exit 1
}

$PreCommitPath = Join-Path $HooksDir "pre-commit"

$HookContent = @'
#!/bin/sh
echo "========================================="
echo "  正在執行本地 Git Pre-commit 驗證..."
echo "========================================="

if command -v pwsh >/dev/null 2>&1; then
    pwsh -ExecutionPolicy Bypass -File ./scripts/validate-skills.ps1
    VAL_RES=$?
    pwsh -ExecutionPolicy Bypass -File ./scripts/generate-index.ps1
    GEN_RES=$?
elif command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -ExecutionPolicy Bypass -File ./scripts/validate-skills.ps1
    VAL_RES=$?
    powershell.exe -ExecutionPolicy Bypass -File ./scripts/generate-index.ps1
    GEN_RES=$?
else
    echo "⚠️ 系統找不到 PowerShell 環境，將跳過 pre-commit 檢查。"
    exit 0
fi

if [ $VAL_RES -ne 0 ]; then
    echo "❌ 錯誤：Skills 結構驗證失敗！已終止 Commit。"
    exit 1
fi

if [ $GEN_RES -ne 0 ]; then
    echo "❌ 錯誤：README 索引產生失敗！已終止 Commit。"
    exit 1
fi

# 自動將自動生成的 README.md 加入本次 Commit 的暫存區
git add README.md
echo "✅ 驗證與索引更新成功，允許提交！"
'@

try {
    # Git hooks 必須使用 LF (Unix) 換行格式，且編碼必須為 UTF-8 without BOM，否則 Git Bash 會因讀到 BOM 頭 (\xef\xbb\xbf) 或 \r 導致 "No such file or directory" 錯誤
    $LfContent = $HookContent -replace "`r`n", "`n"
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($PreCommitPath, $LfContent, $Utf8NoBom)
    Write-Host "✅ 已成功配置 Git pre-commit hook 至：$PreCommitPath" -ForegroundColor Green
}
catch {
    Write-Host "❌ 寫入 pre-commit hook 失敗：$($_.Exception.Message)" -ForegroundColor Red
}
