# .NET Skills — .NET 8/10 RESTful API 開發技能包

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](CHANGELOG.md)

專為 .NET 8/10 RESTful API（MVC Controller 與 Minimal API）開發設計的 AI 技能包。讓 VS Code Copilot、Cursor、Antigravity 等 AI 工具遵循現代 .NET 最佳實踐與 DDD 架構原則，自動產生符合規範的程式碼。

> **所有技能文件均以繁體中文撰寫。**

---

## 📋 系統需求 (System Requirements)

使用本技能包自動生成的程式碼需要滿足以下最低開發環境需求：

- **.NET SDK**：`.NET 8.0` 或更高版本 (支援 .NET 9.0/10.0)
- **C# 語言版本**：`C# 12` 或更高版本 (主建構子 Primary Constructors 的最低需求)

---

## ⚡ 快速開始 (Quick Start)

只需三步，即可在你的 .NET 專案中啟用或移除這套技能包：

### 1. 一鍵安裝 (Install)
在您的 **.NET 專案根目錄**下開啟 PowerShell 視窗，並貼上執行以下指令：
```powershell
PowerShell -ExecutionPolicy Bypass -Command "iwr https://raw.githubusercontent.com/andychang0121/dotnet-skills/master/scripts/install.ps1 | iex"
```
*執行時輸入 `Y` 確認，並選擇您所使用的開發工具（1. VS Code/VS, 2. Cursor, 3. Antigravity），即安裝完成！*

### 2. 開發使用 (Usage)
在與 AI 對話時，在提示詞前方加上 `use dotnet skill,`，AI 就會自動讀取並遵循我們的 20 個技能規範。例如：
> `use dotnet skill, 幫我寫一個 ProductController 並整合 structured-logging。`

### 3. 一鍵解除安裝 (Uninstall)
若想完全清除技能包檔案並恢復專案原狀，在**專案根目錄**下執行：
```powershell
PowerShell -ExecutionPolicy Bypass -Command "iwr https://raw.githubusercontent.com/andychang0121/dotnet-skills/master/scripts/uninstall.ps1 | iex"
```
*此指令會自動偵測已安裝的 AI 工具，並將其產生的技能資料夾與路由設定徹底清除。*

---

## 📦 安裝詳細說明

### 一鍵安裝（推薦）

這套技能包提供一個互動式 PowerShell 安裝程式。在你的**新專案目錄**中，選擇以下其中一種方式執行：

**⭐ 方式一：從 GitHub 線上安裝（當你的 Repo 已設為公開時使用）**

```powershell
PowerShell -ExecutionPolicy Bypass -Command "iwr https://raw.githubusercontent.com/andychang0121/dotnet-skills/master/scripts/install.ps1 | iex"
```

**⭐ 方式二：本機直接安裝（如果你已 Clone 此 Repo 到本機，可直接執行腳本）**

```powershell
# 請將下方的 D:\Project\dotnet-skills 替換為你的實際下載存放路徑
PowerShell -ExecutionPolicy Bypass -File D:\Project\dotnet-skills\scripts\install.ps1
```

執行後安裝程式會詢問：

1. **專案資料夾路徑**（Enter 為目前目錄）
2. **AI 工具選擇**（VS Code / Cursor / Antigravity）

並會自動完成對應的 Skills 下載/複製與專屬設定檔建立。

---

### 手動安裝

#### VS Code（GitHub Copilot）

```bash
git clone https://github.com/andychang0121/dotnet-skills.git /tmp/dotnet-skills
cp -r /tmp/dotnet-skills/skills/* .github/skills/
```

建立 `.github/copilot-instructions.md` 並加入路由片段（見下方說明）。

#### Cursor

```bash
git clone https://github.com/andychang0121/dotnet-skills.git /tmp/dotnet-skills
cp -r /tmp/dotnet-skills/skills/* .cursor/skills/
```

建立 `.cursorrules` 並加入路由片段。

#### Antigravity（Google）

```bash
git clone https://github.com/andychang0121/dotnet-skills.git /tmp/dotnet-skills
cp -r /tmp/dotnet-skills/skills/* .agents/skills/
```

建立 `.agents/AGENTS.md` 並加入路由片段。

#### Claude Code CLI

```
/plugin marketplace add andychang0121/dotnet-skills
/plugin install dotnet-skills
```

---

## 🗂️ 建議的 AGENTS.md 路由片段

將以下內容貼入你的 `AGENTS.md`（或 `.github/copilot-instructions.md` / `.cursorrules`）：

```markdown
# .NET Skills 路由設定

重要：處理所有 .NET / C# 任務時，優先參考 dotnet-skills。

## 路由規則

- 架構設計：clean-architecture-layers, dotnet-ddd-patterns
- 啟動設定：program-cs-extensions, dotnet-di-patterns, dotnet-options-pattern
- Controller 與 Minimal API 開發：controller-apis, minimal-apis, response-patterns
- 資料存取與效能：efcore-async-patterns, efcore-performance
- 錯誤處理：csharp-result-pattern, middleware
- 背景服務：dotnet-background-services
- 快取策略：dotnet-caching-patterns
- 驗證與 DTO 設計：fluent-validation-patterns
- API 文件與規格：openapi-best-practices
- 測試撰寫：dotnet-testing-practices
- 程式碼規範與日誌：csharp-coding-standards, csharp-primary-constructor, structured-logging
- DDD 建模：dotnet-ddd-patterns, clean-architecture-layers
```

---

## 🚀 使用方式

### 觸發關鍵字

在提示詞前加上 `use dotnet skill,` 可確保 AI 參考技能包：

```
use dotnet skill, 建立一個 ProductController 包含 CRUD 操作
use dotnet skill, 在 Program.cs 整理服務注冊
use dotnet skill, 建立 Product Entity 符合 DDD 原則
```

無需前綴時，設定好 `AGENTS.md` 路由後，AI 遇到對應任務也會自動觸發。

---

## 📚 Skills 清單

<!-- SKILLS_LIST_START -->
| Skill | 說明 |
|-------|------|
| `clean-architecture-layers` | ASP.NET Core API 的乾淨架構分層規範，定義 Domain -> Application -> Infrastructure -> Api 的依賴方向。 |
| `controller-apis` | ASP.NET Core MVC Controller 開發最佳實踐，包含 RESTful 路由命名與回應型別標記。 |
| `csharp-coding-standards` | 針對 .NET 8/10 的 C# 程式碼編寫與型別宣告規範。 |
| `csharp-primary-constructor` | 使用 C# 12 主建構子 (Primary Constructor) 進行依賴注入的最佳實踐。 |
| `csharp-result-pattern` | 使用 Result 模式代替異常丟出，處理業務邏輯錯誤與回應狀態。 |
| `dotnet-background-services` | 在 ASP.NET Core 中實作 BackgroundService 背景服務與生命週期管理的最佳實踐。 |
| `dotnet-caching-patterns` | 實作記憶體快取、分散式快取與防擊穿鎖定的快取策略指南。 |
| `dotnet-ddd-patterns` | 領域驅動設計 (DDD) 在 .NET Web API 中的實作模式，包含實體、值物件與聚合根建模。 |
| `dotnet-di-patterns` | ASP.NET Core 依賴注入 (DI) 的生命週期管理與避免常駐相依性 (Captive Dependency) 陷阱。 |
| `dotnet-options-pattern` | 使用 Options 模式進行強型別設定載入與監控的配置指南。 |
| `dotnet-testing-practices` | 使用 xUnit、NSubstitute 與 FluentAssertions 撰寫單元測試與整合測試的最佳實踐。 |
| `efcore-async-patterns` | Entity Framework Core 非同步操作的最佳實踐與常見效能防護。 |
| `efcore-performance` | Entity Framework Core 效能調優，包含 AsNoTracking、拆分查詢與批次更新/刪除。 |
| `fluent-validation-patterns` | 使用 FluentValidation 進行強型別請求驗證、自動註冊與 ProblemDetails 整合的實作規範。 |
| `middleware` | 客製化中介軟體 (Middleware) 的開發規範與全域異常處理器 (IExceptionHandler) 的整合。 |
| `minimal-apis` | ASP.NET Core Minimal API 的端點群組、依賴注入與結果回傳的最佳實踐。 |
| `openapi-best-practices` | 配置高品質 OpenAPI / Swagger 文件、XML 註解與回應型別標籤的最佳實踐。 |
| `program-cs-extensions` | 使用擴充方法優化 Program.cs 的服務註冊與中介軟體管道配置。 |
| `response-patterns` | ASP.NET Core API 回應格式規範，必須遵循 RFC 9457 標準，使用標準 HTTP 狀態碼與 ProblemDetails 格式。 |
| `structured-logging` | 結構化日誌最佳實踐，包含具名範本、LoggerMessage 高效能日誌與日誌上下文 (Scope) 設計。 |
<!-- SKILLS_LIST_END -->

---

## 💡 Before / After 使用範例

### `csharp-primary-constructor`

> 提示詞：`use dotnet skill, 建立一個 UserService 注入 IUserRepository`

❌ **未使用 Skill（AI 舊式寫法）**

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

✅ **使用 Skill 後**

```csharp
/// <summary>使用者服務，處理使用者相關業務邏輯</summary>
public class UserService(IUserRepository repository)
{
    // 直接使用 repository，無需宣告私有欄位
}
```

---

### `csharp-coding-standards`

> 提示詞：`use dotnet skill, 建立 Product 類別`

❌ **未使用 Skill**

```csharp
public class Product
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }

    public bool IsAvailable()
    {
        return Price > 0;
    }
}
```

✅ **使用 Skill 後**

```csharp
public class Product
{
    /// <summary>商品唯一識別碼</summary>
    public Guid Id { get; set; }

    /// <summary>商品名稱</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>商品價格，必須大於零</summary>
    public decimal Price { get; set; }

    /// <summary>
    /// 判斷商品是否可銷售。
    /// 使用範例：if (product.IsAvailable()) { ... }
    /// </summary>
    public bool IsAvailable() => Price > 0;
}
```

---

### `efcore-async-patterns`

> 提示詞：`use dotnet skill, 在 Service 查詢商品並更新狀態`

❌ **未使用 Skill（同步阻塞 + 遺漏 AsNoTracking）**

```csharp
var product = dbContext.Products.FirstOrDefault(p => p.Id == id);
dbContext.SaveChanges();
```

✅ **使用 Skill 後**

```csharp
// 查詢（唯讀）：使用 AsNoTracking 提升效能
Product? product = await dbContext.Products
    .AsNoTracking()
    .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

// 更新：需要追蹤時明確標記
dbContext.Products.Update(product);
await dbContext.SaveChangesAsync(cancellationToken);
```

---

### `dotnet-di-patterns`

> 提示詞：`use dotnet skill, 建立一個每次 HTTP 請求都需要獨立實例的 ReportService`

❌ **未使用 Skill（生命週期錯誤）**

```csharp
services.AddSingleton<IReportService, ReportService>(); // ❌ 所有請求共用同一實例
```

✅ **使用 Skill 後**

```csharp
// Scoped：每次 HTTP 請求建立一個新實例，請求結束後釋放
services.AddScoped<IReportService, ReportService>();
```

---

### `aspnetcore-middleware`（RFC 9457）

> 提示詞：`use dotnet skill, 建立全域例外處理 Middleware`

❌ **未使用 Skill**

```csharp
app.UseExceptionHandler("/error"); // 舊式，無法自訂回應格式
```

✅ **使用 Skill 後**

```csharp
// 實作 IExceptionHandler（.NET 8+），回應格式遵循 RFC 9457
public class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger)
    : IExceptionHandler
{
    /// <summary>
    /// 攔截未處理的例外，統一轉換為 RFC 9457 ProblemDetails 格式回應。
    /// 使用範例：app.UseExceptionHandler() 搭配此 Handler 自動觸發。
    /// </summary>
    public async ValueTask<bool> TryHandleAsync(
        HttpContext context,
        Exception exception,
        CancellationToken cancellationToken)
    {
        logger.LogError(exception, "未處理的例外：{Message}", exception.Message);

        ProblemDetails problem = new()
        {
            Type = "https://tools.ietf.org/html/rfc9457",
            Title = "伺服器內部錯誤",
            Status = StatusCodes.Status500InternalServerError,
            Detail = exception.Message,
            Instance = context.Request.Path
        };

        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await context.Response.WriteAsJsonAsync(problem, cancellationToken);
        return true;
    }
}
```

---

## 🤖 Agents

### `dotnet-api-specialist`

專門處理 .NET RESTful API 架構設計、效能調查、程式碼審查的 AI 人格。當你需要進行架構評審或複雜 API 設計時觸發：

```
請 dotnet-api-specialist 幫我審查這個 Controller 的設計是否符合 REST 原則
```

---

## 🧪 Evals（評估框架）

本 Repo 包含自動化評估，確保每個 Skill 真正有效：

- **4 套 Eval 套件**，每套 3 個獨立 Scenario
- 每個 Scenario 是完整可編譯的 .NET 8 Web API 專案
- 評估會在安裝 Skill 前後各執行一次，比較 AI 輸出品質

詳見 [evals/README.md](evals/README.md)。

---

## 🔧 自動化工具

| 腳本 | 用途 |
|------|------|
| `scripts/install.ps1` | 一鍵安裝，互動選擇 AI 工具 |
| `scripts/validate-skills.ps1` | 驗證所有 Skill 結構完整性 |
| `scripts/generate-index.ps1` | 自動更新 README Skill 清單 |

---

## 🤝 貢獻

1. Fork 此 Repo
2. 從 `dev` 分支建立 feature branch
3. 撰寫 Skill 並執行 `.\scripts\validate-skills.ps1`
4. 提交 PR 至 `dev` 分支

詳見 [AGENTS.md](AGENTS.md)。

---

## 📄 授權

MIT License — Copyright (c) 2026 Andy Chang

詳見 [LICENSE](LICENSE)。

















