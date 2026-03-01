# dotnet-skills README Skill 清單自動更新腳本
# 掃描所有 SKILL.md 並更新 README.md 的 Skill 清單表格
# 使用方式：.\scripts\generate-index.ps1

param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent)
)

$SkillsDir = Join-Path $RepoRoot "skills"

Write-Host "掃描 Skills..." -ForegroundColor Cyan

$skills = @()
foreach ($dir in Get-ChildItem -Path $SkillsDir -Directory | Sort-Object Name) {
    $skillMd = Join-Path $dir.FullName "SKILL.md"
    if (-not (Test-Path $skillMd)) { continue }

    $content = Get-Content $skillMd -Raw
    $nameMatch = [regex]::Match($content, "(?m)^name:\s*(.+)$")
    $descMatch = [regex]::Match($content, "(?m)^description:\s*(.+)$")

    if ($nameMatch.Success -and $descMatch.Success) {
        $skills += [PSCustomObject]@{
            Directory   = $dir.Name
            Name        = $nameMatch.Groups[1].Value.Trim()
            Description = $descMatch.Groups[1].Value.Trim()
        }
        Write-Host "  ✅ $($dir.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "共掃描 $($skills.Count) 個 Skills" -ForegroundColor Cyan
Write-Host ""

# 顯示結果（可手動更新 README）
Write-Host "Skill 清單（複製至 README.md）：" -ForegroundColor Yellow
Write-Host ""
Write-Host "| Skill | 說明 |"
Write-Host "|-------|------|"
foreach ($skill in $skills) {
    Write-Host "| ``$($skill.Directory)`` | $($skill.Description) |"
}
