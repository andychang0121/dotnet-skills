# .NET 8/10 RESTful API Skills Repo 建立計畫（最終版）

本計畫整合兩個參考 Repo 的最佳設計，建立一套 .NET 8/10 RESTful API (MVC Controller) 技能包。

**設計選擇：**

| 項目 | 選擇 | 原因 |
|------|------|------|
| SKILL.md 格式 | 詳盡（10-40KB） | AI 一次讀完，脈絡完整 |
| 內容結構 | 視複雜度而定（單一 SKILL.md 或加 references/ 分檔） | 簡單 Skill 單檔即可；內容過長則分檔 |
| Skill 登記 | `.claude-plugin/plugin.json` | 支援 Claude Code Marketplace |
| AI 人格 | `agents/` 資料夾 | 提供專業領域角色切換 |
| Evals | 採用 vuejs-ai 框架 | 確保每個 Skill 真正有效 |
| 自動化工具 | `scripts/` PowerShell | 跨平台（Windows 優先） |
| 語言 | SKILL.md 繁體中文；`description` 英文 | 中文維護方便，英文供 AI 匹配 |

> [!IMPORTANT]
> YAML frontmatter `description` 欄位保持**英文**（供 AI 關鍵字匹配），其餘內容全部使用**繁體中文**。

---

## Repo 資訊

- **建立位置**：`D:\Project\dotnet-skills`
- **GitHub**：`andychang0121/dotnet-skills`（開源，MIT License）
- **分支**：`main`（穩定發布）、`dev`（開發用）

---

## Proposed Changes

### 根目錄檔案

#### [NEW] README.md

包含以下章節：

1. **專案簡介** — 解決什麼問題、適用哪些 AI 工具
2. **安裝方式**（多工具支援）

   ```bash
   # Claude Code CLI
   /plugin marketplace add andychang0121/dotnet-skills
   /plugin install dotnet-skills

   # GitHub Copilot（專案層級）
   git clone https://github.com/andychang0121/dotnet-skills.git /tmp/dotnet-skills
   cp -r /tmp/dotnet-skills/skills/* .github/skills/

   # 通用（npx）
   npx skills add andychang0121/dotnet-skills
   ```

3. **建議的 AGENTS.md 路由片段** — 複製貼上即可使用的範本
4. **Skill 清單表格**
5. **詳細使用範例（每個 Skill 提供 Before/After 對比）**，例如：

   **`csharp-primary-constructor`**
   > 提示詞：`use dotnet skill, 建立一個 UserService 注入 IUserRepository`

   ❌ 未使用 Skill（AI 舊式寫法）：

   ```csharp
   public class UserService
   {
       private readonly IUserRepository _repository;
       public UserService(IUserRepository repository)
       {
           _repository = repository;
       }
   }
   ```

   ✅ 使用 Skill 後：

   ```csharp
   public class UserService(IUserRepository repository)
   {
       // 直接使用 repository，無需宣告欄位
   }
   ```

   **`efcore-async-patterns`**
   > 提示詞：`use dotnet skill, 在 Service 中查詢使用者並儲存`

   ❌ 未使用 Skill：

   ```csharp
   var user = dbContext.Users.FirstOrDefault(u => u.Id == id);
   dbContext.SaveChanges(); // 同步阻塞
   ```

   ✅ 使用 Skill 後：

   ```csharp
   var user = await dbContext.Users.AsNoTracking()
       .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
   await dbContext.SaveChangesAsync(cancellationToken);
   ```

   **`dotnet-di-patterns`**
   > 提示詞：`use dotnet skill, 建立一個需要每次請求都取得新實例的 ReportService`

   ❌ 未使用 Skill（生命週期錯誤）：

   ```csharp
   services.AddSingleton<IReportService, ReportService>(); // ❌ 應為 Scoped
   ```

   ✅ 使用 Skill 後：

   ```csharp
   services.AddScoped<IReportService, ReportService>(); // ✅ 每次 HTTP 請求一個實例
   ```

6. **貢獻指南**

#### [NEW] CHANGELOG.md

遵循 Keep a Changelog 格式，初始版本 `0.1.0`。

#### [NEW] AGENTS.md

新增 Skill 的完整步驟（含 plugin.json 更新、Skill 格式規範）。

#### [NEW] LICENSE（MIT）

#### [NEW] .gitignore（bin/、obj/、*.user、node_modules/）

---

### Plugin 設定

#### [NEW] .claude-plugin/plugin.json

```json
{
  "name": "dotnet-skills",
  "version": "0.1.0",
  "description": "ASP.NET Core MVC REST API best practices for .NET 8/10 — Clean Architecture, async patterns, DI, EF Core, Result pattern, and more.",
  "author": { "name": "Andy Chang", "url": "https://github.com/andychang0121" },
  "repository": "https://github.com/andychang0121/dotnet-skills",
  "skills": [
    "./skills/clean-architecture-layers",
    "./skills/csharp-primary-constructor",
    "./skills/aspnetcore-controller-best-practices",
    "./skills/aspnetcore-program-cs-extensions",
    "./skills/aspnetcore-response-patterns",
    "./skills/efcore-async-patterns",
    "./skills/dotnet-di-patterns",
    "./skills/csharp-result-pattern",
    "./skills/dotnet-options-pattern",
    "./skills/dotnet-background-services",
    "./skills/aspnetcore-middleware",
    "./skills/csharp-coding-standards",
    "./skills/dotnet-ddd-patterns"
  ],
  "agents": ["./agents/dotnet-api-specialist.md"]
}
```

#### [NEW] .claude-plugin/marketplace.json

---

### Skills（10 個）

每個 SKILL.md 包含：YAML frontmatter、使用時機、核心模式（✅ 正確 / ❌ 錯誤對比）、常見陷阱、最佳實踐摘要。

| # | Skill 目錄 | 主題 | 類型 |
|---|---|---|---|
| 1 | `clean-architecture-layers` | 分層依賴、Controller 不操作 DbContext | Efficiency |
| 2 | `csharp-primary-constructor` | C# 12 Primary Constructor 注入 DI | Efficiency |
| 3 | `aspnetcore-controller-best-practices` | `[ApiController]`、`[ProducesResponseType]`、Route | Efficiency |
| 4 | `aspnetcore-program-cs-extensions` | Program.cs Extension Method 分層 | Efficiency |
| 5 | `aspnetcore-response-patterns` | `Ok()`/`BadRequest()`/`ProblemDetails` | Capability |
| 6 | `efcore-async-patterns` | `async/await`、`AsNoTracking`、N+1 | Capability |
| 7 | `dotnet-di-patterns` | 生命週期、Captive Dependency、Keyed Services | Capability |
| 8 | `csharp-result-pattern` | `Result<T>` 取代業務錯誤 Exception | Efficiency |
| 9 | `dotnet-options-pattern` | `IOptions<T>` vs `IOptionsMonitor<T>` vs `IOptionsSnapshot<T>` | Capability |
| 10 | `dotnet-background-services` | `BackgroundService`、`CancellationToken` 取消模式 | Capability |
| 11 | `aspnetcore-middleware` | 自定義 Middleware 開發、`RequestDelegate` 管線、全域例外攔截（`IExceptionHandler`/.NET 8）、RFC 9457 錯誤回應格式 | Efficiency |
| 12 | `csharp-coding-standards` | 明確型別、Expression-body、命名規範、**每個 method 必須有繁體中文註解與使用範例**、**class/struct/record 每個欄位必須有一列式 `<summary>`** | Capability |
| 13 | `dotnet-ddd-patterns` | DDD 核心概念（Entity / Value Object / Aggregate / Domain Service / Repository）、與 Clean Architecture 整合 | Efficiency |

> [!NOTE]
> **後續版本（0.2.0）考慮加入：** `dotnet-logging-patterns`（結構化日誌）、`efcore-migration-patterns`、`aspnetcore-global-exception`（.NET 8 `IExceptionHandler`）

---

### Agents（1 個）

#### [NEW] agents/dotnet-api-specialist.md

```yaml
---
name: dotnet-api-specialist
description: Expert in ASP.NET Core REST API design, Clean Architecture, EF Core performance, and .NET 8/10 best practices. Invoked for architecture reviews, performance issues, and complex API design questions.
model: sonnet
color: blue
---
```

---

### Scripts（PowerShell）

#### [NEW] scripts/install.ps1（**核心！一鍵安裝**）

使用者在自己專案中執行，腳本會顯示互動式選單，根據選擇的 AI 工具自動完成對應設定：

```
==============================
  .NET Skills 安裝程式
==============================
請輸入專案資料夾路徑 (Enter 為目前目錄):
> D:\Project\MyNewApi\_

請選擇你的 AI 工具：
  1. VS Code (GitHub Copilot)
  2. Cursor
  3. Antigravity (Google)
==============================
請輸入選項 (1-3)：
```

**VS Code → GitHub Copilot**

- 下載 Skills 至 `.github/skills/`
- 建立 `.github/copilot-instructions.md`（含 Skill 路由片段）

**Cursor**

- 下載 Skills 至 `.cursor/skills/`
- 建立 `.cursorrules`（含 Skill 路由片段）

**Antigravity**

- 下載 Skills 至 `.agents/skills/`
- 建立 `.agents/AGENTS.md`（含 Skill 路由片段）

所有選項都會在完成後列出已安裝的 Skills 清單並說明使用方式。

#### [NEW] scripts/validate-skills.ps1

- 驗證每個 `skills/` 子資料夾有 SKILL.md
- 驗證 SKILL.md 含有效 YAML frontmatter（`name`、`description`）
- 驗證所有 Skills 已在 plugin.json 中登記

#### [NEW] scripts/generate-index.ps1

- 自動掃描所有 SKILL.md 的 `name` 欄位
- 更新 README.md 中的 Skill 清單表格

---

### Evals（4 套 × 3 Scenario）

| Eval | Skill | 驗證重點 |
|---|---|---|
| `async-efcore-query` | efcore-async-patterns | 使用 `SaveChangesAsync`、`FirstOrDefaultAsync` |
| `primary-constructor` | csharp-primary-constructor | 使用 Primary Constructor 而非手動欄位 |
| `controller-response` | aspnetcore-controller-best-practices | 回傳 `IActionResult` + `[ProducesResponseType]` |
| `di-lifetime` | dotnet-di-patterns | Scoped 未注入進 Singleton |

---

### GitHub Actions

| 檔案 | 觸發時機 | 功能 |
|---|---|---|
| `validate-skills.yml` | PR | 執行 validate-skills.ps1 |
| `sync-to-main.yml` | 手動 | dev → main 同步 |
| `release.yml` | Push semver tag | 自動建立 GitHub Release |

---

## Verification Plan

```powershell
# 本地驗證
.\scripts\validate-skills.ps1

# 確認 plugin.json 路徑
$config = Get-Content .claude-plugin/plugin.json | ConvertFrom-Json
$config.skills | ForEach-Object {
    if (-not (Test-Path "$_/SKILL.md")) { Write-Error "找不到：$_/SKILL.md" }
}
```

手動驗證：在 VS Code Copilot 輸入 `use dotnet skill, 建立一個包含 CRUD 的 ProductController`，確認輸出使用 Primary Constructor、`IActionResult`、`[ProducesResponseType]`。
