---
name: csharp-coding-standards
description: C# coding standards for .NET 8/10. Use explicit types instead of var. Use expression-body members (=>) for simple methods and properties. Apply Traditional Chinese XML summary to all class/struct/record fields and methods with usage examples. Follow C# naming conventions.
invocable: false
---

# C# 程式碼規範

## 使用時機

當你需要：

- 撰寫任何 C# 類別、方法、屬性（所有場景都適用）
- 確保 AI 產出的程式碼符合專案的程式碼風格
- 確保所有公開 API 有完整的 XML 文件

---

## 規範一：明確型別宣告（禁止溺用 var）

`var` 只在型別明顯時使用（如 `new` 右側、`foreach`），其餘情況使用明確型別。

### ❌ 錯誤寫法（難以閱讀，型別不明確）

```csharp
var product = await repository.GetByIdAsync(id, ct);
var products = await repository.GetAllAsync(ct);
var result = productService.CreateAsync(dto, ct);
var json = JsonSerializer.Serialize(dto);
```

### ✅ 正確寫法（型別明確，可讀性高）

```csharp
Product? product = await repository.GetByIdAsync(id, ct);
IReadOnlyList<Product> products = await repository.GetAllAsync(ct);
Result<ProductDto> result = await productService.CreateAsync(dto, ct);
string json = JsonSerializer.Serialize(dto);

// ✅ var 可接受的使用情境：new 右側型別明顯
Product product = new()
{
    Name = dto.Name,
    Price = dto.Price
};

// ✅ var 可接受的使用情境：foreach 的迭代變數
foreach (Product p in products) { ... }
```

---

## 規範二：Expression-body 成員（`=>`）

簡單的單行方法/屬性使用 `=>` 表達式，減少樣版程式碼。

### ❌ 錯誤寫法（冗長的方法主體）

```csharp
public class ProductService(IProductRepository repository) : IProductService
{
    public async Task<IReadOnlyList<ProductDto>> GetAllAsync(CancellationToken ct)
    {
        return await repository.GetAllAsync(ct);
    }

    public bool IsExpensive(decimal price)
    {
        return price > 1000;
    }

    private string FullName
    {
        get { return $"{FirstName} {LastName}"; }
    }
}
```

### ✅ 正確寫法（Expression-body 精簡）

```csharp
public class ProductService(IProductRepository repository) : IProductService
{
    /// <summary>
    /// 取得所有商品列表。
    /// 使用範例：IReadOnlyList&lt;ProductDto&gt; list = await service.GetAllAsync(ct);
    /// </summary>
    public async Task<IReadOnlyList<ProductDto>> GetAllAsync(CancellationToken ct)
        => await repository.GetAllAsync(ct);  // ✅ 單行回傳用 =>

    /// <summary>
    /// 判斷商品是否為高價商品（超過 1000 元）。
    /// 使用範例：if (service.IsExpensive(price)) { ... }
    /// </summary>
    public bool IsExpensive(decimal price) => price > 1000;  // ✅

    /// <summary>使用者全名（名字 + 姓氏）</summary>
    private string FullName => $"{FirstName} {LastName}";  // ✅ 屬性
}
```

---

## 規範三：XML 文件（class/struct/record 欄位必須有一列式 summary）

所有公開的 `class`、`struct`、`record` 的**每個欄位、屬性**都必須有一列式 `<summary>`。

### ❌ 錯誤寫法（缺少 XML summary）

```csharp
public class ProductDto
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public decimal Price { get; init; }
    public bool IsActive { get; init; }
}
```

### ✅ 正確寫法（每個欄位都有一列式 summary）

```csharp
/// <summary>商品資料傳輸物件</summary>
public class ProductDto
{
    /// <summary>商品唯一識別碼</summary>
    public Guid Id { get; init; }

    /// <summary>商品名稱</summary>
    public string Name { get; init; } = string.Empty;

    /// <summary>商品售價（含稅，新台幣）</summary>
    public decimal Price { get; init; }

    /// <summary>商品是否上架中</summary>
    public bool IsActive { get; init; }
}
```

---

## 規範四：方法必須有繁體中文 summary 與使用範例

所有公開/受保護方法都必須有繁體中文說明與使用範例。

### ✅ 正確格式

```csharp
/// <summary>
/// 根據商品 ID 取得商品詳情。
/// 使用範例：ProductDto? dto = await service.GetByIdAsync(productId, ct);
/// </summary>
/// <param name="id">商品的唯一識別碼（GUID 格式）</param>
/// <param name="ct">取消操作的 Token</param>
/// <returns>商品 DTO，若不存在則回傳 null</returns>
public async Task<ProductDto?> GetByIdAsync(Guid id, CancellationToken ct)
    => await MapToDtoAsync(await repository.GetByIdAsync(id, ct));
```

---

## 規範五：C# 命名規範

| 項目 | 命名規則 | 範例 |
|------|----------|------|
| 類別名稱 | PascalCase | `ProductService` |
| 介面名稱 | `I` + PascalCase | `IProductService` |
| 方法名稱 | PascalCase | `GetByIdAsync` |
| 屬性名稱 | PascalCase | `ProductName` |
| 區域變數 | camelCase | `productList` |
| 參數名稱 | camelCase | `cancellationToken` |
| 私有欄位 | `_` + camelCase | `_repository` |
| 常數 | PascalCase | `MaxRetryCount` |
| 列舉值 | PascalCase | `PaymentStatus.Completed` |
| 非同步方法 | `Async` 後綴 | `SaveChangesAsync` |

### ❌ 錯誤命名

```csharp
string user_name = "Andy";        // ❌ 底線命名法
int RETRY_COUNT = 3;              // ❌ 全大寫
void getProduct() { }             // ❌ camelCase 方法名
class productController { }       // ❌ camelCase 類別名
```

### ✅ 正確命名

```csharp
string userName = "Andy";         // ✅ camelCase 區域變數
const int MaxRetryCount = 3;      // ✅ PascalCase 常數
async Task<ProductDto> GetProductAsync() { }  // ✅
class ProductController { }       // ✅ PascalCase 類別
```

---

## 規範六：其他程式碼風格

```csharp
// ✅ 使用 string.Empty 而非 ""
string name = string.Empty;

// ✅ 使用 is null / is not null 而非 == null
if (product is null) return NotFound();
if (product is not null) ProcessProduct(product);

// ✅ 使用 nameof() 取得名稱字串
throw new ArgumentNullException(nameof(product));

// ✅ 範圍型別使用 readonly 集合介面
public IReadOnlyList<Product> GetAll() { ... }   // 不用 List<T>
public IReadOnlyDictionary<string, int> Map { get; }

// ✅ 使用 Pattern Matching
if (exception is InvalidOperationException { Message: var msg })
    return Conflict(msg);
```

---

## 最佳實踐摘要

| 規範 | 要求 |
|------|------|
| 型別宣告 | 使用明確型別，`var` 限於 `new` 右側或 `foreach` |
| 單行方法/屬性 | 使用 Expression-body (`=>`) |
| 所有欄位/屬性 | 一列式 `<summary>` XML 文件 |
| 所有公開方法 | `<summary>` 含繁體中文說明與使用範例 |
| 命名 camelCase | 區域變數、方法參數 |
| 命名 PascalCase | 類別、方法、屬性、常數 |
| null 比較 | `is null` / `is not null` |
