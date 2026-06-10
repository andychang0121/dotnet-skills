---
name: structured-logging
description: Structured logging best practices for .NET. Use message templates with named properties instead of string interpolation, apply high-performance [LoggerMessage] source generator, and enrich logs with BeginScope.
description_zh: 結構化日誌最佳實踐，包含具名範本、LoggerMessage 高效能日誌與日誌上下文 (Scope) 設計。
invocable: false
---

# .NET 結構化日誌最佳實踐

## 使用時機

當你需要：

- 於 .NET 應用程式中記錄日誌（Logging），特別是搭配 Seq、Elasticsearch、Application Insights 等日誌搜尋分析工具
- 提升高頻率日誌記錄的效能，避免過多的記憶體分配（Allocation）與裝箱（Boxing）開銷
- 在日誌中附加請求上下文（如 Correlation ID、User ID），以便於跨系統追蹤排障
- 制定團隊中統一的日誌輸出語意與命名格式

---

## 模式一：結構化日誌基礎（使用具名屬性）

記錄日誌時，**禁止使用字串插值（String Interpolation）**。必須使用**訊息範本（Message Template）與具名引數**，以利日誌系統提取屬性進行索引與搜尋。

### ❌ 錯誤寫法（字串插值，日誌系統無法索引屬性且造成記憶體分配）

```csharp
// ❌ 日誌系統（例如 Seq）只會收到一條死板的字串，無法針對 "userId" 進行精準篩選
// 此外，不論日誌等級（Log Level）是否啟用，都會無條件執行字串格式化與拼接，造成垃圾回收負擔
logger.LogInformation($"使用者 {userId} 在時間 {DateTime.UtcNow} 成功登入。");
```

### ✅ 正確寫法（訊息範本，保留結構化屬性）

```csharp
// ✅ 訊息範本中的 {UserId} 與 {LoginTime} 會被日誌系統提取為獨立屬性欄位
// 這代表您可以在分析工具中直接下查詢條件：UserId == "123"
// 且若該 Log Level 未啟用，則不會進行參數的字串格式化，避免無謂開銷
logger.LogInformation(
    "使用者 {UserId} 在時間 {LoginTime} 成功登入。", 
    userId, 
    DateTime.UtcNow);
```

---

## 模式二：使用 LoggerMessageAttribute 實現高效能日誌

在**高頻繁呼叫**的路徑（如迴圈、API 請求入口、資料庫查詢）中，應使用 .NET 6+ 推出的 **Source Generator `[LoggerMessage]`**。它能產生高度優化的強型別方法，完全避免 Boxing（裝箱）與參數陣列的記憶體分配。

### ❌ 錯誤寫法（高效能路徑中直接呼叫，造成 Boxing 分配）

```csharp
public class OrderService(ILogger<OrderService> logger)
{
    public void ProcessOrders(IEnumerable<Order> orders)
    {
        foreach (Order order in orders)
        {
            // ❌ 頻繁迴圈中直接呼叫，order.Id (Guid) 與 order.Amount (decimal) 會被裝箱為 object
            // 且底層會為參數建立新的 object[] 陣列，產生極大垃圾回收開銷
            logger.LogInformation("處理訂單 {OrderId}，金額：{Amount}", order.Id, order.Amount);
        }
    }
}
```

### ✅ 正確寫法（使用 [LoggerMessage] 進行 Source Generation）

```csharp
/// <summary>訂單處理服務</summary>
public partial class OrderService(ILogger<OrderService> logger)
{
    // ✅ 使用 partial 關鍵字，並宣告 static partial 強型別日誌方法
    // Source Generator 會自動在背景編譯出高效能、零分配的實作代碼
    [LoggerMessage(
        EventId = 1001,
        Level = LogLevel.Information,
        Message = "處理訂單 {OrderId}，金額：{Amount}")]
    private static partial void LogOrderProcessing(ILogger logger, Guid orderId, decimal amount);

    /// <summary>
    /// 批次處理訂單。
    /// 使用範例：service.ProcessOrders(orders);
    /// </summary>
    public void ProcessOrders(IEnumerable<Order> orders)
    {
        foreach (Order order in orders)
        {
            // ✅ 呼叫強型別 Source Generated 方法，效能極佳且零分配
            LogOrderProcessing(logger, order.Id, order.Amount);
        }
    }
}
```

---

## 模式三：日誌上下文擴充（Log Context & Scope）

當多個日誌方法需要共用相同的上下文（例如 API 的 CorrelationId、當前 User、或 TransactionId）時，應使用 `BeginScope` 或日誌框架的 LogContext，避免在每個 Log 呼叫中手動傳入參數。

### ❌ 錯誤寫法（手動且重複傳入上下文參數）

```csharp
// ❌ 程式碼混亂，每個 Log 方法都要重複傳入 correlationId
logger.LogInformation("開始處理交易 {TransactionId}，關聯號：{CorrelationId}", txId, correlationId);
await DoWorkAsync();
logger.LogInformation("交易處理完畢 {TransactionId}，關聯號：{CorrelationId}", txId, correlationId);
```

### ✅ 正確寫法（使用 ILogger.BeginScope 統一注入上下文）

```csharp
/// <summary>
/// 處理交易流程，日誌將自動帶上交易上下文資訊。
/// </summary>
public async Task ProcessTransactionAsync(Guid txId, string correlationId)
{
    // ✅ 建立一個日誌 Scope，在此 Scope 內產生的所有日誌，都會自動附帶這些屬性
    using (IDisposable? scope = logger.BeginScope(new Dictionary<string, object>
    {
        ["TransactionId"] = txId,
        ["CorrelationId"] = correlationId
    }))
    {
        logger.LogInformation("開始處理交易流程...");
        
        await DoWorkAsync(); // 此方法內部的任何 Log 也都會自動帶上上述兩個 ID
        
        logger.LogInformation("交易處理完成！");
    }
}
```

---

## 最佳實踐摘要

| 項目 | 規範 |
|------|------|
| 字串處理 | ❌ 禁止字串插值 (`$"{var}"`)，必須使用具名訊息範本 (`"{PropertyName}"`) |
| 命名規範 | 訊息範本屬性應使用 **PascalCase** 命名（如 `{UserId}`, `{OrderId}`） |
| 高效能路徑 | 頻繁迴圈或 API 入口，一律使用 **`[LoggerMessage]`** Source Generator |
| 日誌範圍 | 使用 **`ILogger.BeginScope`** 將關聯 ID (CorrelationId) 注入當前執行上下文 |
| 例外記錄 | 記錄 Exception 時，必須將 `exception` 物件作為第一個參數傳入，而非只記錄 `Message` |

### 💡 例外記錄範例：
```csharp
// ❌ 錯誤：這只會記錄 Exception Message，會遺失 StackTrace
logger.LogError("處理資料失敗：{Message}", ex.Message);

// ✅ 正確：傳入 Exception 物件，日誌框架會完整記錄型別、訊息與 StackTrace
logger.LogError(ex, "處理資料時發生未預期錯誤，訂單編號：{OrderId}", orderId);
```
