---
name: aspnetcore-response-patterns
description: Correct usage of ASP.NET Core IActionResult response methods. Use Ok(), BadRequest(), NotFound(), NoContent(), CreatedAtAction() for appropriate HTTP status codes. Standardize error responses using ProblemDetails (RFC 9457).
invocable: false
---

# ASP.NET Core API 回應模式

## 使用時機

當你需要：

- 選擇正確的 HTTP 回應方法（`Ok()`、`NotFound()` 等）
- 設計統一的錯誤回應格式
- 回傳 201 Created 並附上新資源的路由連結

---

## 模式一：標準回應方法使用場景

| 方法 | HTTP 狀態碼 | 使用場景 |
|------|------------|----------|
| `Ok(data)` | 200 | GET 成功、PUT/PATCH 更新成功 |
| `Created(uri, data)` | 201 | 建立新資源（少用，通常用 CreatedAtAction） |
| `CreatedAtAction(...)` | 201 | POST 建立成功，附上新資源的 GET 路由 |
| `NoContent()` | 204 | DELETE 成功、PUT 成功但不回傳資料 |
| `BadRequest(msg)` | 400 | 輸入驗證失敗、業務規則違反 |
| `Unauthorized()` | 401 | 未登入（無驗證資訊） |
| `Forbid()` | 403 | 已登入但無權限 |
| `NotFound()` | 404 | 資源不存在 |
| `Conflict()` | 409 | 資源衝突（如重複名稱） |

### ✅ 完整使用範例

```csharp
/// <summary>商品 API 回應模式示範</summary>
[ApiController]
[Route("api/[controller]")]
public class ProductController(IProductService productService) : ControllerBase
{
    /// <summary>
    /// 建立商品，成功回傳 201 並附上取得路由。
    /// 使用範例：POST /api/product
    /// </summary>
    [HttpPost]
    [ProducesResponseType<ProductDto>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> CreateAsync(
        [FromBody] CreateProductDto dto,
        CancellationToken ct)
    {
        Result<ProductDto> result = await productService.CreateAsync(dto, ct);

        return result.IsSuccess
            ? CreatedAtAction(           // ✅ 201 + Location header
                nameof(GetAsync),
                new { id = result.Value.Id },
                result.Value)
            : result.Error.Code switch
            {
                "DUPLICATE_NAME" => Conflict(CreateProblemDetails(
                    "商品名稱重複",
                    result.Error.Message,
                    StatusCodes.Status409Conflict)),
                _ => BadRequest(CreateProblemDetails(
                    "建立失敗",
                    result.Error.Message,
                    StatusCodes.Status400BadRequest))
            };
    }

    /// <summary>
    /// 刪除商品，成功回傳 204 No Content。
    /// 使用範例：DELETE /api/product/3fa85f64-...
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteAsync(Guid id, CancellationToken ct)
    {
        bool deleted = await productService.DeleteAsync(id, ct);
        return deleted ? NoContent() : NotFound();  // ✅ 204 vs 404
    }
}
```

---

## 模式二：RFC 9457 ProblemDetails 統一錯誤格式

### ❌ 錯誤寫法（自製錯誤格式，不標準）

```csharp
// ❌ 各個 Controller 自定錯誤格式，不一致
return BadRequest(new { error = "名稱已存在", code = 1001 });
return BadRequest("名稱已存在");
return StatusCode(500, $"發生錯誤：{ex.Message}");
```

### ✅ 正確寫法（遵循 RFC 9457 ProblemDetails）

```csharp
// 建立符合 RFC 9457 的 ProblemDetails
private ProblemDetails CreateProblemDetails(
    string title,
    string detail,
    int statusCode,
    string? instance = null) => new()
{
    Type = $"https://httpstatuses.io/{statusCode}",  // RFC 9457
    Title = title,
    Detail = detail,
    Status = statusCode,
    Instance = instance ?? HttpContext.Request.Path
};

// 使用範例
return BadRequest(CreateProblemDetails(
    title: "輸入驗證失敗",
    detail: "商品價格必須大於零",
    statusCode: StatusCodes.Status400BadRequest));

// RFC 9457 回應格式：
// {
//   "type": "https://httpstatuses.io/400",
//   "title": "輸入驗證失敗",
//   "detail": "商品價格必須大於零",
//   "status": 400,
//   "instance": "/api/product"
// }
```

---

## 模式三：避免直接使用 StatusCode(500, ...)

### ❌ 錯誤寫法

```csharp
[HttpGet("{id:guid}")]
public async Task<IActionResult> GetAsync(Guid id, CancellationToken ct)
{
    try
    {
        ProductDto? product = await productService.GetByIdAsync(id, ct);
        return Ok(product);
    }
    catch (Exception ex)
    {
        // ❌ 直接回傳 500，洩漏錯誤細節，且格式不一致
        return StatusCode(500, $"伺服器錯誤：{ex.Message}");
    }
}
```

### ✅ 正確寫法（交由全域 IExceptionHandler 處理）

```csharp
/// <summary>
/// 根據 ID 取得商品。例外由全域 IExceptionHandler 統一處理。
/// 使用範例：GET /api/product/3fa85f64-...
/// </summary>
[HttpGet("{id:guid}")]
[ProducesResponseType<ProductDto>(StatusCodes.Status200OK)]
[ProducesResponseType(StatusCodes.Status404NotFound)]
public async Task<IActionResult> GetAsync(Guid id, CancellationToken ct)
{
    // ✅ 不捕捉例外，讓全域 Middleware 統一處理，Controller 保持精簡
    ProductDto? product = await productService.GetByIdAsync(id, ct);
    return product is null ? NotFound() : Ok(product);
}
```

---

## 常見陷阱

### 1. POST 成功回傳 200 而非 201

```csharp
// ❌ POST 建立資源應回傳 201
[HttpPost]
public async Task<IActionResult> CreateAsync(...)
    => Ok(await service.CreateAsync(...));  // ❌ 應是 CreatedAtAction

// ✅
return CreatedAtAction(nameof(GetAsync), new { id = result.Id }, result);
```

### 2. DELETE 成功回傳資料

```csharp
// ❌ DELETE 成功應回傳 204 No Content
[HttpDelete("{id:guid}")]
public async Task<IActionResult> DeleteAsync(Guid id)
    => Ok(await service.DeleteAsync(id));  // ❌

// ✅
bool deleted = await service.DeleteAsync(id, ct);
return deleted ? NoContent() : NotFound();
```

---

## 最佳實踐摘要

| 項目 | 規範 |
|------|------|
| 建立成功 | `CreatedAtAction()` 回傳 201 + Location header |
| 刪除成功 | `NoContent()` 回傳 204 |
| 資源不存在 | `NotFound()` 回傳 404 |
| 未登入 | `Unauthorized()` 回傳 401 |
| 無權限 | `Forbid()` 回傳 403 |
| 錯誤格式 | 使用 RFC 9457 `ProblemDetails` |
| 伺服器例外 | 交由全域 `IExceptionHandler` 處理，Controller 不 try-catch |
