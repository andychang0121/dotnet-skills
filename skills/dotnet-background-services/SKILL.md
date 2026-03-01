---
name: dotnet-background-services
description: Implement background tasks in ASP.NET Core using BackgroundService or IHostedService. Correctly handle CancellationToken for graceful shutdown. Avoid blocking in ExecuteAsync. Use IDbContextFactory for database access in background services.
invocable: false
---

# BackgroundService 背景服務模式

## 使用時機

當你需要：

- 定期執行背景工作（排程、清理、同步）
- 監聽佇列或事件（Queue Consumer）
- 在應用程式生命週期中持續運行的服務

---

## 模式一：BackgroundService 的正確取消模式

### ❌ 錯誤寫法（未處理 CancellationToken，服務無法優雅關閉）

```csharp
public class DataSyncService(ILogger<DataSyncService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (true)  // ❌ 永遠不會停止
        {
            logger.LogInformation("同步資料...");
            await Task.Delay(TimeSpan.FromMinutes(5));  // ❌ 未傳入 stoppingToken
        }
    }
}
```

### ✅ 正確寫法（正確的取消處理）

```csharp
/// <summary>資料同步背景服務，每 5 分鐘執行一次同步</summary>
public class DataSyncService(
    ILogger<DataSyncService> logger,
    IServiceProvider serviceProvider) : BackgroundService
{
    /// <summary>
    /// 背景服務主迴圈，應用程式關閉時透過 stoppingToken 通知停止。
    /// 使用範例：自動由 ASP.NET Core 主機管理啟動與停止。
    /// </summary>
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("DataSyncService 已啟動");

        // ✅ 使用 stoppingToken 判斷是否需要停止
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await SyncDataAsync(stoppingToken);
            }
            catch (OperationCanceledException)
            {
                // ✅ 正常取消，不視為錯誤
                logger.LogInformation("DataSyncService 收到取消通知");
                break;
            }
            catch (Exception ex)
            {
                // ✅ 記錄錯誤但不讓服務崩潰，等待下次執行
                logger.LogError(ex, "同步資料時發生錯誤");
            }

            // ✅ 傳入 stoppingToken，應用程式關閉時立即中斷等待
            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
        }

        logger.LogInformation("DataSyncService 已停止");
    }

    /// <summary>
    /// 執行一次資料同步操作。
    /// 使用範例：await SyncDataAsync(cancellationToken);
    /// </summary>
    private async Task SyncDataAsync(CancellationToken ct)
    {
        // ✅ 在 BackgroundService 中使用 IDbContextFactory 建立 Scoped DbContext
        await using AsyncServiceScope scope = serviceProvider.CreateAsyncScope();
        ISyncRepository syncRepo = scope.ServiceProvider
            .GetRequiredService<ISyncRepository>();

        await syncRepo.SyncAsync(ct);
    }
}
```

---

## 模式二：在背景服務使用 DbContext

`BackgroundService` 是 **Singleton**，不能直接注入 Scoped 的 `DbContext`。

### ❌ 錯誤寫法（直接注入 Scoped DbContext）

```csharp
// ❌ BackgroundService 是 Singleton，注入 Scoped DbContext → Captive Dependency
public class CleanupService(AppDbContext db) : BackgroundService { ... }
```

### ✅ 正確寫法（使用 IServiceProvider 建立 Scope）

```csharp
/// <summary>定期清理過期資料的背景服務</summary>
public class CleanupService(
    IServiceProvider serviceProvider,
    ILogger<CleanupService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await CleanupExpiredDataAsync(stoppingToken);
            await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
        }
    }

    /// <summary>
    /// 在新 Scope 中執行資料清理，確保 DbContext 生命週期正確。
    /// 使用範例：await CleanupExpiredDataAsync(ct);
    /// </summary>
    private async Task CleanupExpiredDataAsync(CancellationToken ct)
    {
        // ✅ 每次執行建立新的 Scope，DbContext 在 using 結束時正確釋放
        await using AsyncServiceScope scope = serviceProvider.CreateAsyncScope();
        AppDbContext db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        int deleted = await db.Products
            .Where(p => p.ExpiresAt < DateTimeOffset.UtcNow)
            .ExecuteDeleteAsync(ct);

        logger.LogInformation("已清除 {Count} 筆過期商品", deleted);
    }
}
```

---

## 模式三：IHostedService 的使用時機

當需要精確控制啟動/停止行為（如資料庫 Migration、一次性初始化）時，使用 `IHostedService`：

```csharp
/// <summary>應用程式啟動時執行資料庫 Migration 的 Hosted Service</summary>
public class DatabaseMigrationService(
    IServiceProvider serviceProvider,
    ILogger<DatabaseMigrationService> logger) : IHostedService
{
    /// <summary>
    /// 應用程式啟動時執行，完成後即停止。
    /// 使用範例：由 ASP.NET Core 主機自動呼叫。
    /// </summary>
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        logger.LogInformation("執行資料庫 Migration...");

        await using AsyncServiceScope scope = serviceProvider.CreateAsyncScope();
        AppDbContext db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        await db.Database.MigrateAsync(cancellationToken);

        logger.LogInformation("資料庫 Migration 完成");
    }

    /// <summary>應用程式停止時呼叫（一次性服務無需額外處理）</summary>
    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}
```

---

## 模式四：注冊背景服務

```csharp
/// <summary>
/// 注冊所有背景服務。
/// 使用範例：builder.Services.AddBackgroundServices();
/// </summary>
public static IServiceCollection AddBackgroundServices(
    this IServiceCollection services) =>
    services
        .AddHostedService<DataSyncService>()          // ✅ 定期背景服務
        .AddHostedService<CleanupService>()           // ✅ 定期清理
        .AddHostedService<DatabaseMigrationService>(); // ✅ 啟動一次性初始化
```

---

## 常見陷阱

### 1. ExecuteAsync 拋出未捕捉例外導致服務靜默停止

```csharp
// ❌ 未捕捉例外，服務靜默停止（不會重啟）
protected override async Task ExecuteAsync(CancellationToken stoppingToken)
{
    while (!stoppingToken.IsCancellationRequested)
    {
        ProcessData();  // ❌ 若這裡拋出例外，整個 ExecuteAsync 中止
        await Task.Delay(1000, stoppingToken);
    }
}

// ✅ 捕捉例外並記錄，讓服務繼續運行
protected override async Task ExecuteAsync(CancellationToken stoppingToken)
{
    while (!stoppingToken.IsCancellationRequested)
    {
        try { ProcessData(); }
        catch (Exception ex) { logger.LogError(ex, "處理失敗"); }
        await Task.Delay(1000, stoppingToken);
    }
}
```

---

## 最佳實踐摘要

| 項目 | 規範 |
|------|------|
| 取消處理 | 所有 `Task.Delay` 和非同步呼叫都傳入 `stoppingToken` |
| `OperationCanceledException` | 正常取消，不記錄為錯誤 |
| DbContext 存取 | 透過 `IServiceProvider.CreateAsyncScope()` 建立 Scoped DbContext |
| 例外處理 | 捕捉並記錄例外，讓服務繼續運行（不要讓服務靜默停止） |
| 一次性初始化 | 使用 `IHostedService` 而非 `BackgroundService` |
