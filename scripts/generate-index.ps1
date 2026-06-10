# dotnet-skills README Skill 清單自動更新腳本
# 掃描所有 SKILL.md 並更新 README.md 的 Skill 清單表格
# 使用方式：.\scripts\generate-index.ps1

param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent)
)

$SkillsDir = Join-Path $RepoRoot "skills"
$ReadmePath = Join-Path $RepoRoot "README.md"

Write-Host "掃描 Skills..." -ForegroundColor Cyan

$skills = @()
foreach ($dir in Get-ChildItem -Path $SkillsDir -Directory | Sort-Object Name) {
    $skillMd = Join-Path $dir.FullName "SKILL.md"
    if (-not (Test-Path $skillMd)) { continue }

    $content = Get-Content $skillMd -Raw -Encoding UTF8
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

# 組合最新的 Markdown 表格
$TableLines = @()
$TableLines += "<!-- SKILLS_LIST_START -->"
$TableLines += "| Skill | 說明 |"
$TableLines += "|-------|------|"
foreach ($skill in $skills) {
    $TableLines += "| ``$($skill.Directory)`` | $($skill.Description) |"
}
$TableLines += "<!-- SKILLS_LIST_END -->"
$NewTableContent = $TableLines -join "`r`n"

# 自動更新 README.md
if (Test-Path $ReadmePath) {
    Write-Host "正在更新 README.md..." -ForegroundColor Cyan
    $ReadmeContent = Get-Content $ReadmePath -Raw -Encoding UTF8
    
    $StartMarker = "<!-- SKILLS_LIST_START -->"
    $EndMarker = "<!-- SKILLS_LIST_END -->"
    
    if ($ReadmeContent.Contains($StartMarker) -and $ReadmeContent.Contains($EndMarker)) {
        # 使用正則表達式替換標記之間的內容
        $Pattern = "(?s)" + [regex]::Escape($StartMarker) + ".*?" + [regex]::Escape($EndMarker)
        $UpdatedReadmeContent = [regex]::Replace($ReadmeContent, $Pattern, $NewTableContent)
        
        # 以 UTF-8 with BOM 寫回檔案以避免亂碼並與專案編碼一致
        $UpdatedReadmeContent | Out-File -FilePath $ReadmePath -Encoding UTF8
        Write-Host "  🎉 README.md 更新成功！" -ForegroundColor Green
    } else {
        Write-Host "  ❌ 找不到標記！請確認 README.md 中有 $StartMarker 與 $EndMarker" -ForegroundColor Red
    }
} else {
    Write-Host "  ❌ 找不到 README.md 檔案：$ReadmePath" -ForegroundColor Red
}

