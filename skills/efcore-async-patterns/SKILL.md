---
name: efcore-async-patterns
description: EF Core async/await best practices. Always use SaveChangesAsync, FirstOrDefaultAsync, ToListAsync. Never use .Result or .Wait(). Apply AsNoTracking() for read-only queries. Avoid N+1 queries with proper Include. Always pass CancellationToken.
invocable: false
---

# EF Core 非同步查詢模式

## 使用時機

當你需要：

- 在 Service 或 Repository 中操作 EF Core DbContext
- 查詢資料庫（單筆、列表、條件查詢）
- 新增、更新、刪除資料
- 避免 Deadlock 與效能問題

---

## 模式一：全面使用 async/await（禁止同步阻塞）

### ❌ 錯誤寫法（同步阻塞，造成 Deadlock 風險）

```csharp
public class ProductRepository(AppDbContext db) : IProductRepository
{
    public Product? GetById(Guid id)
        => db.Products.FirstOrDefault(p => p.Id == id);  // ❌ 同步，阻塞執行緒

    public void Save(Product product)
    {
        db.Products.Add(product);
        db.SaveChanges();  // ❌ 同步 SaveChanges
    }

    // ❌ 最危險的寫法：在 async 方法中用 .Result 阻塞
    public async Task<Product?> GetByIdAsync(Guid id)
    {
        return db.Products.FirstOrDefaultAsync(p => p.Id == id).Result;  // ❌ Deadlock!
    }
}
```

### ✅ 正確寫法（全面 async）

```csharp
/// <summary>商品 Repository，負責商品資料的 CRUD 操作</summary>
public class ProductRepository(AppDbContext db) : IProductRepository
{
    /// <summary>
    /// 根據 ID 取得商品（唯讀）。
    /// 使用範例：Product? p = await repo.GetByIdAsync(id, ct);
    /// </summary>
    public async Task<Product?> GetByIdAsync(Guid id, CancellationToken ct)
        => await db.Products
            .AsNoTracking()                    // 唯讀查詢加 AsNoTracking
            .FirstOrDefaultAsync(p => p.Id == id, ct);

    /// <summary>
    /// 新增商品至資料庫。
    /// 使用範例：await repo.AddAsync(product, ct);
    /// </summary>
    public async Task AddAsync(Product product, CancellationToken ct)
    {
        db.Products.Add(product);
        await db.SaveChangesAsync(ct);         // ✅ 非同步 SaveChanges
    }

    /// <summary>
    /// 取得所有商品列表（唯讀）。
    /// 使用範例：IReadOnlyList&lt;Product&gt; products = await repo.GetAllAsync(ct);
    /// </summary>
    public async Task<IReadOnlyList<Product>> GetAllAsync(CancellationToken ct)
        => await db.Products
            .AsNoTracking()
            .ToListAsync(ct);
}
```

---

## 模式二：AsNoTracking() 的使用時機

| 查詢用途 | 是否使用 AsNoTracking | 原因 |
|----------|----------------------|------|
| GET API（唯讀，不修改） | ✅ 使用 | 不需追蹤，減少記憶體與 CPU 開銷 |
| 準備更新的查詢 | ❌ 不用（或明確 AsTracking） | 需要追蹤變更 SaveChanges 才有效 |
| 列表顯示 | ✅ 使用 | 唯讀場景 |
| 刪除操作 | ❌ 需要追蹤或用 ExecuteDeleteAsync | 需要 EF 知道要刪哪一筆 |

### ✅ AsNoTracking 正確用法

```csharp
// ✅ 唯讀查詢一律加 AsNoTracking
IReadOnlyList<Product> products = await db.Products
    .AsNoTracking()
    .Where(p => p.IsActive)
    .ToListAsync(ct);

// ✅ 更新時使用 AsTracking（或不加 AsNoTracking）
Product? product = await db.Products
    .AsTracking()
    .FirstOrDefaultAsync(p => p.Id == id, ct);

if (product is not null)
{
    product.UpdatePrice(newPrice);
    await db.SaveChangesAsync(ct);  // ✅ 有追蹤，SaveChanges 才會偵測到變更
}
```

---

## 模式三：避免 N+1 查詢問題

### ❌ 錯誤寫法（N+1：每個 Order 額外查詢 Items）

```csharp
// ❌ 先查 Orders，再在迴圈中逐一查 Items → N+1 次資料庫查詢
IReadOnlyList<Order> orders = await db.Orders.AsNoTracking().ToListAsync(ct);
foreach (Order order in orders)
{
    // ❌ 每次迴圈都觸發一次資料庫查詢
    IList<OrderItem> items = order.Items.ToList();
}
```

### ✅ 正確寫法（使用 Include 預先載入）

```csharp
// ✅ 一次查詢取得所有需要的資料
IReadOnlyList<Order> orders = await db.Orders
    .AsNoTracking()
    .Include(o => o.Items)          // 預先載入 Items（一次 JOIN 或 Split Query）
    .Include(o => o.Customer)       // 預先載入 Customer
    .ToListAsync(ct);

// ✅ 多層 Include
IReadOnlyList<Order> orders = await db.Orders
    .AsNoTracking()
    .Include(o => o.Items)
        .ThenInclude(i => i.Product) // 二層關聯
    .ToListAsync(ct);
```

---

## 模式四：CancellationToken 傳遞

所有接受 `CancellationToken` 的方法都**必須**傳入，讓使用者取消請求時能中斷資料庫查詢。

### ❌ 錯誤寫法（未傳遞 CancellationToken）

```csharp
public async Task<IReadOnlyList<Product>> GetAllAsync(CancellationToken ct)
{
    // ❌ 沒有傳入 ct，使用者取消後資料庫查詢仍繼續執行
    return await db.Products.AsNoTracking().ToListAsync();
}
```

### ✅ 正確寫法

```csharp
/// <summary>
/// 取得所有商品。使用者取消請求時中止查詢。
/// 使用範例：IReadOnlyList&lt;Product&gt; list = await repo.GetAllAsync(ct);
/// </summary>
public async Task<IReadOnlyList<Product>> GetAllAsync(CancellationToken ct)
    => await db.Products
        .AsNoTracking()
        .ToListAsync(ct);  // ✅ 傳入 ct
```

---

## 模式五：大量操作使用 ExecuteUpdateAsync / ExecuteDeleteAsync

### ❌ 錯誤寫法（載入所有 Entity 再逐一更新，效能差）

```csharp
// ❌ 先載入所有過期商品再逐一更新
IList<Product> expiredProducts = await db.Products
    .Where(p => p.ExpiresAt < DateTimeOffset.UtcNow)
    .ToListAsync(ct);

foreach (Product p in expiredProducts)
{
    p.IsActive = false;
}
await db.SaveChangesAsync(ct);  // ❌ 每筆都要 EF 追蹤
```

### ✅ 正確寫法（單一 SQL UPDATE）

```csharp
// ✅ 直接在資料庫執行 UPDATE，不載入 Entity 至記憶體
await db.Products
    .Where(p => p.ExpiresAt < DateTimeOffset.UtcNow)
    .ExecuteUpdateAsync(
        sets => sets.SetProperty(p => p.IsActive, false),
        ct);

// ✅ 直接刪除，不載入
await db.Products
    .Where(p => p.IsActive == false && p.CreatedAt < cutoffDate)
    .ExecuteDeleteAsync(ct);
```

---

## 常見陷阱

### 1. 在 Singleton 中注入 Scoped DbContext

```csharp
// ❌ CacheService 是 Singleton，注入 Scoped DbContext 造成 Captive Dependency
public class CacheService(AppDbContext db) : ICacheService { ... } // ❌
services.AddSingleton<ICacheService, CacheService>(); // ❌ 生命週期錯誤

// ✅ 改用 IDbContextFactory
public class CacheService(IDbContextFactory<AppDbContext> dbFactory) : ICacheService
{
    public async Task RefreshAsync(CancellationToken ct)
    {
        await using AppDbContext db = await dbFactory.CreateDbContextAsync(ct);
        // ... 使用 db
    }
}
services.AddSingleton<ICacheService, CacheService>(); // ✅
```

### 2. Include 過度使用（載入不需要的資料）

```csharp
// ❌ 載入所有關聯，大量不必要的資料
IReadOnlyList<Order> orders = await db.Orders
    .Include(o => o.Items)
    .Include(o => o.Customer)
    .Include(o => o.Customer.Address)
    .Include(o => o.Customer.Orders)  // ❌ 迴圈關聯！
    .ToListAsync(ct);

// ✅ 只 Include 需要的欄位，使用 Select 投影
IReadOnlyList<OrderSummaryDto> summaries = await db.Orders
    .AsNoTracking()
    .Select(o => new OrderSummaryDto
    {
        Id = o.Id,
        CustomerName = o.Customer.Name,
        ItemCount = o.Items.Count
    })
    .ToListAsync(ct);
```

---

## 最佳實踐摘要

| 項目 | 規範 |
|------|------|
| 所有查詢方法 | 使用 `Async` 後綴（`FirstOrDefaultAsync`, `ToListAsync` 等） |
| `.Result` / `.Wait()` | **嚴格禁止**，會導致 Deadlock |
| 唯讀查詢 | 一律加 `AsNoTracking()` |
| `CancellationToken` | 所有 async 方法都傳入並轉發 |
| N+1 問題 | 使用 `Include()` 預先載入，或 `Select()` 投影 |
| 大量操作 | 使用 `ExecuteUpdateAsync()` / `ExecuteDeleteAsync()` |
| Singleton 中使用 DbContext | 改用 `IDbContextFactory<T>` |
