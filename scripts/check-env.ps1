param(
    [string]$ProjectPath = "."
)

# .NET Skills 開發環境相容性檢測工具
# 用於驗證本機環境與專案設定是否符合技能包的需求

# 修正中文亂碼問題
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   .NET Skills 環境相容性檢測工具" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

$HasError = $false
$HasWarning = $false

# 1. 檢測 .NET SDK 版本
Write-Host "[1/3] 檢測本機 .NET SDK 安裝狀態..." -ForegroundColor White
$DotnetVer = $null
try {
    $DotnetVer = (dotnet --version 2>$null).Trim()
}
catch {}

if ([string]::IsNullOrEmpty($DotnetVer)) {
    Write-Host "❌ 找不到 dotnet CLI 命令。請確保已安裝 .NET SDK。" -ForegroundColor Red
    Write-Host "👉 下載網址: https://dotnet.microsoft.com/download" -ForegroundColor Yellow
    $HasError = $true
}
else {
    Write-Host "✅ 已偵測到 .NET SDK 版本: $DotnetVer" -ForegroundColor Green
    
    # 提取主要版本號
    if ($DotnetVer -match "^(\d+)\.") {
        $MajorVer = [int]$Matches[1]
        if ($MajorVer -lt 8) {
            Write-Host "⚠️  警告: 本機安裝的 .NET SDK 版本 ($DotnetVer) 低於 8.0。" -ForegroundColor Yellow
            Write-Host "   部分新語法 (如 Primary Constructors 或 IExceptionHandler) 可能無法正常編譯。" -ForegroundColor Yellow
            $HasWarning = $true
        }
    }
}
Write-Host ""

# 2. 檢測專案目標框架 (TargetFramework)
Write-Host "[2/3] 檢測專案目標框架 (TargetFramework)..." -ForegroundColor White
$CsprojFiles = Get-ChildItem -Path $ProjectPath -Filter "*.csproj" -Recurse -ErrorAction SilentlyContinue

if ($CsprojFiles.Count -eq 0) {
    Write-Host "ℹ️  在路徑 '$ProjectPath' 下未找到任何 C# 專案檔 (*.csproj)。" -ForegroundColor Cyan
    Write-Host "   這可能不是一個 .NET 專案目錄，將跳過專案內部設定檢測。" -ForegroundColor Cyan
}
else {
    Write-Host "📂 找到 $($CsprojFiles.Count) 個專案檔，開始掃描設定..." -ForegroundColor Gray
    
    foreach ($file in $CsprojFiles) {
        $CsprojContent = [xml](Get-Content -Path $file.FullName -ErrorAction SilentlyContinue)
        if ($null -eq $CsprojContent) {
            Write-Host "⚠️  無法解析專案檔: $($file.Name)" -ForegroundColor Yellow
            continue
        }
        
        $TargetFramework = $CsprojContent.Project.PropertyGroup.TargetFramework
        $LangVersion = $CsprojContent.Project.PropertyGroup.LangVersion
        
        Write-Host "📌 專案: $($file.Name)" -ForegroundColor Gray
        
        # 檢查 TargetFramework
        if ([string]::IsNullOrEmpty($TargetFramework)) {
            Write-Host "   ⚠️  未指定 TargetFramework 屬性。" -ForegroundColor Yellow
            $HasWarning = $true
        }
        else {
            Write-Host "   - 目標框架 (TargetFramework): $TargetFramework" -ForegroundColor Gray
            if ($TargetFramework -match "net([0-7])\.") {
                Write-Host "   ❌ 目標框架版本過低，建議升級至 .NET 8.0 或更高版本。" -ForegroundColor Red
                $HasError = $true
            }
            elseif ($TargetFramework -match "net([89]|10)\.") {
                Write-Host "   ✅ 目標框架符合要求 (.NET 8.0+)" -ForegroundColor Green
            }
        }
        
        # 檢查 LangVersion (C# 語言版本)
        if ($null -ne $LangVersion) {
            Write-Host "   - C# 語言版本 (LangVersion): $LangVersion" -ForegroundColor Gray
            if ($LangVersion -match "^(\d+)") {
                $LangNum = [int]$Matches[1]
                if ($LangNum -lt 12) {
                    Write-Host "   ❌ C# 語言版本為 C# $LangVersion，低於最低需求 C# 12。" -ForegroundColor Red
                    Write-Host "      請在專案檔中將 <LangVersion> 設定為 12 或以上，或設定為 latest。" -ForegroundColor Yellow
                    $HasError = $true
                }
            }
            elseif ($LangVersion -eq "latest" -or $LangVersion -eq "preview" -or $LangVersion -eq "default") {
                Write-Host "   ✅ C# 語言版本設定符合需求 ($LangVersion)" -ForegroundColor Green
            }
        }
        else {
            # 未明確指定 LangVersion，通常由 TargetFramework 決定
            if ($TargetFramework -match "net8\.0" -or $TargetFramework -match "net9\.0" -or $TargetFramework -match "net10\.0") {
                Write-Host "   ✅ C# 語言版本: (預設使用 C# 12+，符合需求)" -ForegroundColor Green
            }
            else {
                Write-Host "   ⚠️  未明確設定 C# 語言版本，且目標框架低於 .NET 8.0。可能不支援 C# 12 語法。" -ForegroundColor Yellow
                $HasWarning = $true
            }
        }
    }
}
Write-Host ""

# 3. 診斷總結
Write-Host "[3/3] 診斷總結" -ForegroundColor White
if ($HasError) {
    Write-Host "❌ 環境檢測失敗：您的開發環境或專案設定不符合部分技能包需求。" -ForegroundColor Red
    Write-Host "👉 建議修改後再使用 AI 技能包進行程式碼開發，以防編譯錯誤。" -ForegroundColor Yellow
    exit 1
}
elseif ($HasWarning) {
    Write-Host "⚠️  環境檢測完成：有部分警告，但基本可正常使用。" -ForegroundColor Yellow
    exit 0
}
else {
    Write-Host "🎉 環境檢測通過！您的環境與專案配置完美契合本技能包需求。" -ForegroundColor Green
    exit 0
}
