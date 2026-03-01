<#
.SYNOPSIS
Validate .skills files against project standards
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [string]$LogPath = "./tools/validation-log.txt"
)

# Color settings
$ColorSuccess = "Green"
$ColorError = "Red"
$ColorWarning = "Yellow"
$ColorInfo = "Cyan"

# Required YAML fields
$RequiredYamlFields = @("name", "description", "category", "tags", "version", "author", "created_at")

# Required content sections
$RequiredSections = @("解決痛點", "Before", "After")

# File naming pattern
$NamingPattern = "^[a-z0-9]+(-[a-z0-9]+)*\.md$"

# Initialize log
$LogContent = @()
$LogContent += "========================================"
$LogContent += "Validation Report"
$LogContent += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$LogContent += "Target: $Path"
$LogContent += "========================================"
$LogContent += ""

function Write-Log {
    param([string]$Message)
    $LogContent += $Message
}

function Write-Result {
    param([string]$Message, [string]$Level = "Info")
    Write-Log "[$Level] $Message"
    switch ($Level) {
        "Success" { Write-Host "[OK] $Message" -ForegroundColor $ColorSuccess }
        "Error" { Write-Host "[ERR] $Message" -ForegroundColor $ColorError }
        "Warning" { Write-Host "[WARN] $Message" -ForegroundColor $ColorWarning }
        "Info" { Write-Host "[INFO] $Message" -ForegroundColor $ColorInfo }
    }
}

function Test-SkillFile {
    param([string]$FilePath)
    
    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor $ColorInfo
    Write-Result "Validating: $FilePath" "Info"
    Write-Host "----------------------------------------" -ForegroundColor $ColorInfo
    
    $HasError = $false
    $FileLog = @()
    $FileLog += "FILE: $FilePath"
    
    # 1. Check file exists
    if (-not (Test-Path $FilePath)) {
        Write-Result "File not found!" "Error"
        $FileLog += "  [ERR] File not found!"
        $LogContent += $FileLog
        return $true
    }
    
    # 2. Check file naming
    $FileName = Split-Path $FilePath -Leaf
    if ($FileName -notmatch $NamingPattern) {
        Write-Result "Invalid naming: $FileName" "Error"
        $FileLog += "  [ERR] Invalid naming: $FileName"
        $HasError = $true
    } else {
        Write-Result "File naming OK" "Success"
        $FileLog += "  [OK] File naming OK"
    }
    
    # 3. Read content
    $Content = Get-Content $FilePath -Raw -Encoding UTF8
    
    # 4. Check YAML Front Matter
    if ($Content -match "^---[\r\n]+([\s\S]*?)[\r\n]+---") {
        Write-Result "YAML Front Matter found" "Success"
        $FileLog += "  [OK] YAML Front Matter found"
        $YamlContent = $Matches[1]
        
        foreach ($field in $RequiredYamlFields) {
            if ($YamlContent -match "^$field\s*:") {
                Write-Result "  Field: $field" "Success"
                $FileLog += "    [OK] $field"
            } else {
                Write-Result "  Missing: $field" "Error"
                $FileLog += "    [ERR] $field"
                $HasError = $true
            }
        }
    } else {
        Write-Result "Missing YAML Front Matter" "Error"
        $FileLog += "  [ERR] Missing YAML Front Matter"
        $HasError = $true
    }
    
    # 5. Check sections
    foreach ($section in $RequiredSections) {
        if ($Content -match $section) {
            Write-Result "  Section: $section" "Success"
            $FileLog += "    [OK] Section: $section"
        } else {
            Write-Result "  Missing: $section" "Error"
            $FileLog += "    [ERR] Section: $section"
            $HasError = $true
        }
    }
    
    # 6. Check code blocks
    if ($Content -match "```csharp") {
        Write-Result "C# code block found" "Success"
        $FileLog += "  [OK] C# code block found"
    } else {
        Write-Result "No C# code block" "Warning"
        $FileLog += "  [WARN] No C# code block"
    }
    
    $LogContent += $FileLog
    $LogContent += ""
    return $HasError
}

# ========== Main Logic ==========
$HasGlobalError = $false
$TotalFiles = 0
$PassCount = 0
$FailCount = 0

if (Test-Path $Path -PathType Container) {
    Write-Result "Scanning: $Path" "Info"
    $Files = Get-ChildItem -Path $Path -Filter *.md -Recurse
    
    if ($Files.Count -eq 0) {
        Write-Result "No .md files found" "Warning"
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
} elseif (Test-Path $Path -PathType Leaf) {
    $TotalFiles = 1
    $ErrorFound = Test-SkillFile -FilePath $Path
    if ($ErrorFound) { $FailCount++; $HasGlobalError = $true } else { $PassCount++ }
} else {
    Write-Result "Invalid path: $Path" "Error"
    exit 1
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor $ColorInfo
$LogContent += "========================================"
$LogContent += "SUMMARY"
$LogContent += "========================================"
$LogContent += "Total Files: $TotalFiles"
$LogContent += "Passed: $PassCount"
$LogContent += "Failed: $FailCount"

if ($HasGlobalError) {
    Write-Result "VALIDATION FAILED ($FailCount/$TotalFiles)" "Error"
    $LogContent += "RESULT: FAILED"
} else {
    Write-Result "VALIDATION PASSED ($TotalFiles/$TotalFiles)" "Success"
    $LogContent += "RESULT: PASSED"
}

$LogContent += "========================================"

# Save log
$LogContent | Out-File -FilePath $LogPath -Encoding UTF8
Write-Host ""
Write-Host "Log saved to: $LogPath" -ForegroundColor $ColorInfo

if ($HasGlobalError) { exit 1 } else { exit 0 }