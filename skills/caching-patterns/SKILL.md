---
name: caching-patterns
description: Implementing local and distributed caching strategies, using HybridCache (.NET 9), Cache-Aside, and race condition prevention.
description_zh: 實作記憶體快取、分散式快取與防擊穿鎖定的快取策略指南。
invocable: false
---

# 快取策略與快取控制最佳實踐

## 使用時機（When to Use）
本技能適用於 .NET 應用程式中需要對高頻率讀取、低頻率修改的資料進行效能調優的場景。涵蓋使用 `IMemoryCache` (本地記憶體快取)、`IDistributedCache` (如 Redis 分散式快取)，以及 .NET 9 起提供的 `HybridCache` 解決方案。

## 核心模式

### ✅ 正確範例（具併發防護的 Cache-Aside 模式）
* **防護機制**：在高併發環境下，使用 `SemaphoreSlim` 鎖定機制（或鎖），確保只有第一個請求穿透到資料庫，避免「快取擊穿 (Cache Stampede)」。
* **合理的快取效期**：設定 `AbsoluteExpirationRelativeToNow` (絕對過期) 與 `SlidingExpiration` (滑動過期)。
* **XML 文件規範**：所有類別、欄位與快取包裝方法均包含繁體中文摘要。

```csharp
using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Memory;

namespace DotNetSkills.Caching.Patterns;

/// <summary>
/// 產品資料快取裝飾服務
/// </summary>
public class CachedProductService
{
    private readonly IProductService _innerService;
    private readonly IMemoryCache _memoryCache;
    private readonly SemaphoreSlim _lock = new SemaphoreSlim(1, 1);

    /// <summary>
    /// 初始化快取產品服務
    /// </summary>
    public CachedProductService(IProductService innerService, IMemoryCache memoryCache)
    {
        _innerService = innerService;
        _memoryCache = memoryCache;
    }

    /// <summary>
    /// 取得產品詳細資料，若快取未命中則自資料庫載入
    /// </summary>
    /// <param name="productId">產品唯一識別碼</param>
    /// <returns>產品資訊 DTO</returns>
    public async Task<ProductDto?> GetProductByIdAsync(Guid productId)
    {
        string cacheKey = $"product:{productId}";

        // 1. 嘗試從快取讀取
        if (_memoryCache.TryGetValue(cacheKey, out ProductDto? cachedProduct))
        {
            return cachedProduct;
        }

        // 2. 未命中，使用信號量鎖定，防止大量請求同時穿透資料庫
        await _lock.WaitAsync();
        try
        {
            // 雙重檢查 (Double Check Lock)
            if (_memoryCache.TryGetValue(cacheKey, out cachedProduct))
            {
                return cachedProduct;
            }

            // 從實際資料來源載入
            cachedProduct = await _innerService.GetByIdAsync(productId);

            if (cachedProduct is not null)
            {
                // 設定快取項目與到期時間
                MemoryCacheEntryOptions cacheOptions = new MemoryCacheEntryOptions()
                    .SetAbsoluteExpiration(TimeSpan.FromMinutes(10))
                    .SetSlidingExpiration(TimeSpan.FromMinutes(2));

                _memoryCache.Set(cacheKey, cachedProduct, cacheOptions);
            }

            return cachedProduct;
        }
        finally
        {
            _lock.Release();
        }
    }
}
```

### ❌ 錯誤反例
* 未實作任何併發鎖，直接在 `if (cache == null)` 條件下存取資料庫，這在尖峰流量下會導致「快取擊穿」，使資料庫瞬間崩潰。
* 漏掉過期機制，導致資料一旦快取便永久不變，造成資料不一致。

```csharp
using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Memory;

namespace DotNetSkills.Caching.Patterns;

public class BadCachedService
{
    private readonly IProductService _service;
    private readonly IMemoryCache _cache;

    public BadCachedService(IProductService service, IMemoryCache cache)
    {
        _service = service;
        _cache = cache;
    }

    // 錯誤 1: 缺少 XML 註解與中文說明
    // 錯誤 2: 無併發控制鎖，高流量下會造成資料庫擊穿
    // 錯誤 3: 缺少過期設定，容易導致資料髒讀 (Stale Data)
    public async Task<ProductDto> GetProduct(Guid id)
    {
        var key = "prod_" + id.ToString();
        if (!_cache.TryGetValue(key, out ProductDto dto))
        {
            dto = await _service.GetByIdAsync(id);
            _cache.Set(key, dto); // 未設定 Expire
        }
        return dto;
    }
}
```

## 常見陷阱（Common Pitfalls）
1. **快取雪崩 (Cache Avalanche)**：如果大量快取項目的過期時間設定完全一致，一旦到期時間同時到達，資料庫在短時間內會因承受巨大壓力而停擺。**解決方法**：設定快取過期時間時，在基礎時間上加上隨機的分鐘/秒數（微幅抖動）。
2. **大物件快取記憶體失控**：直接將大型 DataTable 或過多原始資料快取在 IMemoryCache 中，極易引發記憶體不足 (OutOfMemoryException) 與垃圾收集 (GC) 的頻繁回收。**解決方法**：只快取最小化、必要的 DTO 模型，或改用分散式快取分擔本機記憶體。
3. **無效序列化開銷**：在使用 `IDistributedCache` 時，對每個讀寫操作手動寫重複的 JSON 序列化與還原代碼。**解決方法**：將其封裝成強型別的泛型擴充方法，或升級使用 .NET 9 的 `HybridCache`。

## 最佳實踐摘要
* 本地快取 (`IMemoryCache`) 讀取必須搭配 `SemaphoreSlim` 處理雙重檢查鎖，以確保快取擊穿防護。
* 所有快取寫入皆必須明確配置 `AbsoluteExpiration` (絕對過期)，不可設定永久快取。
* 重要的方法與擴充類別必須標註繁體中文註解與摘要。
* 分散式快取鍵值 (Cache Key) 命名應具備明確的 Namespace 前綴與分隔符號（如 `tenant:user:info:123`）。
* 在支援 .NET 9+ 的新專案中，優先考慮採用微軟原生的 `HybridCache` 作為快取標準。
