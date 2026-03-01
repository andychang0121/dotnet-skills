---
name: csharp-result-pattern
description: Use Result<T> pattern instead of throwing exceptions for business logic errors in ASP.NET Core. Use exceptions only for truly unexpected system errors. Provides Success/Failure factory methods and clean Controller unwrapping.
invocable: false
---

# Result\<T\> 業務錯誤處理模式

## 使用時機

當你需要：

- 在 Service 層回傳業務邏輯執行結果（成功/失敗）
- 避免用 Exception 控制預期的業務流程
- 在 Controller 層優雅地解包 Result 並轉換為 HTTP 回應

---

## Result 型別定義

```csharp
namespace 專案名稱.Domain.Primitives;

/// <summary>代表操作的錯誤資訊</summary>
public record Error
{
    /// <summary>錯誤代碼（用於程式判斷）</summary>
    public string Code { get; init; } = string.Empty;

    /// <summary>錯誤說明（顯示給使用者）</summary>
    public string Message { get; init; } = string.Empty;

    /// <summary>
    /// 建立錯誤實例。
    /// 使用範例：Error error = new("DUPLICATE_NAME", "商品名稱已存在");
    /// </summary>
    public Error(string code, string message)
    {
        Code = code;
        Message = message;
    }
}

/// <summary>不含回傳值的操作結果（成功/失敗）</summary>
public class Result
{
    /// <summary>操作是否成功</summary>
    public bool IsSuccess { get; }

    /// <summary>操作是否失敗</summary>
    public bool IsFailure => !IsSuccess;

    /// <summary>失敗時的錯誤資訊（成功時為 null）</summary>
    public Error? Error { get; }

    private Result(bool isSuccess, Error? error)
    {
        IsSuccess = isSuccess;
        Error = error;
    }

    /// <summary>
    /// 建立成功結果。
    /// 使用範例：return Result.Success();
    /// </summary>
    public static Result Success() => new(true, null);

    /// <summary>
    /// 建立失敗結果。
    /// 使用範例：return Result.Failure(new Error("CODE", "說明"));
    /// </summary>
    public static Result Failure(Error error) => new(false, error);
}

/// <summary>含回傳值的操作結果</summary>
/// <typeparam name="TValue">成功時回傳的資料型別</typeparam>
public class Result<TValue>
{
    /// <summary>操作是否成功</summary>
    public bool IsSuccess { get; }

    /// <summary>操作是否失敗</summary>
    public bool IsFailure => !IsSuccess;

    /// <summary>成功時的回傳值（失敗時為 default）</summary>
    public TValue? Value { get; }

    /// <summary>失敗時的錯誤資訊（成功時為 null）</summary>
    public Error? Error { get; }

    private Result(bool isSuccess, TValue? value, Error? error)
    {
        IsSuccess = isSuccess;
        Value = value;
        Error = error;
    }

    /// <summary>
    /// 建立帶有值的成功結果。
    /// 使用範例：return Result&lt;ProductDto&gt;.Success(dto);
    /// </summary>
    public static Result<TValue> Success(TValue value) => new(true, value, null);

    /// <summary>
    /// 建立失敗結果。
    /// 使用範例：return Result&lt;ProductDto&gt;.Failure(new Error("NOT_FOUND", "商品不存在"));
    /// </summary>
    public static Result<TValue> Failure(Error error) => new(false, default, error);
}
```

---

## 模式一：Service 層使用 Result

### ❌ 錯誤寫法（用 Exception 傳遞業務錯誤）

```csharp
public class ProductService(IProductRepository repository) : IProductService
{
    public async Task<ProductDto> CreateAsync(CreateProductDto dto, CancellationToken ct)
    {
        // ❌ 用 Exception 控制業務流程，昂貴且不語意
        if (await repository.ExistsByNameAsync(dto.Name, ct))
            throw new InvalidOperationException("商品名稱已存在");

        if (dto.Price <= 0)
            throw new ArgumentException("價格必須大於零");

        Product product = new() { Name = dto.Name, Price = dto.Price };
        await repository.AddAsync(product, ct);
        return MapToDto(product);
    }
}
```

### ✅ 正確寫法（Result 傳遞業務結果）

```csharp
/// <summary>商品業務邏輯服務</summary>
public class ProductService(IProductRepository repository) : IProductService
{
    /// <summary>
    /// 建立新商品，回傳操作結果。
    /// 使用範例：Result&lt;ProductDto&gt; result = await service.CreateAsync(dto, ct);
    /// </summary>
    public async Task<Result<ProductDto>> CreateAsync(
        CreateProductDto dto,
        CancellationToken ct)
    {
        // ✅ 使用 Result 傳遞可預期的業務錯誤
        if (await repository.ExistsByNameAsync(dto.Name, ct))
            return Result<ProductDto>.Failure(
                new Error("DUPLICATE_NAME", "商品名稱已存在"));

        if (dto.Price <= 0)
            return Result<ProductDto>.Failure(
                new Error("INVALID_PRICE", "價格必須大於零"));

        Product product = new() { Name = dto.Name, Price = dto.Price };
        await repository.AddAsync(product, ct);

        return Result<ProductDto>.Success(MapToDto(product));
    }

    /// <summary>
    /// 將 Product Entity 轉換為 DTO。
    /// 使用範例：ProductDto dto = MapToDto(product);
    /// </summary>
    private static ProductDto MapToDto(Product entity) => new()
    {
        Id = entity.Id,
        Name = entity.Name,
        Price = entity.Price
    };
}
```

---

## 模式二：Controller 層解包 Result

### ✅ 使用 switch expression 解包

```csharp
/// <summary>商品 Controller，使用 Result 模式處理業務結果</summary>
[ApiController]
[Route("api/[controller]")]
public class ProductController(IProductService productService) : ControllerBase
{
    /// <summary>
    /// 建立商品並回傳對應 HTTP 回應。
    /// 使用範例：POST /api/product
    /// </summary>
    [HttpPost]
    [ProducesResponseType<ProductDto>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> CreateAsync(
        [FromBody] CreateProductDto dto,
        CancellationToken ct)
    {
        Result<ProductDto> result = await productService.CreateAsync(dto, ct);

        // ✅ 根據錯誤代碼轉換為對應 HTTP 狀態碼
        if (result.IsSuccess)
            return CreatedAtAction(nameof(GetAsync), new { id = result.Value!.Id }, result.Value);

        return result.Error!.Code switch
        {
            "DUPLICATE_NAME" => Conflict(result.Error.Message),
            "INVALID_PRICE"  => BadRequest(result.Error.Message),
            _                => BadRequest(result.Error.Message)
        };
    }
}
```

---

## 模式三：何時仍使用 Exception

Exception 保留給**真正意外**的情況（程式設計錯誤、系統異常），**不用於控制業務流程**：

```csharp
// ✅ 使用 Exception 的場景：
// 1. 程式設計錯誤（違反前置條件）
ArgumentNullException.ThrowIfNull(dto);

// 2. 系統層級錯誤（資料庫連線失敗、檔案不存在等）
// → 讓全域 IExceptionHandler 捕捉並回傳 RFC 9457 格式

// 3. 基礎設施問題（網路逾時等）
// → 同上，不應在業務層捕捉

// ❌ 不應使用 Exception 的場景：
throw new NotFoundException("商品不存在");     // ❌ 這是預期的業務情境
throw new ValidationException("格式錯誤");    // ❌ 應用 Result 傳遞
throw new DuplicateException("名稱重複");     // ❌ 應用 Result 傳遞
```

---

## 最佳實踐摘要

| 場景 | 工具 |
|------|------|
| 可預期的業務錯誤（驗證失敗、資源不存在、重複） | `Result<T>.Failure(error)` |
| 操作成功有回傳值 | `Result<T>.Success(value)` |
| 操作成功無回傳值 | `Result.Success()` |
| 系統異常（資料庫、網路） | 讓 `Exception` 向上傳遞至全域 Handler |
| 程式設計違誤（null 參數） | `ArgumentNullException.ThrowIfNull()` 等 Guard |
