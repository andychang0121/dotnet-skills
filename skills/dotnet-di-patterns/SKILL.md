---
name: dotnet-di-patterns
description: ASP.NET Core dependency injection best practices. Understand Singleton/Scoped/Transient lifetimes. Avoid Captive Dependency (injecting Scoped into Singleton). Use .NET 8 Keyed Services. Always depend on interfaces, not implementations.
invocable: false
---

# DI 生命週期與注入模式

## 使用時機

當你需要：

- 在 Program.cs 注冊服務
- 判斷服務要用哪種生命週期
- 避免 Captive Dependency 錯誤
- 使用 .NET 8 的 Keyed Services 功能

---

## 模式一：三種生命週期的使用場景

| 生命週期 | 建立時機 | 釋放時機 | 使用場景 |
|----------|----------|----------|----------|
| `Singleton` | 應用程式啟動時（第一次請求時建立） | 應用程式結束 | 無狀態服務、設定快取、重量級初始化 |
| `Scoped` | 每次 HTTP 請求 | 請求結束 | 業務邏輯 Service、DbContext、Repository |
| `Transient` | 每次注入時 | 使用完立即 | 輕量無狀態工具、Builder |

### ✅ 正確使用範例

```csharp
/// <summary>服務注冊擴充方法，依生命週期分類清楚登記</summary>
public static class ServiceExtensions
{
    /// <summary>
    /// 注冊所有業務服務，依照正確生命週期分類。
    /// 使用範例：builder.Services.AddApplicationServices();
    /// </summary>
    public static IServiceCollection AddApplicationServices(
        this IServiceCollection services) =>
        services
            // ✅ Scoped：每次 HTTP 請求一個新實例
            .AddScoped<IProductService, ProductService>()
            .AddScoped<IOrderService, OrderService>()
            .AddScoped<IUserService, UserService>()

            // ✅ Singleton：整個應用程式共用一個實例
            .AddSingleton<ICacheService, MemoryCacheService>()
            .AddSingleton<IConfigurationReader, ConfigurationReader>()

            // ✅ Transient：每次注入都建立新實例
            .AddTransient<IEmailComposer, EmailComposer>();
}
```

---

## 模式二：Captive Dependency（最常見錯誤）

當生命週期較長的服務（Singleton）注入生命週期較短的服務（Scoped）時，Scoped 服務會被「捕捉」存活到應用程式結束，造成資料狀態污染。

### ❌ 錯誤寫法（Singleton 注入 Scoped → Captive Dependency）

```csharp
// ❌ Scoped Service 被 Singleton 捕捉
public class ReportCacheService(IReportService reportService) : IReportCacheService
{
    // reportService 是 Scoped，但 ReportCacheService 是 Singleton
    // reportService 不會在請求結束時釋放！
}

services.AddSingleton<IReportCacheService, ReportCacheService>(); // ❌
services.AddScoped<IReportService, ReportService>();
```

### ✅ 正確寫法（改用 IServiceProvider 動態取得）

```csharp
/// <summary>報表快取服務（Singleton），需要動態取得 Scoped 服務</summary>
public class ReportCacheService(IServiceProvider serviceProvider) : IReportCacheService
{
    /// <summary>
    /// 刷新快取（在請求範圍內取得 Scoped Service）。
    /// 使用範例：await cacheService.RefreshAsync(ct);
    /// </summary>
    public async Task RefreshAsync(CancellationToken ct)
    {
        // ✅ 在 Singleton 中透過建立 Scope 取得 Scoped 服務
        await using AsyncServiceScope scope = serviceProvider.CreateAsyncScope();
        IReportService reportService = scope.ServiceProvider
            .GetRequiredService<IReportService>();

        await reportService.GenerateAsync(ct);
    }
}

services.AddSingleton<IReportCacheService, ReportCacheService>(); // ✅
```

---

## 模式三：.NET 8 Keyed Services

當同一個介面有多個實作，且需要根據名稱取得不同實作時，使用 Keyed Services。

### ✅ 使用範例（多種支付服務）

```csharp
// 注冊：用字串 key 區分不同實作
services.AddKeyedScoped<IPaymentService, CreditCardPaymentService>("credit-card");
services.AddKeyedScoped<IPaymentService, LinePayService>("line-pay");
services.AddKeyedScoped<IPaymentService, CashPaymentService>("cash");

// 注入：透過 [FromKeyedServices] Attribute 指定 key
/// <summary>結帳服務，根據支付方式動態選擇支付提供者</summary>
public class CheckoutService(
    [FromKeyedServices("line-pay")] IPaymentService linePayService,
    IOrderRepository orderRepository) : ICheckoutService
{
    // ...
}

// 或透過 IKeyedServiceProvider 動態取得（key 在執行時才確定）
/// <summary>動態選擇支付服務</summary>
public class PaymentRouter(IServiceProvider serviceProvider) : IPaymentRouter
{
    /// <summary>
    /// 根據支付方式名稱取得對應的支付服務。
    /// 使用範例：IPaymentService service = router.GetService("line-pay");
    /// </summary>
    public IPaymentService GetService(string paymentMethod)
        => serviceProvider.GetRequiredKeyedService<IPaymentService>(paymentMethod);
}
```

---

## 模式四：介面優先原則

### ❌ 錯誤寫法（依賴具體實作）

```csharp
// ❌ 直接注入具體類別，無法替換（無法測試、無法切換實作）
public class OrderService(SqlProductRepository repository) { ... }
services.AddScoped<SqlProductRepository>(); // ❌
```

### ✅ 正確寫法（依賴介面）

```csharp
// ✅ 永遠依賴介面，實作可自由切換
public class OrderService(IProductRepository repository) { ... }
services.AddScoped<IProductRepository, SqlProductRepository>(); // ✅
// 測試時替換：services.AddScoped<IProductRepository, FakeProductRepository>();
```

---

## 常見陷阱

### 1. DbContext 注冊為 Singleton

```csharp
// ❌ DbContext 必須是 Scoped，不能是 Singleton
services.AddSingleton<AppDbContext>(); // ❌ 多個請求共用同一個 context，造成狀態混亂

// ✅
services.AddDbContext<AppDbContext>(options => ...); // AddDbContext 預設是 Scoped
```

### 2. Transient 中注入 Scoped

```csharp
// ❌ 這在 .NET 中通常也是問題（取決於使用情境）
services.AddTransient<IMyService, MyService>();
// 如果 MyService 注入了 Scoped 服務，在非 Scoped 環境下會報錯
```

---

## 最佳實踐摘要

| 服務類型 | 建議生命週期 | 原因 |
|----------|------------|------|
| Service（業務邏輯） | Scoped | 隨請求建立，避免狀態共用 |
| Repository | Scoped | 與 DbContext 同生命週期 |
| DbContext | Scoped（預設） | AddDbContext 自動設定 |
| 快取服務（無狀態） | Singleton | 整個應用共用 |
| 設定讀取（無狀態） | Singleton | 只讀，可共用 |
| 輕量工具 | Transient | 快速建立，不需共用 |
| **禁止** | Singleton 注入 Scoped | Captive Dependency，資料污染 |
