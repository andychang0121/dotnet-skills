---
name: openapi-best-practices
description: Best practices for configuring high-quality OpenAPI/Swagger documentation, utilizing XML comments, and specifying accurate response types.
invocable: false
---

# API 文件與 OpenAPI 最佳實踐

## 使用時機（When to Use）
本技能適用於開發 ASP.NET Core REST API 專案時，需要配置並產生高品質的 OpenAPI (Swagger) 文件的場景。特別是如何結合 XML 註解、標註適當的 HTTP 狀態碼與回應格式屬性，使前端開發人員或外部對接系統能取得精準、易讀的 API 規格書。

## 核心模式

### ✅ 正確範例
* **精準的 HTTP 狀態碼標註**：使用 `[ProducesResponseType]` 標註每一個可能的狀態碼（如 200, 400, 404, 500）及其對應的回傳型別。
* **明確的回傳格式約束**：在 Controller 或 Action 標註 `[Produces("application/json")]`，限制格式為 JSON。
* **高品質的 XML 註解**：在 Action 與 DTO 上撰寫 `<param>`, `<returns>`, 與 `<response>`，使 Swagger UI 能渲染成豐富的文件內容。
* **XML 文件規範**：所有說明與範例一律使用繁體中文註解。

```csharp
using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace DotNetSkills.OpenApi.BestPractices;

/// <summary>
/// 產品管理控制器
/// </summary>
[ApiController]
[Route("api/products")]
[Produces("application/json")]
public class ProductController : ControllerBase
{
    private readonly IProductService _productService;

    /// <summary>
    /// 初始化產品管理控制器
    /// </summary>
    public ProductController(IProductService productService)
    {
        _productService = productService;
    }

    /// <summary>
    /// 根據產品唯一識別碼 (GUID) 取得詳細資訊
    /// </summary>
    /// <param name="id" example="d3b07384-d113-4956-bc7e-aa7827464012">產品識別碼</param>
    /// <returns>產品詳細資料</returns>
    /// <response code="200">成功取得產品資料</response>
    /// <response code="404">找不到指定的產品</response>
    /// <response code="500">伺服器內部發生未預期錯誤</response>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ProductDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetByIdAsync(Guid id)
    {
        ProductDto? product = await _productService.GetByIdAsync(id);
        if (product is null)
        {
            return NotFound(new ProblemDetails
            {
                Status = StatusCodes.Status404NotFound,
                Title = "找不到資源",
                Detail = $"找不到識別碼為 '{id}' 的產品。"
            });
        }

        return Ok(product);
    }
}
```

### ❌ 錯誤反例
* 完全不標註 `[ProducesResponseType]`，導致 Swagger 上顯示的回傳類型是空白或全部都是預設的 `200`，使前端對接人員無從得知可能產生的異常狀態碼。
* 缺少任何 XML 欄位與 API 的說明註解，使得產生的文件流於形式。

```csharp
using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace DotNetSkills.OpenApi.BestPractices;

[ApiController]
[Route("api/[controller]")]
public class BadProductController : ControllerBase
{
    private readonly IProductService _service;

    public BadProductController(IProductService service)
    {
        _service = service;
    }

    // 錯誤 1: 缺少 XML 文件說明註解，也沒有標明回傳參數與狀態碼描述
    // 錯誤 2: 回傳 IActionResult 卻沒有標示 [ProducesResponseType]，Swagger UI 上看不到回傳的模型結構
    [HttpGet("{id}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var product = await _service.GetByIdAsync(id);
        if (product == null)
        {
            return NotFound(); // 前端無法在文件上預先看到 404
        }
        return Ok(product);
    }
}
```

## 常見陷阱（Common Pitfalls）
1. **忘記在專案檔中開啟 XML 文件產生設定**：若沒有在 `.csproj` 中加入 `<GenerateDocumentationFile>true</GenerateDocumentationFile>`，所有的 XML 註解將不會被編譯輸出，Swagger 也無法載入這些註解。
2. **忘記設定 Swagger 載入 XML**：即使產生了 XML 檔案，若沒有在 `AddSwaggerGen` 中配置 `options.IncludeXmlComments(xmlPath)`，文件仍然是空白的。
3. **未忽略無意義的編譯器警告**：開啟 XML 文件產生後，未寫註解的程式碼會產生 `CS1591` 警告。應在 `.csproj` 中加入 `<NoWarn>$(NoWarn);1591</NoWarn>` 以忽略非公開成員或不重要的警告。

## 最佳實踐摘要
* 所有對外公開的 API Controller 及 Action 必須具備繁體中文的 XML 說明註解。
* 每個 API 終端（Action）必須依可能的回傳狀況，標註 `[ProducesResponseType]` 以及正確的回應實體類別。
* 控制器類別上方應標註 `[Produces("application/json")]`，限定 JSON 格式輸出。
* API DTO 的欄位屬性，除摘要外，可適當加上 `<example>` XML 標記以利文件產生範例數值。
* API 錯誤回應模型，統一採用 .NET 官方推薦的 `ProblemDetails`。
