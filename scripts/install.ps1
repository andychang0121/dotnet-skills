# dotnet-skills 安裝腳本
# 使用方式：在你的專案目錄執行此腳本
# iwr https://raw.githubusercontent.com/andychang0121/dotnet-skills/main/scripts/install.ps1 | iex

param(
    [string]$ProjectPath = "",  # 專案路徑（空白則互動詢問）
    [int]$ToolChoice = 0,       # AI 工具選擇（0 則互動詢問）
    [switch]$Force              # 是否強制安裝（跳過確認提示）
)

# 避免環境設定了 $ErrorActionPreference = "Stop" 導致 git clone 警告被誤判為終止錯誤
$ErrorActionPreference = "Continue"

$RepoRaw = "https://raw.githubusercontent.com/andychang0121/dotnet-skills/main"
$RepoUrl = "https://github.com/andychang0121/dotnet-skills.git"

# 修正中文亂碼問題
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 標題與歡迎訊息
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "       .NET Skills 安裝程式 v0.1.0" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "歡迎使用 .NET Skills 安裝程式！" -ForegroundColor White
Write-Host "本程式將引導您下載並安裝專為 .NET REST API 設計的 AI 技能包與設定檔。" -ForegroundColor White
Write-Host ""

# 確認是否繼續安裝
if (-not $Force) {
    Write-Host "是否確定要繼續安裝？[Y/N]" -ForegroundColor Yellow
    $Confirm = Read-Host "> "
    if ($Confirm -notmatch "^[yY](es)?$") {
        Write-Host ""
        Write-Host "⚠️ 安裝已被取消。未對系統或專案進行任何變更。" -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }
}

Write-Host ""
Write-Host "----------------------------------------------" -ForegroundColor Cyan
Write-Host "開始進行安裝設定..." -ForegroundColor Cyan
Write-Host "----------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# 詢問專案路徑
if ($ProjectPath -eq "") {
    Write-Host "請輸入您的專案資料夾路徑（直接按 Enter 為目前目錄 '$((Get-Location).Path)'）:" -ForegroundColor Yellow
    $inputPath = Read-Host "> "
    $ProjectPath = if (([string]::IsNullOrWhiteSpace($inputPath))) { (Get-Location).Path } else { $inputPath }
}

# 驗證並建立路徑
if (-not (Test-Path $ProjectPath)) {
    Write-Host "⚠️ 注意：指定的路徑不存在：$ProjectPath" -ForegroundColor Yellow
    Write-Host "🔧 正在為您建立該目錄..." -ForegroundColor Cyan
    try {
        New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
        Write-Host "✅ 目錄建立成功！" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ 建立目錄失敗，請檢查權限或路徑格式。" -ForegroundColor Red
        exit 1
    }
}

$ProjectPath = (Resolve-Path $ProjectPath).Path
Write-Host ""
Write-Host "  最終安裝路徑：$ProjectPath" -ForegroundColor Green
Write-Host ""

# 詢問 AI 工具
if ($ToolChoice -eq 0) {
    Write-Host "請選擇您的 AI 開發工具：" -ForegroundColor Yellow
    Write-Host "  1. VS Code / Visual Studio (GitHub Copilot)"
    Write-Host "  2. Cursor"
    Write-Host "  3. Antigravity (Google)"
    Write-Host ""

    do {
        $input = Read-Host "請輸入選項 (1-3)"
        $ToolChoice = [int]$input
    } while ($ToolChoice -lt 1 -or $ToolChoice -gt 3)
}

# 根據工具設定目標路徑
$SkillsTarget = switch ($ToolChoice) {
    1 { Join-Path $ProjectPath ".github/skills" }
    2 { Join-Path $ProjectPath ".cursor/skills" }
    3 { Join-Path $ProjectPath ".agents/skills" }
}

$ConfigTarget = switch ($ToolChoice) {
    1 { Join-Path $ProjectPath ".github/copilot-instructions.md" }
    2 { Join-Path $ProjectPath ".cursorrules" }
    3 { Join-Path $ProjectPath ".agents/AGENTS.md" }
}

$ToolName = switch ($ToolChoice) {
    1 { "VS Code / Visual Studio (GitHub Copilot)" }
    2 { "Cursor" }
    3 { "Antigravity (Google)" }
}

Write-Host ""
Write-Host "正在安裝 .NET Skills 至 $ToolName..." -ForegroundColor Cyan
Write-Host ""

# 建立 Skills 目錄
New-Item -ItemType Directory -Path $SkillsTarget -Force | Out-Null

# 下載並複製 Skills
$TempDir = Join-Path $env:TEMP "dotnet-skills-$(Get-Random)"
Write-Host "  正在下載 Skills..." -ForegroundColor Yellow
git clone --quiet $RepoUrl $TempDir > $null 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "下載失敗，請確認 git 已安裝並可存取 GitHub。" -ForegroundColor Red
    exit 1
}

# 複製所有 Skills
$SourceSkills = Join-Path $TempDir "skills"
Copy-Item -Path "$SourceSkills\*" -Destination $SkillsTarget -Recurse -Force
Write-Host "  ✅ Skills 已安裝至：$SkillsTarget" -ForegroundColor Green

# 建立設定檔（AGENTS.md / copilot-instructions.md / .cursorrules）
$ConfigDir = Split-Path $ConfigTarget -Parent
New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null

$RouterContent = @"
# .NET Skills 路由設定

重要：處理所有 .NET / C# 任務時，優先參考 dotnet-skills。

## 路由規則

- 架構設計：clean-architecture-layers, dotnet-ddd-patterns
- 啟動設定：program-cs-extensions, dotnet-di-patterns, dotnet-options-pattern
- Controller 與 Minimal API 開發：controller-apis, minimal-apis, response-patterns
- 資料存取與效能：efcore-async-patterns, efcore-performance
- 錯誤處理：csharp-result-pattern, middleware
- 背景服務：dotnet-background-services
- 快取策略：dotnet-caching-patterns
- 驗證與 DTO 設計：fluent-validation-patterns
- API 文件與規格：openapi-best-practices
- 測試撰寫：dotnet-testing-practices
- 程式碼規範與日誌：csharp-coding-standards, csharp-primary-constructor, structured-logging
- DDD 建模：dotnet-ddd-patterns, clean-architecture-layers

## 使用方式

提示詞前加上 ``use dotnet skill,`` 確保 AI 參考技能包，例如：
- ``use dotnet skill, 建立一個 ProductController 包含 CRUD 操作``
- ``use dotnet skill, 建立符合 DDD 的 Order Aggregate``

## 程式碼規範（所有 .NET 任務都必須遵守）

- 所有欄位必須有一列式 ``<summary>`` XML 文件
- 所有方法必須有繁體中文說明與使用範例
- 使用明確型別宣告（禁止溺用 ``var``）
- 簡單方法使用 Expression-body (``=>``)
"@

# 若設定檔已存在，追加路由設定並指定 UTF8 編碼避免中文亂碼
if (Test-Path $ConfigTarget) {
    Add-Content -Path $ConfigTarget -Value "`n`n$RouterContent" -Encoding UTF8
    Write-Host "  ✅ 路由設定已追加至：$ConfigTarget" -ForegroundColor Green
}
else {
    Set-Content -Path $ConfigTarget -Value $RouterContent -Encoding UTF8
    Write-Host "  ✅ 設定檔已建立：$ConfigTarget" -ForegroundColor Green
}

# 清理暫存
Remove-Item -Path $TempDir -Recurse -Force

# 列出已安裝的 Skills
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
$installedCount = (Get-ChildItem -Path $SkillsTarget -Directory).Count
Write-Host "          已安裝的 Skills（共 $installedCount 個）" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Get-ChildItem -Path $SkillsTarget -Directory | ForEach-Object {
    Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "安裝完成！使用方式：" -ForegroundColor Cyan
Write-Host "  在提示詞前加上 'use dotnet skill,' 即可觸發對應技能" -ForegroundColor White
Write-Host "  例如：use dotnet skill, 建立一個 UserController" -ForegroundColor White
Write-Host ""

