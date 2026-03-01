---
name: dotnet-options-pattern
description: Configure ASP.NET Core settings using IOptions<T>, IOptionsMonitor<T>, and IOptionsSnapshot<T>. Know when to use each variant. Bind configuration sections to strongly-typed classes. Avoid magic strings in configuration access.
invocable: false
---

# IOptions\<T\> 設定注入模式

## 使用時機

當你需要：

- 將 `appsettings.json` 的設定綁定到強型別類別
- 避免 `configuration["Section:Key"]` 魔術字串
- 在 Singleton 或 Scoped 服務中讀取設定
- 在執行期間動態讀取設定變更

---

## 三種 IOptions 的差異

| 介面 | 生命週期 | 設定變更感知 | 適用場景 |
|------|----------|------------|----------|
| `IOptions<T>` | Singleton | ❌ 不感知 | 設定不會變更（JWT Secret、連線字串） |
| `IOptionsSnapshot<T>` | Scoped | ✅ 每次請求重新讀取 | 每次請求需要最新設定 |
| `IOptionsMonitor<T>` | Singleton | ✅ 即時感知並通知 | Singleton 中需要即時更新的設定 |

---

## 模式一：定義強型別設定類別

```csharp
namespace 專案名稱.Application.Options;

/// <summary>JWT 驗證設定</summary>
public class JwtOptions
{
    /// <summary>設定區段名稱（用於 appsettings.json 對應）</summary>
    public const string SectionName = "Jwt";

    /// <summary>JWT 簽署金鑰</summary>
    public string SecretKey { get; init; } = string.Empty;

    /// <summary>JWT 發行者</summary>
    public string Issuer { get; init; } = string.Empty;

    /// <summary>JWT 受眾</summary>
    public string Audience { get; init; } = string.Empty;

    /// <summary>Token 過期時間（分鐘）</summary>
    public int ExpiryMinutes { get; init; } = 60;
}

/// <summary>快取設定</summary>
public class CacheOptions
{
    /// <summary>設定區段名稱</summary>
    public const string SectionName = "Cache";

    /// <summary>預設快取時間（秒）</summary>
    public int DefaultExpirySeconds { get; init; } = 300;

    /// <summary>是否啟用快取</summary>
    public bool IsEnabled { get; init; } = true;
}
```

---

## 模式二：在 Program.cs 注冊設定綁定

### ✅ 正確寫法

```csharp
// appsettings.json
// {
//   "Jwt": { "SecretKey": "...", "Issuer": "...", "ExpiryMinutes": 60 },
//   "Cache": { "DefaultExpirySeconds": 300, "IsEnabled": true }
// }

/// <summary>
/// 注冊所有設定選項綁定。
/// 使用範例：builder.Services.AddOptionsConfiguration(configuration);
/// </summary>
public static IServiceCollection AddOptionsConfiguration(
    this IServiceCollection services,
    IConfiguration configuration) =>
    services
        .Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName))
        .Configure<CacheOptions>(configuration.GetSection(CacheOptions.SectionName));
```

---

## 模式三：各介面的使用情境

### ✅ IOptions\<T\>（靜態設定，Singleton 適用）

```csharp
/// <summary>JWT 產生服務（Singleton），設定不會在執行期間變更</summary>
public class JwtProvider(IOptions<JwtOptions> options) : IJwtProvider
{
    // ✅ IOptions<T> 適合 Singleton，因為 JWT Secret 不會在執行中變更
    private readonly JwtOptions _jwtOptions = options.Value;

    /// <summary>
    /// 根據使用者資訊產生 JWT Token。
    /// 使用範例：string token = jwtProvider.Generate(user);
    /// </summary>
    public string Generate(AppUser user)
    {
        // 使用 _jwtOptions.SecretKey、_jwtOptions.Issuer 等
        ...
    }
}
```

### ✅ IOptionsSnapshot\<T\>（每次請求重新讀取，Scoped 適用）

```csharp
/// <summary>商品服務（Scoped），需要在每次請求讀取最新快取設定</summary>
public class ProductService(
    IProductRepository repository,
    IOptionsSnapshot<CacheOptions> cacheOptions) : IProductService
{
    // ✅ IOptionsSnapshot 是 Scoped，每次請求取得最新設定值
    // 適合開發期間動態調整設定而不必重啟應用程式

    /// <summary>
    /// 取得商品列表，依設定決定是否使用快取。
    /// 使用範例：IReadOnlyList&lt;ProductDto&gt; list = await service.GetAllAsync(ct);
    /// </summary>
    public async Task<IReadOnlyList<ProductDto>> GetAllAsync(CancellationToken ct)
    {
        CacheOptions options = cacheOptions.Value; // 每次請求都是最新值

        if (!options.IsEnabled)
            return await FetchFromDbAsync(ct);

        return await FetchFromCacheOrDbAsync(options.DefaultExpirySeconds, ct);
    }
}
```

### ✅ IOptionsMonitor\<T\>（即時通知，Singleton 適用）

```csharp
/// <summary>快取背景服務（Singleton），需要即時感知設定變更</summary>
public class CacheBackgroundService(
    IOptionsMonitor<CacheOptions> cacheMonitor,
    ILogger<CacheBackgroundService> logger) : BackgroundService
{
    // ✅ IOptionsMonitor 適合在 Singleton 中監聽設定變更
    private CacheOptions _currentOptions = cacheMonitor.CurrentValue;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // 監聽設定變更，即時更新本地快取
        cacheMonitor.OnChange(options =>
        {
            _currentOptions = options;
            logger.LogInformation("快取設定已更新，新的過期時間：{Seconds} 秒",
                options.DefaultExpirySeconds);
        });

        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(TimeSpan.FromSeconds(_currentOptions.DefaultExpirySeconds),
                stoppingToken);
        }
    }
}
```

---

## 常見陷阱

### 1. 直接注入 IConfiguration（魔術字串）

```csharp
// ❌ 魔術字串，拼錯不會有編譯錯誤
public class JwtService(IConfiguration config)
{
    private readonly string _secret = config["Jwt:SecretKey"] ?? "";  // ❌
}

// ✅ 強型別，重構安全
public class JwtService(IOptions<JwtOptions> options)
{
    private readonly string _secret = options.Value.SecretKey;  // ✅
}
```

### 2. 在 Singleton 中使用 IOptionsSnapshot

```csharp
// ❌ IOptionsSnapshot 是 Scoped，不能注入進 Singleton
public class MySingletonService(IOptionsSnapshot<MyOptions> options) { ... }  // ❌
services.AddSingleton<MySingletonService>();  // 執行時報錯

// ✅ Singleton 中使用 IOptionsMonitor
public class MySingletonService(IOptionsMonitor<MyOptions> monitor) { ... }
```

---

## 最佳實踐摘要

| 使用場景 | 選擇 |
|----------|------|
| Singleton 服務，設定固定 | `IOptions<T>` |
| Scoped 服務，需要每次請求最新值 | `IOptionsSnapshot<T>` |
| Singleton 服務，需即時感知設定變更 | `IOptionsMonitor<T>` |
| 存取設定 | 永遠使用強型別類別，禁止魔術字串 |
