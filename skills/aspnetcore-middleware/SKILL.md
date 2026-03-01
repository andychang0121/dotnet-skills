---
name: aspnetcore-middleware
description: Create custom ASP.NET Core middleware using IMiddleware interface, convention-based approach, or lambda. Implement global exception handling with IExceptionHandler (.NET 8+) and RFC 9457 ProblemDetails format. Understand middleware pipeline ordering.
invocable: false
---

# 自定義 Middleware 與全域例外處理

## 使用時機

當你需要：

- 建立跨切面的 HTTP 請求處理邏輯（日誌、驗證、效能計量）
- 實作全域例外攔截並統一回應格式
- 了解 Middleware 管線的執行順序

---

## 模式一：三種 Middleware 寫法

### ✅ 方式一：IMiddleware 介面（推薦，支援 DI 注入）

```csharp
namespace 專案名稱.Api.Infrastructure.Middleware;

/// <summary>記錄每個 HTTP 請求的執行時間的 Middleware</summary>
public class RequestTimingMiddleware(ILogger<RequestTimingMiddleware> logger) : IMiddleware
{
    /// <summary>
    /// 攔截 HTTP 請求，計算並記錄執行時間。
    /// 使用範例：app.UseMiddleware&lt;RequestTimingMiddleware&gt;();
    /// </summary>
    public async Task InvokeAsync(HttpContext context, RequestDelegate next)
    {
        Stopwatch stopwatch = Stopwatch.StartNew();

        // ✅ 呼叫管線中的下一個 Middleware
        await next(context);

        stopwatch.Stop();
        logger.LogInformation(
            "{Method} {Path} 執行時間：{ElapsedMs} ms",
            context.Request.Method,
            context.Request.Path,
            stopwatch.ElapsedMilliseconds);
    }
}

// 注冊（IMiddleware 需要在 DI 容器中注冊）
services.AddScoped<RequestTimingMiddleware>();
app.UseMiddleware<RequestTimingMiddleware>();
```

### ✅ 方式二：Convention-based（簡單場景）

```csharp
/// <summary>基於慣例的 Middleware（無需繼承介面）</summary>
public class CorrelationIdMiddleware(RequestDelegate next)
{
    /// <summary>
    /// 為每個請求附加 Correlation ID，用於日誌追蹤。
    /// 使用範例：app.UseMiddleware&lt;CorrelationIdMiddleware&gt;();
    /// </summary>
    public async Task InvokeAsync(HttpContext context)
    {
        string correlationId = context.Request.Headers["X-Correlation-Id"].FirstOrDefault()
            ?? Guid.NewGuid().ToString();

        context.Response.Headers.Append("X-Correlation-Id", correlationId);
        context.Items["CorrelationId"] = correlationId;

        await next(context);
    }
}
```

### ✅ 方式三：Lambda（簡單一次性使用）

```csharp
// 直接在 Program.cs 中定義輕量 Middleware
app.Use(async (context, next) =>
{
    // 在請求前執行
    context.Response.Headers.Append("X-Powered-By", "dotnet-skills");
    await next();
    // 在請求後執行（回應已寫入後不能修改 Headers）
});
```

---

## 模式二：短路（Short-circuit）Middleware

```csharp
/// <summary>API Key 驗證 Middleware（失敗時短路，不繼續處理）</summary>
public class ApiKeyMiddleware(
    IOptions<ApiKeyOptions> options,
    ILogger<ApiKeyMiddleware> logger) : IMiddleware
{
    /// <summary>
    /// 驗證請求的 API Key，失敗時短路回傳 401。
    /// 使用範例：app.UseMiddleware&lt;ApiKeyMiddleware&gt;();
    /// </summary>
    public async Task InvokeAsync(HttpContext context, RequestDelegate next)
    {
        // 跳過健康檢查路由
        if (context.Request.Path.StartsWithSegments("/health"))
        {
            await next(context);
            return;
        }

        string? apiKey = context.Request.Headers["X-Api-Key"].FirstOrDefault();

        if (string.IsNullOrEmpty(apiKey) || apiKey != options.Value.ValidKey)
        {
            logger.LogWarning("無效的 API Key，來源：{IP}", context.Connection.RemoteIpAddress);

            // ✅ 短路：直接回傳，不呼叫 next()
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsJsonAsync(new ProblemDetails
            {
                Type = "https://httpstatuses.io/401",
                Title = "未授權",
                Detail = "API Key 無效或未提供",
                Status = StatusCodes.Status401Unauthorized,
                Instance = context.Request.Path
            });
            return;
        }

        await next(context);
    }
}
```

---

## 模式三：全域例外處理（RFC 9457，.NET 8 IExceptionHandler）

### ❌ 錯誤寫法（舊式 try-catch，格式不一致）

```csharp
// ❌ 舊式做法，每個 Controller 都要 try-catch
[HttpGet("{id:guid}")]
public async Task<IActionResult> GetAsync(Guid id)
{
    try { ... }
    catch (Exception ex)
    {
        return StatusCode(500, ex.Message);  // ❌ 格式不統一，洩漏細節
    }
}
```

### ✅ 正確寫法（IExceptionHandler + RFC 9457）

```csharp
namespace 專案名稱.Api.Infrastructure.Middleware;

/// <summary>全域例外處理，統一回應格式遵循 RFC 9457</summary>
public class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    /// <summary>
    /// 攔截未處理的例外，轉換為 RFC 9457 ProblemDetails 格式。
    /// 使用範例：在 Program.cs 中加入 app.UseExceptionHandler() 自動觸發。
    /// </summary>
    public async ValueTask<bool> TryHandleAsync(
        HttpContext context,
        Exception exception,
        CancellationToken cancellationToken)
    {
        // 根據例外類型決定 HTTP 狀態碼
        (int statusCode, string title) = exception switch
        {
            ArgumentNullException     => (StatusCodes.Status400BadRequest, "請求參數錯誤"),
            UnauthorizedAccessException => (StatusCodes.Status401Unauthorized, "未授權存取"),
            KeyNotFoundException       => (StatusCodes.Status404NotFound, "資源不存在"),
            InvalidOperationException  => (StatusCodes.Status409Conflict, "操作衝突"),
            _                          => (StatusCodes.Status500InternalServerError, "伺服器內部錯誤")
        };

        logger.LogError(exception,
            "例外攔截 [{StatusCode}] {Title}: {Message}",
            statusCode, title, exception.Message);

        // ✅ RFC 9457 標準格式
        ProblemDetails problem = new()
        {
            Type = $"https://httpstatuses.io/{statusCode}",
            Title = title,
            Detail = exception.Message,
            Status = statusCode,
            Instance = context.Request.Path
        };

        context.Response.StatusCode = statusCode;
        await context.Response.WriteAsJsonAsync(problem, cancellationToken);

        return true;  // true = 例外已處理，不繼續傳播
    }
}

// Program.cs 設定（IExceptionHandler 需要以下兩行）
services.AddExceptionHandler<GlobalExceptionHandler>();
services.AddProblemDetails();
app.UseExceptionHandler();  // 啟用全域例外處理 Middleware
```

---

## 常見陷阱

### 1. 在例外 Handler 之後修改 Response

```csharp
// ❌ Response 開始寫出後無法修改 Headers
public async Task InvokeAsync(HttpContext context, RequestDelegate next)
{
    await next(context);
    // ❌ 這裡 Response 可能已經開始寫出，修改 Headers 無效
    context.Response.Headers.Append("X-Something", "value");
}

// ✅ 使用 OnStarting callback
context.Response.OnStarting(() =>
{
    context.Response.Headers.Append("X-Something", "value");
    return Task.CompletedTask;
});
```

---

## 最佳實踐摘要

| 項目 | 規範 |
|------|------|
| 需要 DI 注入 | 使用 `IMiddleware` 介面 |
| 簡單場景 | Convention-based 或 Lambda |
| 全域例外 | 使用 `IExceptionHandler`（.NET 8+），遵循 RFC 9457 |
| 短路 | 不呼叫 `next()`，直接設定 Response |
| Middleware 順序 | 必須在 `UseAuthentication` 之前處理 CORS，例外處理放最外層 |
