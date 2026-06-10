---
name: fluent-validation-patterns
description: Designing clean request validation using FluentValidation, automatic dependency injection registration, and standardized error responses.
description_zh: 使用 FluentValidation 進行強型別請求驗證、自動註冊與 ProblemDetails 整合的實作規範。
invocable: false
---

# FluentValidation 驗證最佳實踐

## 使用時機（When to Use）
本技能適用於在 ASP.NET Core 專案中處理傳入請求（如 DTO、Command、Query）之資料驗證的場景。相較於將驗證規則與資料結構混在一起的 Data Annotations (屬性標記)，**FluentValidation** 提供了一種關注點分離 (Separation of Concerns) 的強型別且具高度擴充性的驗證架構。

## 核心模式

### ✅ 正確範例
* **關注點分離**：將驗證邏輯獨立寫在繼承 `AbstractValidator<T>` 的驗證器類別中。
* **強型別規則鏈**：利用 Fluent API（如 `.NotEmpty()`, `.MinimumLength()`, `.Matches()`）鏈結驗證條件。
* **自訂錯誤訊息**：使用 `.WithMessage()` 提供明確的錯誤說明，並使用預留字（如 `{PropertyName}`）以防重複命名。
* **XML 文件規範**：類別與欄位必須符合繁體中文 XML 文件註解要求。

```csharp
using System;
using FluentValidation;

namespace DotNetSkills.Validation.Patterns;

/// <summary>
/// 建立產品請求的資料傳輸物件 (DTO)
/// </summary>
public record CreateProductRequest(string Name, decimal Price, string Sku);

/// <summary>
/// 針對建立產品請求 (CreateProductRequest) 的驗證器
/// </summary>
public class CreateProductRequestValidator : AbstractValidator<CreateProductRequest>
{
    /// <summary>
    /// 初始化驗證器並設定規則
    /// </summary>
    public CreateProductRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("產品名稱為必填項目。")
            .MaximumLength(100).WithMessage("產品名稱長度不可超過 {MaxLength} 個字元。");

        RuleFor(x => x.Price)
            .GreaterThan(0).WithMessage("產品價格必須大於 0。");

        RuleFor(x => x.Sku)
            .NotEmpty().WithMessage("SKU 編號為必填項目。")
            .Matches(@"^[A-Z]{3}-\d{4}$").WithMessage("SKU 格式不正確，應符合 'AAA-0000' 的規範。");
    }
}
```

### ❌ 錯誤反例
* 在 DTO/Record 中混用 DataAnnotations，導致資料結構類別變得臃腫且不易單元測試。
* 或者直接在 Controller/Service 中撰寫繁雜的 `if-else` 程序式邏輯來驗證參數。

```csharp
using System;
using System.ComponentModel.DataAnnotations;

namespace DotNetSkills.Validation.Patterns;

// 錯誤 1: 在單純的 DTO 結構中耦合大量驗證與 UI 格式字串
public class BadCreateProductRequest
{
    [Required(ErrorMessage = "Name is required")]
    [MaxLength(100, ErrorMessage = "Too long")]
    public string Name { get; set; } = string.Empty;

    [Range(0.01, double.MaxValue, ErrorMessage = "Price must be > 0")]
    public decimal Price { get; set; }

    [Required]
    public string Sku { get; set; } = string.Empty;
}
```

## 常見陷阱（Common Pitfalls）
1. **阻斷式驗證（FAIL-FAST）未開啟**：預設情況下，FluentValidation 會檢查所有屬性的所有規則。若某屬性第一個驗證失敗便不需往後驗證（例如，信箱為空就不需再驗證信箱格式），可使用 `Cascade(CascadeMode.Stop)` 或 `.Cascade(CascadeMode.Stop)` 來開啟阻斷。
2. **在驗證器內執行耗時的 DB 查詢**：雖然 FluentValidation 支援透過 `.MustAsync()` 去資料庫確認欄位是否重複（如 Email 是否被註冊），但應避免在此寫入過於複雜或耗時的業務邏輯。此類資料庫檢驗應簡化，或保留在 Application Service 中處理。
3. **未搭配 DI 自動註冊**：若漏了在 `Program.cs` 註冊驗證器，驗證將不會生效。建議使用 `builder.Services.AddValidatorsFromAssemblyContaining<T>()` 來整批自動註冊。

## 最佳實踐摘要
* DTO 與驗證規則必須徹底分離，禁止在 DTO 中使用 DataAnnotations 進行欄位約束。
* 驗證器類別必須繼承自 `AbstractValidator<T>`，並透過主建構子或建構子宣告規則。
* 每個驗證器及重要的自訂驗證規則方法，皆必須撰寫繁體中文說明。
* 所有回傳至客戶端的驗證錯誤訊息必須使用繁體中文，且資訊應具體、明確。
* 簡單的常數驗證優先使用 Expression，複雜規則應獨立拉出為 Private Method。
