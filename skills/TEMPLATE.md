---
name: skill-name-in-kebab-case
description: A clear English description for AI keyword matching, detailing specifically when this skill should be invoked.
invocable: false
---

# Skill 標題（繁體中文）

## 使用時機（When to Use）
請以繁體中文說明何時應觸發此 Skill。描述適合此設計模式或規範的具體情境與背景。

## 核心模式

### ✅ 正確範例
請提供一個清晰且符合最佳實踐的 C# 程式碼範例。
* 所有欄位與類別必須有一列式 XML `<summary>` 說明文件。
* 所有公開/內部方法必須有**繁體中文註解**與**使用範例**。
* 明確宣告變數型別（禁止溺用 `var`）。
* 簡單方法優先使用 Expression-body (`=>`)。

```csharp
using System;

namespace DotNetSkills.Template;

/// <summary>
/// 範本類別的單行摘要說明
/// </summary>
public class ExampleService
{
    /// <summary>
    /// 內部欄位摘要說明
    /// </summary>
    private readonly string _prefix;

    /// <summary>
    /// 建構子，初始化範本服務
    /// </summary>
    /// <param name="prefix">前綴字串</param>
    public ExampleService(string prefix)
    {
        _prefix = prefix;
    }

    /// <summary>
    /// 執行指定操作並格式化輸出
    /// </summary>
    /// <param name="message">輸入的訊息</param>
    /// <returns>格式化後的結果字串</returns>
    /// <example>
    /// 使用範例：
    /// <code>
    /// ExampleService service = new ExampleService("SYS");
    /// string result = service.Execute("Hello");
    /// </code>
    /// </example>
    public string Execute(string message) => $"{_prefix}: {message}";
}
```

### ❌ 錯誤反例
請提供對應的反例，說明不佳的設計方式，並搭配中文註解說明其問題。

```csharp
using System;

namespace DotNetSkills.Template;

// 缺少 XML 文件說明
public class BadService
{
    private readonly string prefix;

    public BadService(string prefix)
    {
        this.prefix = prefix;
    }

    // 1. 缺少 XML 文件說明與範例
    // 2. 註解未使用繁體中文
    // 3. 簡單方法未使用 Expression-body 簡化
    public string Execute(string message)
    {
        // 應避免使用 var 代替明確型別
        var result = this.prefix + ": " + message;
        return result;
    }
}
```

## 常見陷阱（Common Pitfalls）
* 列出開發者在實作此功能或模式時最常犯的錯誤。
* 指出容易導致效能瓶頸、記憶體洩漏或執行期錯誤的寫法。

## 最佳實踐摘要
* 條列式總結核心的開發與設計原則。
* 提供一目了然的快速查閱清單。
