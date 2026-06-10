---
name: minimal-apis
description: Best practices for ASP.NET Core Minimal APIs. Include Route Groups, Dependency Injection, TypedResults, and validation.
description_zh: ASP.NET Core Minimal API 的端點群組、依賴注入與結果回傳的最佳實踐。
invocable: false
---

# ASP.NET Core Minimal APIs 最佳實踐

## 使用時機

當你需要：

- 建立輕量化、高效能且低記憶體開銷的 HTTP APIs
- 取代傳統 MVC Controller，以減少專案中的樣版程式碼（Boilerplate）
- 搭配 .NET 8/10 現代語法（如 Target-typed new, Primary Constructor）進行快速開發
- 提供對 Swagger/OpenAPI 自動推導友善的強型別 API 接口

---

## 模式一：使用 Route Groups 組織程式碼

避免將所有路由直接堆疊在 `Program.cs` 中，應使用 `IEndpointRouteBuilder` 擴充方法進行模組化分割。

### ❌ 錯誤寫法（Program.cs 臃腫，難以維護）

```csharp
// Program.cs
WebApplication app = builder.Build();

app.MapGet("/api/products", async (AppDbContext db) => ...);
app.MapGet("/api/products/{id}", async (Guid id, AppDbContext db) => ...);
app.MapPost("/api/products", async (ProductCreateDto dto, AppDbContext db) => ...);
// 隨著 API 增加，這裡會堆疊數百行，破壞 Program.cs 的單一職責

app.Run();
```

### ✅ 正確寫法（使用 Extension Method 進行模組化）

```csharp
/// <summary>商品模組的 Endpoint 註冊擴充類別</summary>
public static class ProductEndpoints
{
    /// <summary>
    /// 註冊商品相關的所有 Minimal API 路由群組。
    /// 使用範例：app.MapProductEndpoints();
    /// </summary>
    public static IEndpointRouteBuilder MapProductEndpoints(this IEndpointRouteBuilder routes)
    {
        // 建立路由群組，並統一設定前綴與標籤
        RouteGroupBuilder group = routes.MapGroup("/api/products")
            .WithTags("Products");

        group.MapGet("/", GetProductsAsync);
        group.MapGet("/{id:guid}", GetProductByIdAsync);
        group.MapPost("/", CreateProductAsync);

        return routes;
    }

    private static async Task<IResult> GetProductsAsync(AppDbContext db, CancellationToken ct)
    {
        IReadOnlyList<ProductDto> products = await db.Products
            .AsNoTracking()
            .Select(p => new ProductDto(p.Id, p.Name, p.Price))
            .ToListAsync(ct);
        return TypedResults.Ok(products);
    }

    private static async Task<IResult> GetProductByIdAsync(Guid id, AppDbContext db, CancellationToken ct)
    {
        Product? product = await db.Products.FindAsync([id], ct);
        return product is null 
            ? TypedResults.NotFound() 
            : TypedResults.Ok(new ProductDto(product.Id, product.Name, product.Price));
    }

    private static async Task<IResult> CreateProductAsync(ProductCreateDto dto, AppDbContext db, CancellationToken ct)
    {
        Product product = new()
        {
            Id = Guid.NewGuid(),
            Name = dto.Name,
            Price = dto.Price
        };
        db.Products.Add(product);
        await db.SaveChangesAsync(ct);
        return TypedResults.CreatedAtRoute(nameof(GetProductByIdAsync), new { id = product.Id }, new ProductDto(product.Id, product.Name, product.Price));
    }
}
```

---

## 模式二：依賴注入與參數綁定

Minimal APIs 具備強大的自動參數綁定功能，不需要顯式標記 `[FromServices]`。

### ❌ 錯誤寫法（過多無謂的屬性標記）

```csharp
// ❌ 顯式標記 [FromServices] 與 [FromBody] 顯得冗長且舊式
group.MapPost("/", async ([FromServices] IProductService service, [FromBody] ProductCreateDto dto) => 
{
    return Results.Ok(await service.CreateAsync(dto));
});
```

### ✅ 正確寫法（隱式解析服務與預設綁定）

```csharp
// ✅ 服務（IProductService）會自動從 DI 容器中解析，複雜類型（dto）預設視為 Request Body
group.MapPost("/", async (IProductService service, ProductCreateDto dto, CancellationToken ct) => 
{
    ProductDto result = await service.CreateAsync(dto, ct);
    return TypedResults.Created($"/products/{result.Id}", result);
});
```

---

## 模式三：使用 TypedResults 提供強型別回應

為確保 Swagger/OpenAPI 能自動推導正確的 HTTP 狀態碼與 JSON 結構，必須避免使用 `Results`，而應回傳 `TypedResults` 或是強型別的 `Results<T1, T2...>`。

### ❌ 錯誤寫法（OpenAPI 無法自動推導回應型別，除非手動加 Attribute）

```csharp
// ❌ 回傳 IResult 與 Results.Ok 遺失了強型別，Swagger 會不知道 200 OK 裡面是什麼 DTO
group.MapGet("/{id:guid}", async (Guid id, IProductService service) =>
{
    ProductDto? product = await service.GetByIdAsync(id);
    return product is null 
        ? Results.NotFound() 
        : Results.Ok(product); 
});
```

### ✅ 正確寫法（使用 TypedResults 與 Results<T1, T2>）

```csharp
// ✅ 使用 Results<Ok<ProductDto>, NotFound> 明確標記可能的回傳型別
// Swagger / OpenAPI 會自動辨識 200 OK (含 ProductDto) 與 404 NotFound，不需額外標註
group.MapGet("/{id:guid}", async Task<Results<Ok<ProductDto>, NotFound>> (Guid id, IProductService service, CancellationToken ct) =>
{
    ProductDto? product = await service.GetByIdAsync(id, ct);
    return product is null 
        ? TypedResults.NotFound() 
        : TypedResults.Ok(product);
});
```

---

## 模式四：使用 Filter 進行輸入驗證 (Validation)

避免在 API 主體中撰寫重複的欄位驗證邏輯，應使用 `EndpointFilter` 進行切面（AOP）式驗證攔截。

### ❌ 錯誤寫法（驗證邏輯污染 API 業務核心）

```csharp
group.MapPost("/", async (ProductCreateDto dto, AppDbContext db) =>
{
    // ❌ 欄位驗證邏輯與資料庫操作混在一起，造成程式碼冗長
    if (string.IsNullOrWhiteSpace(dto.Name))
    {
        return Results.BadRequest("商品名稱為必填");
    }
    if (dto.Price <= 0)
    {
        return Results.BadRequest("價格必須大於零");
    }

    // 業務邏輯...
});
```

### ✅ 正確寫法（使用自定義 EndpointFilter 統一處理驗證）

```csharp
/// <summary>驗證 DTO 的 Endpoint 篩選器</summary>
public class ValidationFilter<T>(IValidator<T> validator) : IEndpointFilter where T : class
{
    /// <summary>
    /// 攔截 Endpoint 執行，取得 DTO 參數進行驗證。
    /// </summary>
    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        // 尋找類型符合 T 的輸入參數
        T? argToValidate = context.Arguments.FirstOrDefault(x => x is T) as T;

        if (argToValidate is null)
        {
            return TypedResults.BadRequest("找不到驗證目標 DTO");
        }

        ValidationResult result = await validator.ValidateAsync(argToValidate);
        if (-not result.IsValid)
        {
            // 將 FluentValidation 的錯誤轉換為 RFC 9457 ProblemDetails 格式
            return TypedResults.ValidationProblem(result.ToDictionary());
        }

        return await next(context);
    }
}

// 註冊時直接掛載 Filter：
group.MapPost("/", CreateProductAsync)
     .AddEndpointFilter<ValidationFilter<ProductCreateDto>>();
```

---

## 常見陷阱

### 1. 忘記限制路由參數約束導致 API 匹配衝突
在 Minimal API 中，如果兩個 Endpoint 的路由結構太像，容易發生路由衝突。

```csharp
// ❌ 若沒有加上約束，當請求 GET /api/products/all 時，"all" 會被當作 Guid 解析而報錯
group.MapGet("/{id}", GetProductByIdAsync); 
group.MapGet("/all", GetAllProductsAsync);

// ✅ 加上 :guid 約束以區隔路由參數
group.MapGet("/{id:guid}", GetProductByIdAsync);
group.MapGet("/all", GetAllProductsAsync);
```

### 2. 在 Singleton 服務中解析 Scoped Endpoint Filter 造成生命週期錯置
如果您自定義了 Endpoint Filter，且該 Filter 依賴了 Scoped 服務（如 `DbContext`），請勿將 Filter 宣告為 Singleton 註冊，否則會發生 Captive Dependency 錯誤。

---

## 最佳實踐摘要

| 使用情境 | 建議 |
|----------|------|
| 組織多個 Endpoints | ✅ 使用 Extension Method 搭配 `MapGroup` 模組化 |
| 參數依賴注入 | ✅ 直接寫在參數列中，由 DI 自動隱式解析 |
| API 回應型別 | ✅ 使用 `TypedResults` 或 `Results<T1, T2>` 確保 OpenAPI 自動推導 |
| 輸入欄位驗證 | ✅ 撰寫自定義 `IEndpointFilter` 配合 `FluentValidation` |
| 路由防衝突 | ✅ 為路由變數加上明確約束（如 `/{id:guid}`、`/{name:alpha}`） |
