<#
.SYNOPSIS
Validate .skills files against project standards
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

# Color settings
$ColorSuccess = "Green"
$ColorError   = "Red"
$ColorWarning = "Yellow"
$ColorInfo    = "Cyan"

# Required YAML fields
$RequiredYamlFields = @("name", "description", "category", "tags", "version", "author", "created_at")

# Required content sections (Chinese keywords to match)
$RequiredSections = @("解決痛點", "Before", "After")

# File naming pattern (kebab-case)
$NamingPattern = "^[a-z0-9]+(-[a-z0-9]+)*\.md$"

function Write-Result {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
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
    Write-Result "Validating: $FilePath" "Info"
    Write-Host "----------------------------------------" -ForegroundColor $ColorInfo

    $HasError = $false

    # 1. Check file exists
    if (-not (Test-Path $FilePath)) {
        Write-Result "File not found!" "Error"
        return $true
    }

    # 2. Check file naming
    $FileName = Split-Path $FilePath -Leaf
    if ($FileName -notmatch $NamingPattern) {
        Write-Result "Invalid naming (use kebab-case): $FileName" "Error"
        $HasError = $true
    } else {
        Write-Result "File naming OK" "Success"
    }

    # 3. Read file content
    $Content = Get-Content $FilePath -Raw -Encoding UTF8

    # 4. Check YAML Front Matter
    if ($Content -match "^---[\r\n]+([\s\S]*?)[\r\n]+---") {
        Write-Result "YAML Front Matter found" "Success"
        $YamlContent = $Matches[1]

        foreach ($field in $RequiredYamlFields) {
            if ($YamlContent -match "^$field\s*:") {
                Write-Result "  [OK] Field exists: $field" "Success"
            } else {
                Write-Result "  [ERR] Missing field: $field" "Error"
                $HasError = $true
            }
        }
    } else {
        Write-Result "Missing YAML Front Matter (---)" "Error"
        $HasError = $true
    }

    # 5. Check required sections
    foreach ($section in $RequiredSections) {
        if ($Content -match $section) {
            Write-Result "  [OK] Section found: $section" "Success"
        } else {
            Write-Result "  [ERR] Missing section: $section" "Error"
            $HasError = $true
        }
    }

    # 6. Check code blocks
    if ($Content -match "```csharp") {
        Write-Result "  [OK] C# code block found" "Success"
    } else {
        Write-Result "  [WARN] No C# code block" "Warning"
    }

    return $HasError
}

# ========== Main Logic ==========
$HasGlobalError = $false

if (Test-Path $Path -PathType Container) {
    Write-Result "Scanning directory: $Path" "Info"
    $Files = Get-ChildItem -Path $Path -Filter *.md -Recurse
    
    if ($Files.Count -eq 0) {
        Write-Result "No .md files found" "Warning"
    }

    foreach ($File in $Files) {
        $ErrorFound = Test-SkillFile -FilePath $File.FullName
        if ($ErrorFound) { $HasGlobalError = $true }
    }
}
elseif (Test-Path $Path -PathType Leaf) {
    $ErrorFound = Test-SkillFile -FilePath $Path
    if ($ErrorFound) { $HasGlobalError = $true }
}
else {
    Write-Result "Invalid path: $Path" "Error"
    exit 1
}

# Final result
Write-Host "`n========================================" -ForegroundColor $ColorInfo
if ($HasGlobalError) {
    Write-Result "VALIDATION FAILED: Please fix errors before commit" "Error"
    exit 1
} else {
    Write-Result "VALIDATION PASSED: All checks OK!" "Success"
    exit 0
}