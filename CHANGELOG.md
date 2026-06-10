# 變更日誌

本文件紀錄所有重要的版本變更，格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.0.0/)，版本號遵循 [Semantic Versioning](https://semver.org/)。

## [0.2.0] - 2026-06-10

### 新增

- `scripts/uninstall.ps1`：新增一鍵解除安裝腳本，支援自動偵測安裝的開發工具並完整清理設定與資料夾，且針對 Windows PowerShell 5.1 進行了編碼與指令相容性優化
- 5 個核心 Skills 技能包：
  - `dotnet-testing-practices`：單元與整合測試最佳實踐 (xUnit, NSubstitute, FluentAssertions)
  - `fluent-validation-patterns`：Request 驗證最佳實踐 (FluentValidation, ProblemDetails 整合)
  - `dotnet-caching-patterns`：快取策略與控制最佳實踐 (MemoryCache, Redis, HybridCache)
  - `efcore-performance`：EF Core 效能調優與批次操作 (AsNoTracking, split queries)
  - `openapi-best-practices`：API 文件與 OpenAPI/Swagger 最佳實踐 (XML 註解, ProducesResponseType)
- 技能繁體中文簡介欄位 `description_zh`：允許在 `README.md` 的技能清單中以繁體中文直觀呈現，並升級 `generate-index.ps1` 進行同步支援
- 本地 Git Hook：新增 `scripts/setup-git-hooks.ps1` 用以一鍵配置 pre-commit hook，在 commit 前自動驗證與更新索引
- 雲端 CI：新增 `.github/workflows/validate.yml` 用以在 Push 與 PR 時於 GitHub Actions 執行技能完整性自動化驗證

### 變更

- 安裝與卸載指令碼中的「VS Code (GitHub Copilot)」擴充標註為「VS Code / Visual Studio (GitHub Copilot)」，提供更完整的 .NET 生態系支援說明
- `README.md` 新增 `⚡ 快速開始` 區段，提供最簡化的單行安裝與解除安裝線上執行指令

## [0.1.0] - 2026-03-01

### 新增

- `clean-architecture-layers`：Clean Architecture 分層原則 Skill
- `csharp-primary-constructor`：C# 12 Primary Constructor 現代寫法 Skill
- `aspnetcore-controller-best-practices`：ASP.NET Core Controller 最佳實踐 Skill
- `aspnetcore-program-cs-extensions`：Program.cs Extension Method 整理 Skill
- `aspnetcore-response-patterns`：API 回應模式 Skill
- `efcore-async-patterns`：EF Core 非同步查詢模式 Skill
- `dotnet-di-patterns`：DI 生命週期與 Keyed Services Skill
- `csharp-result-pattern`：Result\<T\> 業務錯誤處理 Skill
- `dotnet-options-pattern`：IOptions\<T\> 設定注入 Skill
- `dotnet-background-services`：BackgroundService 背景服務 Skill
- `aspnetcore-middleware`：自定義 Middleware 與 RFC 9457 例外處理 Skill
- `csharp-coding-standards`：C# 程式碼規範 Skill（繁體中文註解、XML summary、明確型別）
- `dotnet-ddd-patterns`：DDD 領域驅動設計模式 Skill
- `dotnet-api-specialist`：REST API 設計專家 Agent
- `scripts/install.ps1`：互動式安裝腳本（支援 VS Code、Cursor、Antigravity）
- `scripts/validate-skills.ps1`：Skill 結構驗證腳本
- `scripts/generate-index.ps1`：README Skill 清單自動產生腳本
- Evals 評估框架（4 套 × 3 Scenario）
- GitHub Actions 自動化工作流程

[未發布]: https://github.com/andychang0121/dotnet-skills/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/andychang0121/dotnet-skills/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/andychang0121/dotnet-skills/releases/tag/v0.1.0
