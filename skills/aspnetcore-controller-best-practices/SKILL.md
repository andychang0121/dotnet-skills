---
name: aspnetcore-controller-best-practices
description: ASP.NET Core MVC Controller best practices. Use [ApiController] and [ProducesResponseType] attributes. Follow REST route naming conventions. Return IActionResult or ActionResult<T>. Keep controllers thin by delegating business logic to services.
invocable: false
---

# ASP.NET Core Controller 最佳實踐

## 使用時機

當你需要：

- 建立新的 API Controller
- 定義 HTTP 端點（GET / POST / PUT / PATCH / DELETE）
- 標注 Swagger 文件與回應型別
- 判斷 Controller 應該負責哪些邏輯

---

## 模式一：[ApiController] 與自動 ModelState 驗證

加上 `[ApiController]` 後，ASP.NET Core 會**自動**在 `ModelState.IsValid == false` 時回傳 400，不需手動判斷。

### ❌ 錯誤寫法（手動檢查 ModelState，已由 [ApiController] 處理）

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductController(IProductService productService) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> CreateAsync([FromBody] CreateProductDto dto)
    {
        // ❌ 不需要，[ApiController] 已自動處理
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        ProductDto result = await productService.CreateAsync(dto);
        return CreatedAtAction(nameof(GetAsync), new { id = result.Id }, result);
    }
}
```

### ✅ 正確寫法（移除冗餘的 ModelState 檢查）

```csharp
/// <summary>商品管理 API Controller</summary>
[ApiController]
[Route("api/[controller]")]
public class ProductController(IProductService productService) : ControllerBase
{
    /// <summary>
    /// 建立新商品。
    /// 使用範例：POST /api/product，Body 為 CreateProductDto JSON
    /// </summary>
    [HttpPost]
    [ProducesResponseType<ProductDto>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateAsync(
        [FromBody] CreateProductDto dto,
        CancellationToken ct)
    {
        // ✅ [ApiController] 已自動驗證 ModelState，這裡直接執行業務邏輯
        ProductDto result = await productService.CreateAsync(dto, ct);
        return CreatedAtAction(nameof(GetAsync), new { id = result.Id }, result);
    }
}
```

---

## 模式二：[ProducesResponseType] 標注規範

每個 Action 的**所有可能回應狀態碼**都必須標注，以產生完整的 Swagger 文件。

### ✅ 完整 CRUD Controller 範例

```csharp
/// <summary>商品 CRUD API</summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class ProductController(IProductService productService) : ControllerBase
{
    /// <summary>
    /// 取得所有商品列表。
    /// 使用範例：GET /api/product
    /// </summary>
    [HttpGet]
    [ProducesResponseType<IEnumerable<ProductDto>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAllAsync(CancellationToken ct)
        => Ok(await productService.GetAllAsync(ct));

    /// <summary>
    /// 根據 ID 取得單一商品。
    /// 使用範例：GET /api/product/3fa85f64-5717-4562-b3fc-2c963f66afa6
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType<ProductDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetAsync(Guid id, CancellationToken ct)
    {
        ProductDto? product = await productService.GetByIdAsync(id, ct);
        return product is null ? NotFound() : Ok(product);
    }

    /// <summary>
    /// 建立新商品。
    /// 使用範例：POST /api/product，Body: { "name": "...", "price": 100 }
    /// </summary>
    [HttpPost]
    [ProducesResponseType<ProductDto>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateAsync(
        [FromBody] CreateProductDto dto,
        CancellationToken ct)
    {
        ProductDto result = await productService.CreateAsync(dto, ct);
        return CreatedAtAction(nameof(GetAsync), new { id = result.Id }, result);
    }

    /// <summary>
    /// 更新商品資訊。
    /// 使用範例：PUT /api/product/3fa85f64-...，Body: { "name": "...", "price": 200 }
    /// </summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType<ProductDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateAsync(
        Guid id,
        [FromBody] UpdateProductDto dto,
        CancellationToken ct)
    {
        ProductDto? result = await productService.UpdateAsync(id, dto, ct);
        return result is null ? NotFound() : Ok(result);
    }

    /// <summary>
    /// 刪除商品。
    /// 使用範例：DELETE /api/product/3fa85f64-...
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteAsync(Guid id, CancellationToken ct)
    {
        bool deleted = await productService.DeleteAsync(id, ct);
        return deleted ? NoContent() : NotFound();
    }
}
```

---

## 模式三：Route 命名慣例

```csharp
// ✅ 標準 Route 設定
[Route("api/[controller]")]         // 自動使用類別名稱（去掉 Controller 後綴）

// 路由範例：
// GET    /api/product           → 取得列表
// GET    /api/product/{id}      → 取得單筆
// POST   /api/product           → 建立
// PUT    /api/product/{id}      → 完整更新
// PATCH  /api/product/{id}      → 部分更新
// DELETE /api/product/{id}      → 刪除

// ✅ 帶型別限制的路由參數
[HttpGet("{id:guid}")]              // 限制為 GUID 格式
[HttpGet("{id:int:min(1)}")]        // 限制為正整數
[HttpGet("{slug:alpha}")]           // 限制為純字母

// ❌ 避免在路由中使用動詞
[HttpGet("getProduct/{id}")]        // ❌ REST 不應用動詞命名
[HttpPost("createProduct")]         // ❌
```

---

## 模式四：Controller 精簡化原則

Controller 只負責：

1. **接收** HTTP 請求（路由、參數解析）
2. **委派** 業務邏輯至 Service
3. **回傳** HTTP 回應（狀態碼、資料）

### ❌ 錯誤寫法（Controller 包含業務邏輯）

```csharp
[HttpPost]
public async Task<IActionResult> CreateAsync([FromBody] CreateProductDto dto, CancellationToken ct)
{
    // ❌ 業務邏輯不應在 Controller
    if (dto.Price <= 0)
        return BadRequest("價格必須大於零");

    if (await db.Products.AnyAsync(p => p.Name == dto.Name, ct))
        return Conflict("商品名稱已存在");

    Product product = new() { Name = dto.Name, Price = dto.Price };
    db.Products.Add(product);
    await db.SaveChangesAsync(ct);

    return CreatedAtAction(nameof(GetAsync), new { id = product.Id }, product);
}
```

### ✅ 正確寫法（Controller 只處理 HTTP 關注點）

```csharp
/// <summary>
/// 建立新商品，驗證與業務邏輯由 Service 處理。
/// 使用範例：POST /api/product，Body 為 CreateProductDto JSON
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
        ? CreatedAtAction(nameof(GetAsync), new { id = result.Value.Id }, result.Value)
        : result.Error.Code switch
        {
            "DUPLICATE_NAME" => Conflict(result.Error.Message),
            "INVALID_PRICE"  => BadRequest(result.Error.Message),
            _                => BadRequest(result.Error.Message)
        };
}
```

---

## 常見陷阱

### 1. 忘記加 [ApiController]

```csharp
// ❌ 少了 [ApiController]，ModelState 自動驗證失效
[Route("api/[controller]")]
public class ProductController : ControllerBase { ... }

// ✅
[ApiController]
[Route("api/[controller]")]
public class ProductController : ControllerBase { ... }
```

### 2. 回傳裸 object 而非泛型 ActionResult

```csharp
// ❌ Swagger 無法推斷回傳型別
public async Task<IActionResult> GetAsync(Guid id) => Ok(await service.GetByIdAsync(id));

// ✅ 加上 [ProducesResponseType] 明確標注
[ProducesResponseType<ProductDto>(StatusCodes.Status200OK)]
public async Task<IActionResult> GetAsync(Guid id, CancellationToken ct)
    => Ok(await service.GetByIdAsync(id, ct));
```

---

## 最佳實踐摘要

| 項目 | 規範 |
|------|------|
| `[ApiController]` | 每個 Controller 必須加，自動處理 ModelState 驗證 |
| `[ProducesResponseType]` | 標注所有可能的回應狀態碼（含錯誤） |
| Route 命名 | 使用名詞，禁止在路由加動詞 |
| 參數限制 | 路由參數加型別限制（`:guid`、`:int` 等） |
| Controller 職責 | 只處理 HTTP，業務邏輯下沉至 Service |
| CancellationToken | 所有 async Action 都接受 `CancellationToken ct` 參數 |
