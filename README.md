# .NET Skills — .NET 8/10 RESTful API 開發技能包

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](CHANGELOG.md)

專為 .NET 8/10 RESTful API（MVC Controller）開發設計的 AI 技能包。讓 VS Code Copilot、Cursor、Antigravity 等 AI 工具遵循現代 .NET 最佳實踐與 DDD 架構原則，自動產生符合規範的程式碼。

> **所有技能文件均以繁體中文撰寫。**

---

## 📦 安裝

### 一鍵安裝（推薦）

在你的**新專案目錄**執行以下指令，互動式選單會引導你完成設定：

```powershell
PowerShell -ExecutionPolicy Bypass -Command "iwr https://raw.githubusercontent.com/andychang0121/dotnet-skills/main/scripts/install.ps1 | iex"
```

安裝程式會詢問：

1. **專案資料夾路徑**（Enter 為目前目錄）
2. **AI 工具選擇**（VS Code / Cursor / Antigravity）

並自動完成對應的 Skills 安裝與設定檔建立。

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
- 啟動設定：aspnetcore-program-cs-extensions, dotnet-di-patterns, dotnet-options-pattern
- Controller 開發：aspnetcore-controller-best-practices, aspnetcore-response-patterns
- 資料存取：efcore-async-patterns
- 錯誤處理：csharp-result-pattern, aspnetcore-middleware
- 背景服務：dotnet-background-services
- 程式碼規範：csharp-coding-standards, csharp-primary-constructor
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

### 架構類

| Skill | 說明 | 類型 |
|-------|------|------|
| `clean-architecture-layers` | Clean Architecture 分層原則，Controller 不直接操作 DbContext | Efficiency |
| `dotnet-ddd-patterns` | DDD 核心概念（Entity / Value Object / Aggregate / Domain Service / Repository） | Efficiency |

### C# 語言類

| Skill | 說明 | 類型 |
|-------|------|------|
| `csharp-primary-constructor` | C# 12 Primary Constructor 現代注入寫法 | Efficiency |
| `csharp-coding-standards` | 明確型別、Expression-body、繁體中文註解、XML summary | Capability |
| `csharp-result-pattern` | `Result<T>` 取代業務錯誤 Exception | Efficiency |

### ASP.NET Core 類

| Skill | 說明 | 類型 |
|-------|------|------|
| `aspnetcore-controller-best-practices` | `[ApiController]`、`[ProducesResponseType]`、Route 命名 | Efficiency |
| `aspnetcore-program-cs-extensions` | Program.cs Extension Method 分層整理 | Efficiency |
| `aspnetcore-response-patterns` | `Ok()`/`BadRequest()`/`NotFound()` 使用場景 | Capability |
| `aspnetcore-middleware` | 自定義 Middleware、RFC 9457 全域例外處理 | Efficiency |

### DI 與設定類

| Skill | 說明 | 類型 |
|-------|------|------|
| `dotnet-di-patterns` | Singleton/Scoped/Transient 生命週期、Captive Dependency | Capability |
| `dotnet-options-pattern` | `IOptions<T>` vs `IOptionsMonitor<T>` vs `IOptionsSnapshot<T>` | Capability |

### EF Core 類

| Skill | 說明 | 類型 |
|-------|------|------|
| `efcore-async-patterns` | async/await 全面使用、AsNoTracking、N+1 問題 | Capability |

### 背景服務類

| Skill | 說明 | 類型 |
|-------|------|------|
| `dotnet-background-services` | `BackgroundService`、`CancellationToken` 正確取消模式 | Capability |

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
