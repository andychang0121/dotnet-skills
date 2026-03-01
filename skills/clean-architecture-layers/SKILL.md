---
name: clean-architecture-layers
description: Clean Architecture layering for ASP.NET Core APIs. Domain -> Application -> Infrastructure -> Api dependency direction. Controllers must not directly access DbContext. Services injected via interfaces. DTOs separate from Entities.
invocable: false
---

# Clean Architecture 分層架構原則

## 使用時機

當你需要：

- 建立新的 .NET REST API 專案結構
- 判斷某段程式碼應該放在哪一層
- 避免 Controller 直接操作資料庫
- 設計 Service、Repository 的介面與實作位置

---

## 分層架構總覽

```
專案名稱/
├── App/
│   └── 專案名稱.Api/              ← 表現層（Presentation Layer）
│       ├── Controllers/           ← HTTP 端點
│       ├── ViewModels/            ← 請求/回應 ViewModel（非 DTO）
│       └── Infrastructure/        ← API 層的設定（Middleware、Extension）
├── Core/
│   ├── 專案名稱.Application/      ← 應用層（Application Layer）
│   │   ├── DTOs/                  ← 資料傳輸物件
│   │   ├── Interfaces/            ← Service 介面定義
│   │   └── Services/              ← 業務邏輯實作
│   └── 專案名稱.Domain/           ← 領域層（Domain Layer）
│       ├── Entities/              ← 領域實體
│       ├── Interfaces/            ← Repository 介面定義
│       ├── Exceptions/            ← 領域例外
│       └── Primitives/            ← Value Object、基底類別
├── Db/
│   └── 專案名稱.Infrastructure/   ← 基礎設施層（Infrastructure Layer）
│       ├── Data/                  ← DbContext、Entity 設定
│       ├── Repositories/          ← Repository 實作
│       └── Services/              ← 外部服務實作（Email、Cache 等）
└── Lib/
    └── 專案名稱.Common/           ← 共用工具（跨層使用）
```

---

## 核心原則：依賴方向

依賴只能由外層指向內層，**絕不反向**：

```
Api → Application → Domain
 ↑           ↑
Infrastructure（實作 Domain 的介面）
```

**Domain 層不能依賴任何其他層。**

---

## 模式一：Controller 不直接存取資料庫

### ❌ 錯誤寫法（Controller 直接注入 DbContext）

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductController(AppDbContext db) : ControllerBase
{
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetAsync(Guid id, CancellationToken ct)
    {
        // ❌ Controller 直接操作 DbContext，違反分層原則
        Product? product = await db.Products.FindAsync(id, ct);
        return product is null ? NotFound() : Ok(product);
    }
}
```

### ✅ 正確寫法（Controller 透過 Service 介面）

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductController(IProductService productService) : ControllerBase
{
    /// <summary>
    /// 根據 ID 取得商品資訊。
    /// 使用範例：GET /api/product/3fa85f64-5717-4562-b3fc-2c963f66afa6
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType<ProductDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetAsync(Guid id, CancellationToken ct)
    {
        // ✅ 透過 Service 介面，Controller 只處理 HTTP 關注點
        ProductDto? product = await productService.GetByIdAsync(id, ct);
        return product is null ? NotFound() : Ok(product);
    }
}
```

---

## 模式二：介面定義在 Domain/Application，實作在 Infrastructure

### ❌ 錯誤寫法（Application 層直接依賴 Infrastructure 實作）

```csharp
// Application 層 ← 直接引用 Infrastructure 的具體類別
public class OrderService(SqlOrderRepository repository) { ... } // ❌
```

### ✅ 正確寫法（依賴抽象介面）

```csharp
// Domain 層：定義 Repository 介面
namespace 專案名稱.Domain.Interfaces;

/// <summary>訂單資料存取介面，由 Infrastructure 層實作</summary>
public interface IOrderRepository
{
    /// <summary>
    /// 根據 ID 取得訂單。
    /// 使用範例：Order? order = await _repo.GetByIdAsync(orderId, ct);
    /// </summary>
    Task<Order?> GetByIdAsync(Guid id, CancellationToken ct);

    /// <summary>
    /// 新增訂單至資料庫。
    /// 使用範例：await _repo.AddAsync(newOrder, ct);
    /// </summary>
    Task AddAsync(Order order, CancellationToken ct);
}

// Infrastructure 層：實作介面
namespace 專案名稱.Infrastructure.Repositories;

public class SqlOrderRepository(AppDbContext db) : IOrderRepository
{
    /// <inheritdoc/>
    public async Task<Order?> GetByIdAsync(Guid id, CancellationToken ct)
        => await db.Orders.FindAsync([id], ct);

    /// <inheritdoc/>
    public async Task AddAsync(Order order, CancellationToken ct)
    {
        db.Orders.Add(order);
        await db.SaveChangesAsync(ct);
    }
}

// Application 層：只依賴介面
public class OrderService(IOrderRepository orderRepository) { ... } // ✅
```

---

## 模式三：DTO 與 Entity 的邊界

### ❌ 錯誤寫法（直接回傳 Entity）

```csharp
// ❌ 直接回傳 Domain Entity，洩漏領域細節，且無法控制序列化
public async Task<Product> GetByIdAsync(Guid id) { ... }
```

### ✅ 正確寫法（使用 DTO 轉換）

```csharp
// Application 層 DTO：只包含 API 需要的欄位
namespace 專案名稱.Application.DTOs.Product;

public record ProductDto
{
    /// <summary>商品唯一識別碼</summary>
    public Guid Id { get; init; }

    /// <summary>商品名稱</summary>
    public string Name { get; init; } = string.Empty;

    /// <summary>商品售價（含稅）</summary>
    public decimal Price { get; init; }
}

// Service 手動映射（禁止使用 AutoMapper）
public class ProductService(IProductRepository repository) : IProductService
{
    /// <summary>
    /// 根據 ID 取得商品 DTO。
    /// 使用範例：ProductDto? dto = await productService.GetByIdAsync(id, ct);
    /// </summary>
    public async Task<ProductDto?> GetByIdAsync(Guid id, CancellationToken ct)
    {
        Product? entity = await repository.GetByIdAsync(id, ct);
        if (entity is null) return null;

        // 手動映射：明確控制哪些欄位暴露給外部
        return new ProductDto
        {
            Id = entity.Id,
            Name = entity.Name.Value,
            Price = entity.Price.Amount
        };
    }
}
```

---

## 模式四：DI 服務注冊的分層整理

### ✅ 正確寫法（各層自行定義 Extension Method）

```csharp
// Application 層
namespace 專案名稱.Application.Services;

public static class ServiceExtensions
{
    /// <summary>
    /// 注冊所有 Application 層服務。
    /// 使用範例：builder.Services.AddApplicationServices();
    /// </summary>
    public static IServiceCollection AddApplicationServices(
        this IServiceCollection services) =>
        services
            .AddScoped<IProductService, ProductService>()
            .AddScoped<IOrderService, OrderService>();
}

// Infrastructure 層
public static class InfrastructureExtensions
{
    /// <summary>
    /// 注冊所有 Infrastructure 層服務（DbContext、Repository）。
    /// 使用範例：builder.Services.AddInfrastructureServices(config);
    /// </summary>
    public static IServiceCollection AddInfrastructureServices(
        this IServiceCollection services,
        IConfiguration configuration) =>
        services
            .AddDbContext<AppDbContext>(opt =>
                opt.UseSqlServer(configuration.GetConnectionString("Default")))
            .AddScoped<IProductRepository, SqlProductRepository>();
}

// Program.cs（保持精簡）
builder.Services
    .AddApplicationServices()
    .AddInfrastructureServices(builder.Configuration)
    .AddApiServices(builder.Configuration);
```

---

## 常見陷阱

### 1. Infrastructure 層注入 Application 層（反向依賴）

```csharp
// ❌ Infrastructure 不能依賴 Application
public class EmailSender(IOrderService orderService) { ... }
```

**解決**：透過 Domain 事件或 Callback 傳遞資料，不直接注入上層服務。

### 2. 在 Domain Entity 引用 EF Core

```csharp
// ❌ Domain 層不能有 EF Core 的 using
using Microsoft.EntityFrameworkCore;
public class Product { [Key] public Guid Id { get; set; } } // ❌ [Key] 是 EF Core Attribute
```

**解決**：在 `Infrastructure/Data/Configurations/` 使用 Fluent API 設定，Entity 保持純淨。

### 3. Controller 直接 new Service

```csharp
// ❌ 直接實例化，無法測試、無法替換
IProductService service = new ProductService(new SqlProductRepository(...));
```

**解決**：永遠透過 DI 注入，永遠依賴介面。

---

## 最佳實踐摘要

| 項目 | 規範 |
|------|------|
| 依賴方向 | Api → Application → Domain，Infrastructure 實作 Domain 介面 |
| Controller 職責 | 只處理 HTTP（路由、驗證、回應），業務邏輯一律下沉至 Service |
| 介面位置 | Service 介面 → Application；Repository 介面 → Domain |
| DTO 映射 | 手動映射，禁止 AutoMapper；Entity 不直接回傳給 API |
| DI 注冊 | 各層使用 Extension Method，Program.cs 保持精簡 |
