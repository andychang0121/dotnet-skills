---
name: csharp-primary-constructor
description: Use C# 12 Primary Constructor for dependency injection in ASP.NET Core. Eliminates boilerplate private readonly fields. Use for DI injection only. Prefer traditional constructor when initialization logic is needed.
invocable: false
---

# C# 12 Primary Constructor 現代注入寫法

## 使用時機

當你需要：

- 透過建構子注入 DI 依賴（Service、Repository、Logger 等）
- 撰寫 Controller、Service、Repository、Middleware 等需要注入的類別
- 簡化建構子樣版程式碼（移除私有欄位宣告）

---

## 核心概念

C# 12 的 **Primary Constructor** 允許將建構子參數直接定義在類別宣告上，省去傳統的欄位宣告與賦值樣版程式碼。

---

## 模式一：Controller 使用 Primary Constructor

### ❌ 錯誤寫法（傳統建構子，程式碼冗長）

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductController : ControllerBase
{
    private readonly IProductService _productService;
    private readonly ILogger<ProductController> _logger;

    public ProductController(
        IProductService productService,
        ILogger<ProductController> logger)
    {
        _productService = productService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetAllAsync(CancellationToken ct)
    {
        return Ok(await _productService.GetAllAsync(ct));
    }
}
```

### ✅ 正確寫法（Primary Constructor，精簡清晰）

```csharp
/// <summary>商品管理 API Controller</summary>
[ApiController]
[Route("api/[controller]")]
public class ProductController(
    IProductService productService,
    ILogger<ProductController> logger) : ControllerBase
{
    /// <summary>
    /// 取得所有商品列表。
    /// 使用範例：GET /api/product
    /// </summary>
    [HttpGet]
    [ProducesResponseType<IEnumerable<ProductDto>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAllAsync(CancellationToken ct)
    {
        logger.LogInformation("取得商品列表");
        return Ok(await productService.GetAllAsync(ct));
    }
}
```

---

## 模式二：Service 使用 Primary Constructor

### ✅ 正確寫法

```csharp
/// <summary>商品業務邏輯服務</summary>
public class ProductService(
    IProductRepository repository,
    ILogger<ProductService> logger) : IProductService
{
    /// <summary>
    /// 取得所有商品（唯讀查詢）。
    /// 使用範例：IEnumerable&lt;ProductDto&gt; products = await productService.GetAllAsync(ct);
    /// </summary>
    public async Task<IEnumerable<ProductDto>> GetAllAsync(CancellationToken ct)
    {
        logger.LogDebug("查詢所有商品");
        IEnumerable<Product> entities = await repository.GetAllAsync(ct);
        return entities.Select(MapToDto);
    }

    /// <summary>
    /// 將 Product Entity 映射為 ProductDto。
    /// 使用範例：ProductDto dto = MapToDto(product);
    /// </summary>
    private static ProductDto MapToDto(Product entity) => new()
    {
        Id = entity.Id,
        Name = entity.Name,
        Price = entity.Price
    };
}
```

---

## 模式三：何時仍使用傳統建構子

當建構子需要**執行初始化邏輯**（非單純賦值）時，使用傳統建構子：

```csharp
// ✅ 需要初始化邏輯時，使用傳統建構子
public class CacheService : ICacheService
{
    private readonly IMemoryCache _cache;
    private readonly TimeSpan _defaultExpiry;

    public CacheService(IMemoryCache cache, IConfiguration config)
    {
        _cache = cache;
        // 初始化邏輯：從設定讀取並轉換型別
        int minutes = config.GetValue<int>("Cache:DefaultExpiryMinutes", 30);
        _defaultExpiry = TimeSpan.FromMinutes(minutes);
    }
}

// ✅ Primary Constructor（無初始化邏輯，單純注入）
public class ProductRepository(AppDbContext db) : IProductRepository { ... }
```

---

## 模式四：record 與 Primary Constructor

Primary Constructor 在 `record` 中是位置性的（Positional），行為與類別不同：

```csharp
// record 的 Primary Constructor 自動產生 init-only 屬性
public record ProductDto(Guid Id, string Name, decimal Price);

// 等同於：
public record ProductDto
{
    /// <summary>商品唯一識別碼</summary>
    public Guid Id { get; init; }

    /// <summary>商品名稱</summary>
    public string Name { get; init; }

    /// <summary>商品售價</summary>
    public decimal Price { get; init; }

    public ProductDto(Guid id, string name, decimal price)
    {
        Id = id;
        Name = name;
        Price = price;
    }
}
```

---

## 常見陷阱

### 1. Primary Constructor 參數不會自動成為欄位

```csharp
public class MyService(IRepository repository)
{
    public void DoWork()
    {
        // ✅ 可直接使用 repository（C# 捕捉為隱式欄位）
        repository.Save();
    }
}

// ❌ 不要同時宣告同名欄位，這會造成重複
public class MyService(IRepository repository)
{
    private readonly IRepository _repository = repository; // ❌ 多餘
}
```

### 2. 不要在 Primary Constructor 中做複雜初始化

```csharp
// ❌ Primary Constructor 不適合複雜邏輯
public class BadService(IConfiguration config)
{
    private readonly string _connectionString =
        config.GetConnectionString("Default") // ❌ 應在建構子內處理
        ?? throw new InvalidOperationException("Connection string 未設定");
}

// ✅ 改用傳統建構子處理驗證邏輯
public class GoodService
{
    private readonly string _connectionString;

    public GoodService(IConfiguration config)
    {
        _connectionString = config.GetConnectionString("Default")
            ?? throw new InvalidOperationException("Connection string 未設定");
    }
}
```

---

## 最佳實踐摘要

| 使用情境 | 建議 |
|----------|------|
| 純 DI 注入（Controller、Service、Repository） | ✅ Primary Constructor |
| 需要初始化邏輯（計算、驗證、轉型） | ✅ 傳統建構子 |
| record 型別 | ✅ Primary Constructor（位置性） |
| struct 型別 | 視情況，通常傳統建構子 |
