# .NET Skills 開發指南

本文件提供給貢獻者與 AI Agent 使用，說明如何維護與擴充本 Skill 庫。

## 分支策略

> **重要：禁止直接推送到 `main` 分支！**

| 分支 | 用途 | 提交方式 |
|------|------|----------|
| `main` | 發布分支（使用者安裝的來源） | 禁止直接 commit，透過 GitHub Action 同步 |
| `dev` | 開發分支（所有開發工作） | 透過 PR 提交 |

## 新增 Skill 步驟

1. 從 `dev` 分支建立 feature branch：`git checkout -b skill/your-skill-name`
2. 建立 Skill 目錄：`skills/<skill-name>/SKILL.md`
3. 將 Skill 路徑加入 `.claude-plugin/plugin.json` 的 `skills` 陣列
4. 執行驗證腳本：`.\scripts\validate-skills.ps1`
5. 執行索引更新：`.\scripts\generate-index.ps1`
6. 提交 PR 至 `dev` 分支

## SKILL.md 規格

每個 `SKILL.md` 必須包含：

### YAML Frontmatter（必填）

```yaml
---
name: skill-name-in-kebab-case
description: English description for AI keyword matching. Be specific about when to use this skill.
invocable: false
---
```

### 內容結構（必填）

```markdown
# Skill 標題（繁體中文）

## 使用時機（When to Use）
說明何時應觸發此 Skill。

## 核心模式
包含 ✅ 正確範例 與 ❌ 錯誤反例。

## 常見陷阱（Common Pitfalls）
## 最佳實踐摘要
```

### 語言規範

- **`description` 欄位**：英文（供 AI 關鍵字匹配）
- **其餘所有內容**：繁體中文
- **程式碼範例**：程式碼本身不限語言，但**程式碼內的註解必須繁體中文**

### 內容規範

- 每個 method 必須有**繁體中文註解**與**使用範例**
- `class`/`struct`/`record` 的每個欄位必須有**一列式 XML `<summary>`**
- 明確型別宣告（禁止以 `var` 取代明確型別）
- 簡單方法優先使用 **Expression-body (`=>`)**

### 長度規範

- 單一 `SKILL.md`：建議 10KB–40KB
- 若內容過長（> 40KB），拆分為 `SKILL.md` + `references/` 子目錄

## 新增 Agent 步驟

1. 建立 `agents/<agent-name>.md`
2. 加入 `.claude-plugin/plugin.json` 的 `agents` 陣列
3. 執行 `.\scripts\validate-skills.ps1` 驗證

## 發布流程

1. 更新 `.claude-plugin/plugin.json` 的 `version` 欄位
2. 更新 `CHANGELOG.md`
3. Push semver tag：`git tag v0.x.0 && git push origin v0.x.0`
4. GitHub Actions 自動建立 Release 並同步至 `main`

## Eval 規格

每個 Eval 包含一個完整可編譯的 .NET 8 Web API 專案：

```
evals/suites/<skill-name>/<scenario-name>/
├── eval.json       # 任務描述與期望行為
├── eval.cs         # xUnit 驗證測試（執行期間對 AI 隱藏）
├── results.json    # 各模型執行結果
├── Program.cs
├── *.csproj
└── Controllers/    # 空白 stub
```

`eval.json` 格式：

```json
{
  "skills": ["skill-name"],
  "query": "請用繁體中文描述任務...",
  "files": ["Controllers/ProductController.cs"],
  "expected_behavior": [
    "使用 Primary Constructor 注入依賴",
    "回傳 IActionResult 並標注 [ProducesResponseType]"
  ]
}
```
