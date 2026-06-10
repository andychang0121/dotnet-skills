---
name: efcore-performance
description: EF Core performance optimization techniques, including AsNoTracking, split queries, and high-performance batch operations.
description_zh: Entity Framework Core 效能調優，包含 AsNoTracking、拆分查詢與批次更新/刪除。
invocable: false
---

# EF Core 效能調優最佳實踐

## 使用時機（When to Use）
本技能適用於在 .NET 應用程式中使用 Entity Framework Core (EF Core) 進行資料庫存取時，需要調優查詢速度、優化記憶體使用率、或處理大量資料批次更新與刪除的場景。

## 核心模式

### ✅ 正確範例
* **唯讀查詢優化**：主動在 LINQ 鏈結中加上 `.AsNoTracking()`，阻斷變更追蹤 (Change Tracker) 以大幅減少記憶體分配與 CPU 開銷。
* **避免笛卡爾積爆炸**：針對一對多 (1:N) 的多重關聯預先載入，使用 `.AsSplitQuery()` 將大 SQL 拆分為多個小 SQL 執行。
* **高效批次操作**：使用 `ExecuteUpdateAsync` 或 `ExecuteDeleteAsync` 來直接在資料庫端執行批次更新/刪除，避開傳統「查出來 ➜ 改物件 ➜ SaveChanges」的超低效率模式。
* **XML 文件規範**：所有儲存庫層方法、擴充查詢方法均配有繁體中文文件。

```csharp
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace DotNetSkills.EfCore.Performance;

/// <summary>
/// 產品倉儲 (ProductRepository) 的實作類別
/// </summary>
public class ProductRepository
{
    private readonly AppDbContext _context;

    /// <summary>
    /// 初始化產品倉儲
    /// </summary>
    public ProductRepository(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// 取得上架產品清單（唯讀查詢範例）
    /// </summary>
    /// <returns>產品唯讀列表</returns>
    public async Task<List<ProductDto>> GetActiveProductsAsync()
    {
        // 使用 AsNoTracking 提升查詢速度並節省記憶體
        return await _context.Products
            .AsNoTracking()
            .Where(x => x.IsActive)
            .Select(x => new ProductDto(x.Id, x.Name, x.Price))
            .ToListAsync();
    }

    /// <summary>
    /// 取得產品及其關聯的標籤與圖片（拆分查詢範例）
    /// </summary>
    /// <param name="productId">產品識別碼</param>
    /// <returns>產品詳細資料（含關聯）</returns>
    public async Task<Product?> GetProductDetailsAsync(Guid productId)
    {
        // 使用 AsSplitQuery 避免關聯加載造成的笛卡爾積爆炸
        return await _context.Products
            .Include(x => x.Tags)
            .Include(x => x.Images)
            .AsSplitQuery()
            .FirstOrDefaultAsync(x => x.Id == productId);
    }

    /// <summary>
    /// 將指定分類下的所有產品降價（批次更新範例，.NET 7+ 支援）
    /// </summary>
    /// <param name="categoryId">分類識別碼</param>
    /// <param name="discount">折扣比率 (如 0.9 代表打九折)</param>
    /// <returns>受影響的資料筆數</returns>
    public async Task<int> ApplyCategoryDiscountAsync(Guid categoryId, decimal discount)
    {
        // 直接在資料庫端執行批次更新，不需要載入記憶體與 SaveChanges
        return await _context.Products
            .Where(x => x.CategoryId == categoryId && x.IsActive)
            .ExecuteUpdateAsync(s => s.SetProperty(p => p.Price, p => p.Price * discount));
    }
}
```

### ❌ 錯誤反例
* 執行純展示的資料列表查詢時，未使用 `AsNoTracking()`，造成大記憶體開銷。
* 使用巢狀迴圈去查詢相關聯的多個子資料表，導致 N+1 查詢問題。
* 利用 `foreach` 逐條載入並修改實體，最後呼叫 `SaveChanges()`，在高筆數（如萬筆）下效能會極度低落。

```csharp
using System;
using System.Linq;
using System.Threading.Tasks;

namespace DotNetSkills.EfCore.Performance;

public class BadRepository
{
    private readonly AppDbContext _context;

    public BadRepository(AppDbContext context)
    {
        _context = context;
    }

    // 錯誤 1: 缺少 XML 註解與中文說明
    // 錯誤 2: 純讀取卻使用 Tracking 查詢
    // 錯誤 3: 傳統的 foreach 修改 + SaveChanges，在大數據量下會非常緩慢
    public async Task InactivateAllProducts(Guid categoryId)
    {
        var products = _context.Products
            .Where(x => x.CategoryId == categoryId)
            .ToList(); // 載入記憶體

        foreach (var p in products)
        {
            p.IsActive = false;
        }

        await _context.SaveChangesAsync(); // 產生一堆單條 UPDATE 語句
    }
}
```

## 常見陷阱（Common Pitfalls）
1. **N+1 查詢問題**：在 `foreach` 迴圈中，去存取延遲載入 (Lazy Loading) 的導覽屬性，導致 EF Core 產生數百次額外的資料庫連線與查詢。**解決方法**：一律使用 `Include` 進行積極載入 (Eager Loading) 或在 LINQ 中直接 `Select` 投影成 DTO。
2. **在記憶體中執行資料庫篩選**：無意間在 LINQ 中提早呼叫了 `.ToList()` 或 `.AsEnumerable()`，導致資料庫將數百萬條資料拉回本機記憶體，才在記憶體中做 `Where` 篩選。**解決方法**：務必確保 `.Where()` 等篩選方法是在 `.ToListAsync()` 之前呼叫，維持 `IQueryable` 的延遲執行特性。
3. **主鍵值與複合鍵未建索引**：對於經常作為 `Where`、`Join` 或 `OrderBy` 的欄位（如 `CreatedTime`, `UserId`），沒有在 `DbContext` 內設定索引 (`HasIndex()`)，導致資料庫每次都執行全表掃描 (Table Scan)。

## 最佳實踐摘要
* 唯讀查詢操作一律標註 `.AsNoTracking()`。
* 當 `Include` 大於兩個一對多 (1:N) 的導覽屬性時，應主動加上 `.AsSplitQuery()` 拆分查詢。
* 批次更新與刪除，請優先使用 `ExecuteUpdateAsync` 與 `ExecuteDeleteAsync`。
* LINQ 篩選動作必須在 `IQueryable` 階段完成，禁止提前呼叫 `ToList` 或 `AsEnumerable` 到本機進行記憶體端過濾。
* 複雜的 LINQ 方法或需要調優的 Store Procedure 叫用，必須撰寫繁體中文註解。
