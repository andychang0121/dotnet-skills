# .NET Skills Repo 建立任務清單

## 階段一：規劃與設計

- [x] 研究 vuejs-ai/skills 架構
- [x] 研究 Aaronontheweb/dotnet-skills 架構
- [x] 審視 ProfitAsset Hub 專案取得素材
- [x] 整合兩個參考 Repo 的最佳設計
- [x] 討論並確認 Skill 清單（13 個）、README 詳細使用範例格式
- [x] 取得 Andy 最終確認

## 階段二：Repo 建立

- [x] 初始化 Git Repo（D:\Project\dotnet-skills）
- [x] 建立 .gitignore、LICENSE（MIT）
- [x] 建立 .claude-plugin/plugin.json + marketplace.json
- [x] 建立 AGENTS.md（開發指南）
- [x] 建立 README.md（含詳細 Before/After 使用範例）
- [x] 建立 CHANGELOG.md（0.1.0）

## 階段三：Skills 撰寫（共 13 個）

- [x] `clean-architecture-layers` - 分層架構原則
- [x] `csharp-primary-constructor` - Primary Constructor 現代寫法
- [x] `aspnetcore-controller-best-practices` - Controller 最佳實踐
- [x] `aspnetcore-program-cs-extensions` - Program.cs Extension Method 整理
- [x] `aspnetcore-response-patterns` - API 回應模式
- [x] `efcore-async-patterns` - EF Core 非同步查詢
- [x] `dotnet-di-patterns` - DI 生命週期與 Keyed Services
- [x] `csharp-result-pattern` - Result<T> 模式
- [x] `dotnet-options-pattern` - IOptions<T>/IOptionsMonitor/IOptionsSnapshot
- [x] `dotnet-background-services` - BackgroundService / CancellationToken
- [x] `aspnetcore-middleware` - 自定義 Middleware / RFC 9457 全域例外處理
- [x] `csharp-coding-standards` - 明確型別、Expression-body、命名規範、程式碼風格
- [x] `dotnet-ddd-patterns` - DDD 核心概念（Entity / Value Object / Aggregate / Domain Service / Repository）

## 階段四：Agents 撰寫（1 個）

- [x] `dotnet-api-specialist.md` - REST API 設計專家人格

## 階段五：Scripts 建立

- [x] `scripts/install.ps1` - 一鍵安裝（互動式選單：VS Code / Cursor / Antigravity）
- [x] `scripts/validate-skills.ps1` - 驗證結構完整性
- [x] `scripts/generate-index.ps1` - 自動更新 README Skill 清單

## 階段六：Evals 建立（4 套 × 3 Scenario）

- [x] `async-efcore-query`（efcore-async-patterns）
- [x] `primary-constructor`（csharp-primary-constructor）
- [x] `controller-response`（aspnetcore-controller-best-practices）
- [x] **分支**：`master`（穩定發布）、`dev`（開發用）dotnet-di-patterns）

## 階段七：4. GitHub Actions 自動建立 Release 並同步至 `master`lidate-skills.yml`（PR 自動驗證）
- [x] `sync-to-master.yml`（手動同步至 master）
- [x] `release.yml`（semver tag 觸發建立 Release）

## 階段八：最終驗證

- [x] 執行 validate-skills.ps1 確認結構正確
- [x] 確認 plugin.json 中所有路徑存在
- [x] 確認 README 安裝流程正確
