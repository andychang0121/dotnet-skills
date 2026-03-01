# dotnet-skills 驗證腳本
# 驗證所有 Skill 結構完整性
# 使用方式：.\scripts\validate-skills.ps1

param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent)
)

$SkillsDir = Join-Path $RepoRoot "skills"
$PluginJson = Join-Path $RepoRoot ".claude-plugin/plugin.json"

$ErrorCount = 0

Write-Host ""
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "  .NET Skills 結構驗證" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# 讀取 plugin.json
$plugin = Get-Content $PluginJson | ConvertFrom-Json
$registeredSkills = $plugin.skills | ForEach-Object { Split-Path $_ -Leaf }

# 驗證每個 Skill 資料夾都有 SKILL.md
Write-Host "[1/3] 驗證 SKILL.md 存在性..." -ForegroundColor Yellow
$skillDirs = Get-ChildItem -Path $SkillsDir -Directory
foreach ($dir in $skillDirs) {
    $skillMd = Join-Path $dir.FullName "SKILL.md"
    if (-not (Test-Path $skillMd)) {
        Write-Host "  ❌ 缺少 SKILL.md：$($dir.Name)" -ForegroundColor Red
        $ErrorCount++
    }
    else {
        Write-Host "  ✅ $($dir.Name)" -ForegroundColor Green
    }
}

# 驗證 SKILL.md 包含 YAML frontmatter
Write-Host ""
Write-Host "[2/3] 驗證 YAML frontmatter..." -ForegroundColor Yellow
foreach ($dir in $skillDirs) {
    $skillMd = Join-Path $dir.FullName "SKILL.md"
    if (Test-Path $skillMd) {
        $content = Get-Content $skillMd -Raw
        if (-not $content.StartsWith("---")) {
            Write-Host "  ❌ 缺少 YAML frontmatter：$($dir.Name)" -ForegroundColor Red
            $ErrorCount++
        }
        elseif (-not ($content -match "name:") -or -not ($content -match "description:")) {
            Write-Host "  ❌ frontmatter 缺少 name 或 description：$($dir.Name)" -ForegroundColor Red
            $ErrorCount++
        }
        else {
            Write-Host "  ✅ $($dir.Name)" -ForegroundColor Green
        }
    }
}

# 驗證所有 Skills 都在 plugin.json 中登記
Write-Host ""
Write-Host "[3/3] 驗證 plugin.json 登記..." -ForegroundColor Yellow
foreach ($dir in $skillDirs) {
    if ($registeredSkills -contains $dir.Name) {
        Write-Host "  ✅ $($dir.Name)" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ 未在 plugin.json 登記：$($dir.Name)" -ForegroundColor Red
        $ErrorCount++
    }
}

# 結果
Write-Host ""
Write-Host "==============================" -ForegroundColor Cyan
if ($ErrorCount -eq 0) {
    Write-Host "  ✅ 驗證通過（0 個錯誤）" -ForegroundColor Green
}
else {
    Write-Host "  ❌ 驗證失敗（$ErrorCount 個錯誤）" -ForegroundColor Red
    exit 1
}
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""
