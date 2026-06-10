<#
.SYNOPSIS
驗證 C# Skills 結構是否符合專案標準
#>

param(
    [string]$Path = "$PSScriptRoot\..\skills",
    [string]$LogPath = ""
)

# 顏色設定
$ColorSuccess = "Green"
$ColorError   = "Red"
$ColorWarning = "Yellow"
$ColorInfo    = "Cyan"

# 必要的 YAML Frontmatter 欄位
$RequiredYamlFields = @("name", "description")

# 必要的 Markdown 標題區段
$RequiredSections = @("使用時機", "最佳實踐摘要")

# 檔案命名規則 (必須為 kebab-case，例如: clean-architecture-layers.md)
$NamingPattern = "^[a-z0-9]+(-[a-z0-9]+)*\.md$"

# 初始化日誌內容
$LogContent = @()
$LogContent += "========================================"
$LogContent += "Skills 結構驗證報告"
$LogContent += "日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$LogContent += "目標路徑: $Path"
$LogContent += "========================================"
$LogContent += ""

function Write-Log {
    param([string]$Message)
    if ($LogPath) {
        $script:LogContent += $Message
    }
}

function Write-Result {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    Write-Log "[$Level] $Message"
    switch ($Level) {
        "Success" { Write-Host "[OK] $Message" -ForegroundColor $ColorSuccess }
        "Error"   { Write-Host "[ERR] $Message" -ForegroundColor $ColorError }
        "Warning" { Write-Host "[WARN] $Message" -ForegroundColor $ColorWarning }
        "Info"    { Write-Host "[INFO] $Message" -ForegroundColor $ColorInfo }
    }
}

function Test-SkillFile {
    param([string]$FilePath)

    Write-Host "`n----------------------------------------" -ForegroundColor $ColorInfo
    Write-Result "開始驗證: $FilePath" "Info"
    Write-Host "----------------------------------------" -ForegroundColor $ColorInfo

    $HasError = $false
    $FileLog = @()
    $FileLog += "檔案: $FilePath"

    # 1. 檢查檔案是否存在
    if (-not (Test-Path $FilePath)) {
        Write-Result "找不到檔案！" "Error"
        $FileLog += "  [ERR] 找不到檔案！"
        $script:LogContent += $FileLog
        return $true
    }

    # 2. 檢查檔案命名格式是否符合 kebab-case（若非 SKILL.md）
    $FileName = Split-Path $FilePath -Leaf
    if ($FileName -ne "SKILL.md" -and $FileName -notmatch $NamingPattern) {
        Write-Result "檔案命名格式錯誤（必須使用 kebab-case，如 some-skill.md）：$FileName" "Error"
        $FileLog += "  [ERR] 檔案命名格式錯誤：$FileName"
        $HasError = $true
    } else {
        Write-Result "檔案命名格式正確 ($FileName)" "Success"
        $FileLog += "  [OK] 檔案命名格式正確 ($FileName)"
    }

    # 3. 讀取 UTF-8 檔案內容
    $Content = Get-Content $FilePath -Raw -Encoding UTF8

    # 4. 檢查 YAML Front Matter
    if ($Content -match "^---[\r\n]+([\s\S]*?)[\r\n]+---") {
        Write-Result "找到 YAML Front Matter" "Success"
        $FileLog += "  [OK] 找到 YAML Front Matter"
        $YamlContent = $Matches[1]

        # 驗證必要欄位
        foreach ($field in $RequiredYamlFields) {
            if ($YamlContent -match "(?m)^$field\s*:") {
                Write-Result "  [OK] 欄位存在: $field" "Success"
                $FileLog += "    [OK] 欄位存在: $field"
            } else {
                Write-Result "  [ERR] 遺漏欄位: $field" "Error"
                $FileLog += "    [ERR] 遺漏欄位: $field"
                $HasError = $true
            }
        }

        # 驗證 invocable 欄位格式（若存在，必須為 true 或 false）
        if ($YamlContent -match "(?m)^invocable\s*:\s*(.+)$") {
            $Value = $Matches[1].Trim()
            if ($Value -eq "true" -or $Value -eq "false") {
                Write-Result "  [OK] invocable 格式正確 ($Value)" "Success"
                $FileLog += "    [OK] invocable 格式正確 ($Value)"
            } else {
                Write-Result "  [ERR] invocable 必須為 true 或 false，目前為: $Value" "Error"
                $FileLog += "    [ERR] invocable 格式錯誤: $Value"
                $HasError = $true
            }
        }
    } else {
        Write-Result "遺漏 YAML Front Matter (---)" "Error"
        $FileLog += "  [ERR] 遺漏 YAML Front Matter"
        $HasError = $true
    }

    # 5. 檢查必要的 Markdown 區段
    foreach ($section in $RequiredSections) {
        # 匹配 ## 區段名稱，允許前後有空格或中文括號的英文翻譯
        if ($Content -match "(?m)^##\s*$section") {
            Write-Result "  [OK] 找到必要區段: $section" "Success"
            $FileLog += "    [OK] 找到必要區段: $section"
        } else {
            Write-Result "  [ERR] 遺漏必要區段: $section" "Error"
            $FileLog += "    [ERR] 遺漏必要區段: $section"
            $HasError = $true
        }
    }

    # 5.1 檢查是否有包含 ✅ 與 ❌ 範例
    if ($Content -match "✅" -and $Content -match "❌") {
        Write-Result "  [OK] 找到正確範例 (✅) 與錯誤反例 (❌)" "Success"
        $FileLog += "    [OK] 找到正確範例 (✅) 與錯誤反例 (❌)"
    } else {
        Write-Result "  [ERR] 必須包含至少一個正確範例 (✅) 與錯誤反例 (❌)" "Error"
        $FileLog += "    [ERR] 必須包含至少一個正確範例 (✅) 與錯誤反例 (❌)"
        $HasError = $true
    }

    # 6. 檢查 C# 程式碼區塊
    if ($Content -match "```csharp") {
        Write-Result "  [OK] 找到 C# 程式碼區塊" "Success"
        $FileLog += "  [OK] 找到 C# 程式碼區塊"
    } else {
        Write-Result "  [WARN] 未找到 C# 程式碼區塊" "Warning"
        $FileLog += "  [WARN] 未找到 C# 程式碼區塊"
    }

    $script:LogContent += $FileLog
    $script:LogContent += ""
    return $HasError
}

# ========== 主要執行邏輯 ==========
$HasGlobalError = $false
$TotalFiles = 0
$PassCount = 0
$FailCount = 0

Write-Result "開始掃描路徑: $Path" "Info"

if (Test-Path $Path -PathType Container) {
    # 尋找所有目錄下的 SKILL.md 檔案
    $Files = Get-ChildItem -Path $Path -Filter SKILL.md -Recurse
    
    if ($Files.Count -eq 0) {
        Write-Result "在 $Path 下找不到任何 SKILL.md 檔案" "Warning"
    }

    foreach ($File in $Files) {
        $TotalFiles++
        $ErrorFound = Test-SkillFile -FilePath $File.FullName
        if ($ErrorFound) {
            $FailCount++
            $HasGlobalError = $true
        } else {
            $PassCount++
        }
    }
}
elseif (Test-Path $Path -PathType Leaf) {
    $TotalFiles = 1
    $ErrorFound = Test-SkillFile -FilePath $Path
    if ($ErrorFound) {
        $FailCount++
        $HasGlobalError = $true
    } else {
        $PassCount++
    }
}
else {
    Write-Result "無效的路徑: $Path" "Error"
    exit 1
}

# 統計摘要
Write-Host ""
Write-Host "========================================" -ForegroundColor $ColorInfo
$SummaryMsg = "驗證統計: 總共 $TotalFiles 個檔案，通過: $PassCount，失敗: $FailCount"
$LogContent += "========================================"
$LogContent += "驗證摘要"
$LogContent += "========================================"
$LogContent += "總檔案數: $TotalFiles"
$LogContent += "通過數: $PassCount"
$LogContent += "失敗數: $FailCount"

if ($HasGlobalError) {
    Write-Result "驗證失敗！有部分檔案未符合規範 ($FailCount/$TotalFiles)" "Error"
    $LogContent += "結果: 失敗"
} else {
    Write-Result "驗證通過！所有檔案皆符合規範 ($TotalFiles/$TotalFiles)" "Success"
    $LogContent += "結果: 通過"
}
$LogContent += "========================================"

# 輸出日誌檔案
if ($LogPath) {
    $LogDir = Split-Path $LogPath -Parent
    if ($LogDir -and -not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    $LogContent | Out-File -FilePath $LogPath -Encoding UTF8
    Write-Host "`n日誌已儲存至: $LogPath" -ForegroundColor $ColorInfo
}

if ($HasGlobalError) {
    exit 1
} else {
    exit 0
}

