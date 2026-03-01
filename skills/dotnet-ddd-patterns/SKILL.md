---
name: dotnet-ddd-patterns
description: Domain-Driven Design patterns for ASP.NET Core REST APIs. Implement Entity, Value Object, Aggregate Root, Domain Service, and Repository pattern. Integrate DDD with Clean Architecture. Keep domain logic inside domain objects, not services.
invocable: false
---

# DDD 領域驅動設計模式

## 使用時機

當你需要：

- 建立複雜業務領域的模型
- 避免貧血型領域模型（Anemic Domain Model）
- 決定業務規則要放在哪個類別
- 設計 Repository 介面

---

## 核心概念速覽

| 概念 | 說明 | 範例 |
|------|------|------|
| Entity | 有唯一識別碼的物件，以 ID 判斷相等性 | `Product`、`Order`、`User` |
| Value Object | 無 ID、以值判斷相等性、不可變 | `Money`、`Email`、`Address` |
| Aggregate | 一組 Entity 的一致性邊界 | `Order`（含 `OrderItem`） |
| Aggregate Root | Aggregate 的唯一入口 | `Order`（而非 `OrderItem`） |
| Domain Service | 跨 Entity 的業務邏輯（無狀態） | `PricingService`（計算含稅金額） |
| Repository | 持久化介面（Domain 定義，Infrastructure 實作） | `IOrderRepository` |

---

## 模式一：Entity 基底類別

```csharp
namespace 專案名稱.Domain.Primitives;

/// <summary>領域實體基底類別，以唯一識別碼判斷相等性</summary>
/// <typeparam name="TId">識別碼型別</typeparam>
public abstract class Entity<TId> : IEquatable<Entity<TId>>
    where TId : notnull
{
    /// <summary>實體唯一識別碼</summary>
    public TId Id { get; protected init; } = default!;

    /// <summary>
    /// 判斷兩個實體是否相等（以 Id 比較）。
    /// 使用範例：bool isSame = product1.Equals(product2);
    /// </summary>
    public bool Equals(Entity<TId>? other)
    {
        if (other is null) return false;
        if (ReferenceEquals(this, other)) return true;
        return Id.Equals(other.Id);
    }

    /// <inheritdoc/>
    public override bool Equals(object? obj) => Equals(obj as Entity<TId>);

    /// <inheritdoc/>
    public override int GetHashCode() => Id.GetHashCode();
}

// ✅ 具體 Entity 使用 Strongly-Typed ID
/// <summary>商品識別碼（強型別，避免 Guid 混用）</summary>
public readonly record struct ProductId(Guid Value)
{
    /// <summary>
    /// 建立新的商品識別碼。
    /// 使用範例：ProductId id = ProductId.New();
    /// </summary>
    public static ProductId New() => new(Guid.NewGuid());
}
```

---

## 模式二：Value Object

Value Object 是**不可變**的，以**值**判斷相等性（而非 ID）。

```csharp
namespace 專案名稱.Domain.ValueObjects;

/// <summary>金額 Value Object（不可變，包含數值與貨幣）</summary>
public sealed record Money
{
    /// <summary>金額數值（必須大於等於 0）</summary>
    public decimal Amount { get; }

    /// <summary>貨幣代碼（ISO 4217，如 TWD、USD）</summary>
    public string Currency { get; }

    private Money(decimal amount, string currency)
    {
        Amount = amount;
        Currency = currency;
    }

    /// <summary>
    /// 建立金額 Value Object。
    /// 使用範例：Money price = Money.Create(100m, "TWD");
    /// </summary>
    public static Result<Money> Create(decimal amount, string currency)
    {
        if (amount < 0)
            return Result<Money>.Failure(new Error("INVALID_AMOUNT", "金額不能為負數"));

        if (string.IsNullOrWhiteSpace(currency))
            return Result<Money>.Failure(new Error("INVALID_CURRENCY", "貨幣代碼不能為空"));

        return Result<Money>.Success(new Money(amount, currency));
    }

    /// <summary>
    /// 加法（僅限相同貨幣）。
    /// 使用範例：Money total = price.Add(tax);
    /// </summary>
    public Result<Money> Add(Money other)
    {
        if (Currency != other.Currency)
            return Result<Money>.Failure(
                new Error("CURRENCY_MISMATCH", $"無法加總不同貨幣：{Currency} + {other.Currency}"));

        return Result<Money>.Success(new Money(Amount + other.Amount, Currency));
    }
}

/// <summary>Email Value Object</summary>
public sealed record Email
{
    /// <summary>Email 地址字串</summary>
    public string Value { get; }

    private Email(string value) => Value = value;

    /// <summary>
    /// 建立 Email Value Object，驗證格式。
    /// 使用範例：Result&lt;Email&gt; email = Email.Create("user@example.com");
    /// </summary>
    public static Result<Email> Create(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return Result<Email>.Failure(new Error("INVALID_EMAIL", "Email 不能為空"));

        if (!value.Contains('@'))
            return Result<Email>.Failure(new Error("INVALID_EMAIL", "Email 格式不正確"));

        return Result<Email>.Success(new Email(value.ToLowerInvariant()));
    }
}
```

---

## 模式三：Aggregate 與 Aggregate Root

Aggregate 是**強一致性邊界**，外部只能透過 Aggregate Root 來操作內部物件。

```csharp
namespace 專案名稱.Domain.Orders;

/// <summary>訂單聚合根（Aggregate Root）</summary>
public class Order : Entity<OrderId>
{
    private readonly List<OrderItem> _items = [];

    /// <summary>訂單建立時間</summary>
    public DateTimeOffset CreatedAt { get; private set; }

    /// <summary>訂單狀態</summary>
    public OrderStatus Status { get; private set; }

    /// <summary>訂單明細（唯讀，外部不得直接修改）</summary>
    public IReadOnlyList<OrderItem> Items => _items.AsReadOnly();

    /// <summary>訂單總金額</summary>
    public Money TotalAmount => _items.Aggregate(
        Money.Create(0, "TWD").Value!,
        (sum, item) => sum.Add(item.SubTotal).Value!);

    private Order() { }  // EF Core 導航用

    /// <summary>
    /// 建立新訂單。
    /// 使用範例：Result&lt;Order&gt; order = Order.Create(customerId);
    /// </summary>
    public static Order Create(CustomerId customerId) => new()
    {
        Id = OrderId.New(),
        CreatedAt = DateTimeOffset.UtcNow,
        Status = OrderStatus.Pending
    };

    /// <summary>
    /// 加入訂單明細（業務規則：已確認的訂單不能修改）。
    /// 使用範例：Result result = order.AddItem(product, 2);
    /// </summary>
    public Result AddItem(Product product, int quantity)
    {
        // ✅ 業務規則放在 Domain，而非 Service
        if (Status != OrderStatus.Pending)
            return Result.Failure(new Error("ORDER_LOCKED", "已確認的訂單不能修改明細"));

        if (quantity <= 0)
            return Result.Failure(new Error("INVALID_QTY", "數量必須大於 0"));

        OrderItem? existing = _items.Find(i => i.ProductId == product.Id);
        if (existing is not null)
        {
            // ✅ 合併相同商品的數量
            existing.IncreaseQuantity(quantity);
        }
        else
        {
            _items.Add(OrderItem.Create(product.Id, product.Price, quantity));
        }

        return Result.Success();
    }
}

/// <summary>訂單明細（Aggregate 內部 Entity，不是 Aggregate Root）</summary>
public class OrderItem : Entity<OrderItemId>
{
    /// <summary>所屬商品 ID</summary>
    public ProductId ProductId { get; private set; }

    /// <summary>單價</summary>
    public Money UnitPrice { get; private set; } = null!;

    /// <summary>數量</summary>
    public int Quantity { get; private set; }

    /// <summary>小計（單價 × 數量）</summary>
    public Money SubTotal => Money.Create(UnitPrice.Amount * Quantity, UnitPrice.Currency).Value!;

    private OrderItem() { }

    /// <summary>
    /// 建立訂單明細。
    /// 使用範例：由 Order.AddItem() 內部呼叫，不應直接建立。
    /// </summary>
    internal static OrderItem Create(ProductId productId, Money unitPrice, int quantity) => new()
    {
        Id = OrderItemId.New(),
        ProductId = productId,
        UnitPrice = unitPrice,
        Quantity = quantity
    };

    /// <summary>
    /// 增加數量（由 Aggregate Root 呼叫）。
    /// 使用範例：由 Order.AddItem() 內部呼叫。
    /// </summary>
    internal void IncreaseQuantity(int additional) => Quantity += additional;
}
```

---

## 模式四：Domain Service

當業務邏輯跨越多個 Aggregate，且不屬於任何一個 Entity 時，使用 Domain Service。

```csharp
namespace 專案名稱.Domain.Services;

/// <summary>定價領域服務（跨 Product 與 Promotion 的邏輯）</summary>
public class PricingDomainService(IPromotionRepository promotionRepository)
{
    /// <summary>
    /// 計算商品的最終售價（考慮促銷活動）。
    /// 使用範例：Money finalPrice = await pricingService.CalculateFinalPriceAsync(product, ct);
    /// </summary>
    public async Task<Money> CalculateFinalPriceAsync(Product product, CancellationToken ct)
    {
        // ✅ 跨 Aggregate 的業務邏輯放在 Domain Service
        IReadOnlyList<Promotion> promotions =
            await promotionRepository.GetActiveForProductAsync(product.Id, ct);

        Money originalPrice = product.Price;
        return promotions.Aggregate(originalPrice,
            (price, promo) => promo.Apply(price));
    }
}
```

---

## 常見陷阱

### 1. 貧血型領域模型（Anemic Domain Model）

```csharp
// ❌ Entity 只有屬性，業務邏輯全在 Service（貧血模型）
public class Order
{
    public Guid Id { get; set; }
    public OrderStatus Status { get; set; }
    public List<OrderItem> Items { get; set; } = [];  // ❌ 公開可直接修改
}

public class OrderService
{
    public void AddItem(Order order, Product product)  // ❌ 業務邏輯不在 Entity
    {
        if (order.Status != OrderStatus.Pending)
            throw new InvalidOperationException("已確認訂單不能修改");
        order.Items.Add(new OrderItem(product));
    }
}

// ✅ 業務邏輯放在 Entity，Service 只協調流程
order.AddItem(product, quantity);  // Entity 自己保護業務規則
```

### 2. 外部直接修改 Aggregate 內部集合

```csharp
// ❌ 外部可直接修改 Items，繞過 Aggregate 保護
order.Items.Add(new OrderItem(...));  // ❌ 不應允許

// ✅ 只能透過 Aggregate Root 的方法修改
order.AddItem(product, quantity);     // ✅ 業務規則受到保護
```

---

## 最佳實踐摘要

| 項目 | 規範 |
|------|------|
| Entity | 繼承 `Entity<TId>`，業務行為放在 Entity 內 |
| Value Object | 使用 `sealed record`，透過工廠方法建立並驗證 |
| Aggregate 內部集合 | 以 `IReadOnlyList<T>` 暴露，禁止外部直接 `.Add()` |
| Domain Service | 跨 Entity/Aggregate 的業務邏輯，無狀態 |
| Repository 介面 | 定義在 Domain 層，Infrastructure 實作 |
| 業務規則 | 放在 Domain（Entity / Value Object / Domain Service），不放在 Application Service |
