---
name: aspnetcore-program-cs-extensions
description: Organize ASP.NET Core Program.cs using IServiceCollection and IApplicationBuilder extension methods. Avoid bloated Program.cs by grouping service registrations into layered AddXxx() and UseXxx() methods. Follow middleware pipeline ordering.
invocable: false
---

# Program.cs Extension Method 分層整理

## 使用時機

當你需要：

- 整理 Program.cs 的服務注冊與 Middleware 設定
- 各層（Application、Infrastructure、API）自行管理自己的服務注冊
- 確保 Middleware 的執行順序正確

---

## 模式一：分層 Extension Method

### ❌ 錯誤寫法（所有注冊都放在 Program.cs）

```csharp
WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

// ❌ Program.cs 膨脹，難以維護
builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => { ... });
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IProductRepository, SqlProductRepository>();
builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseSqlServer(builder.Configuration.GetConnectionString("Default")));
builder.Services.AddMemoryCache();
builder.Services.AddScoped<ICacheService, MemoryCacheService>();
// ... 數十行繼續 ...
```

### ✅ 正確寫法（各層自行管理，Program.cs 保持精簡）

```csharp
// Program.cs（只有呼叫，不含細節）
WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddOptionsConfiguration(builder.Configuration)  // 設定選項
    .AddApplicationServices()                         // Application 層服務
    .AddInfrastructureServices()                      // Infrastructure 層服務
    .AddApiServices(builder.Configuration);           // API 層服務（Controller、Auth、Swagger）

WebApplication app = builder.Build();
app.UseApiMiddleware();  // Middleware 管線設定
app.Run();
```

---

## 模式二：各層的 Extension Method 實作

### Application 層（Application/Services/ServiceExtensions.cs）

```csharp
namespace 專案名稱.Application.Services;

/// <summary>Application 層服務注冊擴充方法集合</summary>
public static class ServiceExtensions
{
    /// <summary>
    /// 注冊所有 Application 層的業務邏輯服務。
    /// 使用範例：builder.Services.AddApplicationServices();
    /// </summary>
    public static IServiceCollection AddApplicationServices(
        this IServiceCollection services) =>
        services
            .AddScoped<IProductService, ProductService>()
            .AddScoped<IOrderService, OrderService>()
            .AddScoped<IUserService, UserService>();
}
```

### Infrastructure 層（Infrastructure/Extensions/InfrastructureExtensions.cs）

```csharp
namespace 專案名稱.Infrastructure.Extensions;

/// <summary>Infrastructure 層服務注冊擴充方法集合</summary>
public static class InfrastructureExtensions
{
    /// <summary>
    /// 注冊所有 Infrastructure 層服務（DbContext、Repository、外部服務）。
    /// 使用範例：builder.Services.AddInfrastructureServices();
    /// </summary>
    public static IServiceCollection AddInfrastructureServices(
        this IServiceCollection services) =>
        services
            .AddScoped<IProductRepository, SqlProductRepository>()
            .AddScoped<IOrderRepository, SqlOrderRepository>()
            .AddScoped<ICacheService, MemoryCacheService>()
            .AddMemoryCache();
}
```

### API 層（Api/Infrastructure/Extensions/ApiServiceExtensions.cs）

```csharp
namespace 專案名稱.Api.Infrastructure.Extensions;

/// <summary>API 層服務注冊擴充方法集合</summary>
public static class ApiServiceExtensions
{
    /// <summary>
    /// 注冊所有 API 層服務（Controller、Swagger、驗證、CORS 等）。
    /// 使用範例：builder.Services.AddApiServices(configuration);
    /// </summary>
    public static IServiceCollection AddApiServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services
            .AddControllers()
            .AddJsonOptions(options =>
            {
                // 保持 camelCase 命名
                options.JsonSerializerOptions.PropertyNamingPolicy =
                    JsonNamingPolicy.CamelCase;
            });

        services
            .AddOpenApi()
            .AddAuthentication(configuration)
            .AddCors(configuration);

        return services;
    }

    /// <summary>
    /// 注冊所有設定選項（IOptions 綁定）。
    /// 使用範例：builder.Services.AddOptionsConfiguration(configuration);
    /// </summary>
    public static IServiceCollection AddOptionsConfiguration(
        this IServiceCollection services,
        IConfiguration configuration) =>
        services
            .Configure<JwtOptions>(configuration.GetSection("Jwt"))
            .Configure<DatabaseOptions>(configuration.GetSection("Database"))
            .Configure<CacheOptions>(configuration.GetSection("Cache"));
}
```

---

## 模式三：Middleware 管線（正確執行順序）

### ❌ 錯誤寫法（順序錯誤導致驗證失效）

```csharp
app.UseAuthorization();   // ❌ 必須在 UseAuthentication 之後
app.UseAuthentication();  // ❌
app.UseRouting();         // ❌ 必須在最前面
```

### ✅ 正確寫法（標準 ASP.NET Core Middleware 順序）

```csharp
namespace 專案名稱.Api.Infrastructure.Extensions;

/// <summary>API Middleware 管線設定擴充方法</summary>
public static class MiddlewareExtensions
{
    /// <summary>
    /// 設定 HTTP 請求管線（Middleware 順序至關重要）。
    /// 使用範例：app.UseApiMiddleware();
    /// </summary>
    public static WebApplication UseApiMiddleware(this WebApplication app)
    {
        // 1. 例外處理（最外層，捕捉所有例外）
        app.UseExceptionHandler();           // 配合 IExceptionHandler

        // 2. HTTPS 重導向
        if (!app.Environment.IsDevelopment())
        {
            app.UseHsts();
        }
        app.UseHttpsRedirection();

        // 3. 靜態檔案（若有）
        app.UseStaticFiles();

        // 4. 路由
        app.UseRouting();

        // 5. CORS（必須在 Auth 之前）
        app.UseCors();

        // 6. 驗證（Authentication 必須在 Authorization 之前）
        app.UseAuthentication();
        app.UseAuthorization();

        // 7. Swagger（僅開發環境）
        if (app.Environment.IsDevelopment())
        {
            app.MapOpenApi();
        }

        // 8. 對應 Controller
        app.MapControllers();

        return app;
    }
}
```

---

## 模式四：WebApplicationBuilder Extension

針對 Kestrel、Serilog 等 `builder` 層級的設定：

```csharp
namespace 專案名稱.Api.Infrastructure.Extensions;

/// <summary>WebApplicationBuilder 擴充方法集合</summary>
public static class BuilderExtensions
{
    /// <summary>
    /// 設定 Kestrel 安全性（移除 Server 標頭）。
    /// 使用範例：builder.ConfigureKestrel();
    /// </summary>
    public static WebApplicationBuilder ConfigureKestrel(
        this WebApplicationBuilder builder)
    {
        builder.WebHost.ConfigureKestrel(options =>
        {
            // 移除 Server 回應標頭，避免洩漏伺服器資訊
            options.AddServerHeader = false;
        });

        return builder;
    }

    /// <summary>
    /// 設定 Serilog 結構化日誌。
    /// 使用範例：builder.AddConfigureSerilog();
    /// </summary>
    public static WebApplicationBuilder AddConfigureSerilog(
        this WebApplicationBuilder builder)
    {
        builder.Host.UseSerilog((context, config) =>
            config.ReadFrom.Configuration(context.Configuration));

        return builder;
    }
}
```

---

## 常見陷阱

### 1. Extension Method 命名不一致

```csharp
// ❌ 不一致的命名
services.RegisterApplicationServices();  // ❌
services.SetupDatabase();               // ❌
services.InitializeCors();              // ❌

// ✅ 一致的 Add/Use 慣例
services.AddApplicationServices();
services.AddDatabaseServices();
services.AddCorsPolicy();
```

### 2. 跨層的 Extension Method 放錯地方

```csharp
// ❌ Infrastructure Extension Method 放在 Api 層
namespace 專案名稱.Api.Extensions;
public static class DbExtensions  // ❌ 應在 Infrastructure 層
{
    public static IServiceCollection AddDatabase(...) { ... }
}
```

---

## 最佳實踐摘要

| 項目 | 規範 |
|------|------|
| Program.cs | 只呼叫 Extension Method，不包含實作細節 |
| 命名 | 服務用 `AddXxx()`，Middleware 用 `UseXxx()`，WebApplicationBuilder 用 `AddXxx()` / `ConfigureXxx()` |
| 位置 | Extension Method 放在對應的架構層（Application/Infrastructure/Api） |
| Middleware 順序 | 例外處理 → HTTPS → 靜態 → 路由 → CORS → 認證 → 授權 → Controller |
