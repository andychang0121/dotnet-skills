# .NET Skills — .NET 8/10 RESTful API 開發技能包

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](CHANGELOG.md)

專為 .NET 8/10 RESTful API（MVC Controller 與 Minimal API）開發設計的 AI 技能包。讓 VS Code Copilot、Cursor、Antigravity 等 AI 工具遵循現代 .NET 最佳實踐與 DDD 架構原則，自動產生符合規範的程式碼。

> **所有技能文件均以繁體中文撰寫。**

---

## 📦 安裝

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

路由：
- 架構設計：clean-architecture-layers, dotnet-ddd-patterns
- 啟動設定：program-cs-extensions, dotnet-di-patterns, dotnet-options-pattern
- Controller 與 Minimal API 開發：controller-apis, minimal-apis, response-patterns
- 資料存取：efcore-async-patterns
- 錯誤處理：csharp-result-pattern, middleware
- 背景服務：dotnet-background-services
- 程式碼規範與日誌：csharp-coding-standards, csharp-primary-constructor, structured-logging
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
| `clean-architecture-layers` | Clean Architecture layering for ASP.NET Core APIs. Domain -> Application -> Infrastructure -> Api dependency direction. Controllers must not directly access DbContext. Services injected via interfaces. DTOs separate from Entities. |
| `controller-apis` | ASP.NET Core MVC Controller best practices. Use [ApiController] and [ProducesResponseType] attributes. Follow REST route naming conventions. Return IActionResult or ActionResult<T>. Keep controllers thin by delegating business logic to services. |
| `csharp-coding-standards` | C# coding standards for .NET 8/10. Use explicit types instead of var. Use expression-body members (=>) for simple methods and properties. Apply Traditional Chinese XML summary to all class/struct/record fields and methods with usage examples. Follow C# naming conventions. |
| `csharp-primary-constructor` | Use C# 12 Primary Constructor for dependency injection in ASP.NET Core. Eliminates boilerplate private readonly fields. Use for DI injection only. Prefer traditional constructor when initialization logic is needed. |
| `csharp-result-pattern` | Use Result<T> pattern instead of throwing exceptions for business logic errors in ASP.NET Core. Use exceptions only for truly unexpected system errors. Provides Success/Failure factory methods and clean Controller unwrapping. |
| `dotnet-background-services` | Implement background tasks in ASP.NET Core using BackgroundService or IHostedService. Correctly handle CancellationToken for graceful shutdown. Avoid blocking in ExecuteAsync. Use IDbContextFactory for database access in background services. |
| `dotnet-caching-patterns` | Implementing local and distributed caching strategies, using HybridCache (.NET 9), Cache-Aside, and race condition prevention. |
| `dotnet-ddd-patterns` | Domain-Driven Design patterns for ASP.NET Core REST APIs. Implement Entity, Value Object, Aggregate Root, Domain Service, and Repository pattern. Integrate DDD with Clean Architecture. Keep domain logic inside domain objects, not services. |
| `dotnet-di-patterns` | ASP.NET Core dependency injection best practices. Understand Singleton/Scoped/Transient lifetimes. Avoid Captive Dependency (injecting Scoped into Singleton). Use .NET 8 Keyed Services. Always depend on interfaces, not implementations. |
| `dotnet-options-pattern` | Configure ASP.NET Core settings using IOptions<T>, IOptionsMonitor<T>, and IOptionsSnapshot<T>. Know when to use each variant. Bind configuration sections to strongly-typed classes. Avoid magic strings in configuration access. |
| `dotnet-testing-practices` | Best practices for writing unit and integration tests in .NET using xUnit, NSubstitute, FluentAssertions, and WebApplicationFactory. |
| `efcore-async-patterns` | EF Core async/await best practices. Always use SaveChangesAsync, FirstOrDefaultAsync, ToListAsync. Never use .Result or .Wait(). Apply AsNoTracking() for read-only queries. Avoid N+1 queries with proper Include. Always pass CancellationToken. |
| `efcore-performance` | EF Core performance optimization techniques, including AsNoTracking, split queries, and high-performance batch operations. |
| `fluent-validation-patterns` | Designing clean request validation using FluentValidation, automatic dependency injection registration, and standardized error responses. |
| `middleware` | Create custom ASP.NET Core middleware using IMiddleware interface, convention-based approach, or lambda. Implement global exception handling with IExceptionHandler (.NET 8+) and RFC 9457 ProblemDetails format. Understand middleware pipeline ordering. |
| `minimal-apis` | Best practices for ASP.NET Core Minimal APIs. Include Route Groups, Dependency Injection, TypedResults, and validation. |
| `openapi-best-practices` | Best practices for configuring high-quality OpenAPI/Swagger documentation, utilizing XML comments, and specifying accurate response types. |
| `program-cs-extensions` | Organize ASP.NET Core Program.cs using IServiceCollection and IApplicationBuilder extension methods. Avoid bloated Program.cs by grouping service registrations into layered AddXxx() and UseXxx() methods. Follow middleware pipeline ordering. |
| `response-patterns` | Correct usage of ASP.NET Core IActionResult response methods. Use Ok(), BadRequest(), NotFound(), NoContent(), CreatedAtAction() for appropriate HTTP status codes. Standardize error responses using ProblemDetails (RFC 9457). |
| `structured-logging` | Structured logging best practices for .NET. Use message templates with named properties instead of string interpolation, apply high-performance [LoggerMessage] source generator, and enrich logs with BeginScope. |
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










