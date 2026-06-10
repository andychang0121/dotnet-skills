---
name: dotnet-testing-practices
description: Best practices for writing unit and integration tests in .NET using xUnit, NSubstitute, FluentAssertions, and WebApplicationFactory.
description_zh: 使用 xUnit、NSubstitute 與 FluentAssertions 撰寫單元測試與整合測試的最佳實踐。
invocable: false
---

# 單元與整合測試最佳實踐

## 使用時機（When to Use）
本技能適用於開發人員為 .NET 專案撰寫單元測試（Unit Test）與整合測試（Integration Test）的場景。特別是利用 **xUnit** 作為測試框架、**NSubstitute** 作為 Mock 隔離工具，以及 **FluentAssertions** 作為斷言函式庫時，規範測試結構以維持測試程式的可讀性與可維護性。

## 核心模式

### ✅ 正確範例（單元測試）
* **測試命名結構**：`MethodName_StateUnderTest_ExpectedBehavior` (例如：`RegisterUserAsync_EmailAlreadyExists_ShouldReturnFailureResult`)。
* **AAA 結構**：明確劃分 `Arrange` (準備)、`Act` (執行)、`Assert` (驗證) 三個區塊，並使用空白行分隔。
* **強型別 Mock 與 FluentAssertions**：使用 `Substitute.For<T>` 來 Mock 介面，並以 `Should().Be(...)` 進行語意化斷言。
* **XML 文件規範**：類別與測試方法應附帶繁體中文說明。

```csharp
using System;
using System.Threading.Tasks;
using Xunit;
using NSubstitute;
using FluentAssertions;

namespace DotNetSkills.Testing.Tests;

/// <summary>
/// 使用者服務 (UserService) 的單元測試類別
/// </summary>
public class UserServiceTests
{
    private readonly IUserRepository _userRepositoryMock;
    private readonly ILogger<UserService> _loggerMock;
    private readonly UserService _sut; // System Under Test

    /// <summary>
    /// 初始化測試實例，建立 Mock 物件與測試主體
    /// </summary>
    public UserServiceTests()
    {
        _userRepositoryMock = Substitute.For<IUserRepository>();
        _loggerMock = Substitute.For<ILogger<UserService>>();
        _sut = new UserService(_userRepositoryMock, _loggerMock);
    }

    /// <summary>
    /// 驗證當註冊信箱已存在時，應回傳失敗結果
    /// </summary>
    /// <example>
    /// 測試案例：信箱 "duplicate@example.com" 已被使用
    /// </example>
    [Fact]
    public async Task RegisterUserAsync_EmailAlreadyExists_ShouldReturnFailureResult()
    {
        // Arrange (準備)
        string email = "duplicate@example.com";
        RegisterRequest request = new RegisterRequest(email, "Password123");
        
        // 設定 Mock 行為：當查詢此信箱時回傳已存在的使用者
        _userRepositoryMock.ExistsByEmailAsync(email).Returns(true);

        // Act (執行)
        Result<UserDto> result = await _sut.RegisterUserAsync(request);

        // Assert (驗證)
        result.IsSuccess.Should().BeFalse();
        result.Error.Should().Be("Email already registered");
        
        // 驗證 Repository 沒有呼叫新增方法
        await _userRepositoryMock.DidNotReceive().AddAsync(Arg.Any<User>());
    }
}
```

### ❌ 錯誤反例
* 測試結構混亂，Arrange、Act、Assert 混在一起，缺乏明確分隔。
* 隨意命名測試方法，無法單從名稱看出測試目的。
* 溺用 C# 原生 `Assert.True`，報錯訊息不直觀，且未驗證 Mock 的互動行為。

```csharp
using System;
using System.Threading.Tasks;
using Xunit;
using NSubstitute;

namespace DotNetSkills.Testing.Tests;

public class TestClass
{
    // 錯誤 1: 沒有寫 XML 說明，測試方法命名模糊，且沒有區分 AAA 區塊
    [Fact]
    public async Task Test1()
    {
        // Arrange 與 Act 與 Assert 全混在一起
        var repo = Substitute.For<IUserRepository>();
        repo.ExistsByEmailAsync("test@test.com").Returns(true);
        var logger = Substitute.For<ILogger<UserService>>();
        var service = new UserService(repo, logger);
        
        var req = new RegisterRequest("test@test.com", "12345");
        var res = await service.RegisterUserAsync(req);
        
        // 錯誤 2: 使用弱語意 Assert，當失敗時錯誤資訊不佳
        Assert.False(res.IsSuccess);
        Assert.Equal("Email already registered", res.Error);
    }
}
```

## 常見陷阱（Common Pitfalls）
1. **Mock 具體類別而非介面**：使用 NSubstitute 去 Mock 沒有虛擬方法 (`virtual`) 的實體類別會導致執行期報錯。務必針對 Interface 進行 Mock。
2. **過度測試 Mock 互動**：頻繁使用 `Received()` 去驗證每一次的內部方法呼叫會導致測試與實作細節過度耦合 (Over-specification)。通常只驗證有關鍵副作用的方法（如寄信、寫入資料庫）。
3. **在單元測試中連接真實外部資源**：單元測試中不應呼叫真實資料庫、外部 API 或檔案系統，這會降低測試執行速度並導致不穩定。外部資源應使用介面隔離並 Mock。

## 最佳實踐摘要
* 測試類別及測試方法皆必須撰寫繁體中文說明。
* 測試方法名稱應遵循 `MethodName_StateUnderTest_ExpectedBehavior` 結構。
* 嚴格區分並用空白行隔離 `Arrange`、`Act`、`Assert` 區塊。
* 使用 `FluentAssertions` 進行語意清晰的斷言（如 `result.Should().NotBeNull()`）。
* 測試中禁止使用隱式型別 `var` 進行重要物件之宣告，維持型別明確度。
