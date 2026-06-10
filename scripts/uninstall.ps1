# dotnet-skills 解除安裝腳本
# 使用方式：在你的專案目錄執行此腳本
# .\scripts\uninstall.ps1

param(
    [string]$ProjectPath = "",  # 專案路徑（空白則互動詢問）
    [int]$ToolChoice = 0,       # AI 工具選擇（0 則互動詢問）
    [switch]$Force              # 是否強制執行（跳過確認提示）
)

# 避免環境設定了 $ErrorActionPreference = "Stop" 導致命令失敗
$ErrorActionPreference = "Continue"

# 修正中文亂碼問題
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 標題與歡迎訊息
Write-Host ""
Write-Host "==============================================" -ForegroundColor Red
Write-Host "      .NET Skills 解除安裝程式 v0.1.0" -ForegroundColor Red
Write-Host "==============================================" -ForegroundColor Red
Write-Host ""
Write-Host "本程式將引導您從專案中移除所有的 .NET Skills 技能包與 AI 路由設定。" -ForegroundColor White
Write-Host ""

# 確認是否繼續解除安裝
if (-not $Force) {
    Write-Host "是否確定要解除安裝並移除相關檔案？[Y/N]" -ForegroundColor Yellow
    $Confirm = Read-Host "> "
    if ($Confirm -notmatch "^[yY](es)?$") {
        Write-Host ""
        Write-Host "⚠️ 解除安裝已被取消。未進行任何變更。" -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }
}

Write-Host ""
Write-Host "----------------------------------------------" -ForegroundColor Red
Write-Host "開始進行解除安裝設定..." -ForegroundColor Red
Write-Host "----------------------------------------------" -ForegroundColor Red
Write-Host ""

# 詢問專案路徑
if ($ProjectPath -eq "") {
    Write-Host "請輸入您的專案資料夾路徑（直接按 Enter 為目前目錄 '$((Get-Location).Path)'）:" -ForegroundColor Yellow
    $inputPath = Read-Host "> "
    $ProjectPath = if (([string]::IsNullOrWhiteSpace($inputPath))) { (Get-Location).Path } else { $inputPath }
}

# 驗證路徑
if (-not (Test-Path $ProjectPath)) {
    Write-Host "❌ 錯誤：指定的路徑不存在：$ProjectPath" -ForegroundColor Red
    exit 1
}

$ProjectPath = (Resolve-Path $ProjectPath).Path
Write-Host ""
Write-Host "  專案路徑：$ProjectPath" -ForegroundColor Green
Write-Host ""

# 定義獲取工具路徑與名稱的輔助函式
function Get-ToolPaths($choice, $path) {
    $skills = switch ($choice) {
        1 { Join-Path $path ".github/skills" }
        2 { Join-Path $path ".cursor/skills" }
        3 { Join-Path $path ".agents/skills" }
    }
    $config = switch ($choice) {
        1 { Join-Path $path ".github/copilot-instructions.md" }
        2 { Join-Path $path ".cursorrules" }
        3 { Join-Path $path ".agents/AGENTS.md" }
    }
    $name = switch ($choice) {
        1 { "VS Code (GitHub Copilot)" }
        2 { "Cursor" }
        3 { "Antigravity (Google)" }
    }
    return [PSCustomObject]@{
        Choice = $choice
        SkillsTarget = $skills
        ConfigTarget = $config
        ToolName = $name
    }
}

# 偵測已安裝的 AI 開發工具
$ToolsToUninstall = @()

if ($ToolChoice -ne 0) {
    $ToolsToUninstall += Get-ToolPaths -choice $ToolChoice -path $ProjectPath
} else {
    # 自動掃描所有可能的工具安裝痕跡
    for ($i = 1; $i -le 3; $i++) {
        $info = Get-ToolPaths -choice $i -path $ProjectPath
        $hasSkills = Test-Path $info.SkillsTarget
        $hasConfig = $false
        if (Test-Path $info.ConfigTarget) {
            try {
                $content = [System.IO.File]::ReadAllText($info.ConfigTarget, [System.Text.Encoding]::UTF8)
                if ($content -match "# \.NET Skills 路由設定") {
                    $hasConfig = $true
                }
            } catch {}
        }
        if ($hasSkills -or $hasConfig) {
            $ToolsToUninstall += $info
        }
    }
}

if ($ToolsToUninstall.Count -eq 0) {
    Write-Host "ℹ️ 偵測到本專案中沒有任何已安裝的 .NET Skills 技能包與設定。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Red
    Write-Host "           解除安裝已結束" -ForegroundColor Red
    Write-Host "==============================================" -ForegroundColor Red
    Write-Host ""
    exit 0
}

Write-Host "偵測到以下已安裝的 AI 開發工具設定：" -ForegroundColor Cyan
foreach ($tool in $ToolsToUninstall) {
    Write-Host "  - $($tool.ToolName)" -ForegroundColor White
}
Write-Host ""

# 執行解除安裝循環
foreach ($Tool in $ToolsToUninstall) {
    $SkillsTarget = $Tool.SkillsTarget
    $ConfigTarget = $Tool.ConfigTarget
    $ToolName = $Tool.ToolName

    Write-Host "正在為 $ToolName 執行解除安裝..." -ForegroundColor Red
    Write-Host ""

    # 1. 刪除 Skills 目錄
    if (Test-Path $SkillsTarget) {
        try {
            Remove-Item -Path $SkillsTarget -Recurse -Force
            Write-Host "  ✅ 已成功移除 Skills 目錄：$SkillsTarget" -ForegroundColor Green
        }
        catch {
            Write-Host "  ❌ 移除 Skills 目錄失敗，請檢查權限或檔案佔用狀態。" -ForegroundColor Red
        }
    } else {
        Write-Host "  ℹ️ 找不到 Skills 目錄，跳過此步驟。" -ForegroundColor Yellow
    }

    # 2. 復原或刪除設定檔
    if (Test-Path $ConfigTarget) {
        try {
            $Content = [System.IO.File]::ReadAllText($ConfigTarget, [System.Text.Encoding]::UTF8)
            # 尋找路由設定段落（包含前置換行）
            $Pattern = "(?s)\r?\n?\r?\n?# \.NET Skills 路由設定.*"
            
            if ($Content -match "# \.NET Skills 路由設定") {
                # 移除路由設定部分
                $RestoredContent = [regex]::Replace($Content, $Pattern, "")
                
                if ([string]::IsNullOrWhiteSpace($RestoredContent)) {
                    # 如果還原後檔案內容為空，則直接刪除設定檔
                    Remove-Item -Path $ConfigTarget -Force
                    Write-Host "  ✅ 設定檔已成功刪除（回復至安裝前不存在的狀態）：$ConfigTarget" -ForegroundColor Green
                } else {
                    # 否則寫回檔案，保留使用者的其他自訂設定
                    [System.IO.File]::WriteAllText($ConfigTarget, $RestoredContent.Trim(), [System.Text.Encoding]::UTF8)
                    Write-Host "  ✅ 設定檔已成功復原（保留了您的其他自訂設定）：$ConfigTarget" -ForegroundColor Green
                }
            } else {
                Write-Host "  ℹ️ 設定檔中未包含本技能包的路由設定，未做變更。" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  ❌ 處理設定檔復原時發生錯誤：$($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  ℹ️ 找不到設定檔，跳過此步驟。" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Red
Write-Host "           解除安裝完成！" -ForegroundColor Red
Write-Host "==============================================" -ForegroundColor Red
Write-Host ""

