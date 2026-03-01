# 🤝 貢獻指南 (Contributing Guidelines)

感謝你對 `dotnet-skills` 專案的興趣！本專案旨在建立一套高品質的 .NET 開發 AI 技能包，幫助開發者透過 AI 工具產生符合最佳實踐的程式碼。

為了確保 Skills 的一致性與品質，請在貢獻前閱讀以下規範。

---

## 📋 新增 Skill 規範

### 1. 檔案命名與位置

- 所有 Skill 檔案必須位於 `.skills/` 資料夾下。
- 檔案名稱須使用 **小寫英文 + 連字號** (kebab-case)。
- 副檔名統一為 `.md` 或 `.skill` (建議 `.md` 以便預覽)。
- 範例：`.skills/efcore-async-patterns.md`

### 2. 必填 Metadata (YAML Front Matter)

每個 Skill 檔案開頭必須包含以下 YAML 區塊：

```yaml
---
name: 技能顯示名稱
description: 簡短描述 (不超過 50 字)
category: 架構設計 | C# 語法 | ASP.NET Core | EF Core | 其他
tags: [關鍵字 1, 關鍵字 2, 關鍵字 3]
version: 1.0.0
author: 你的名字
created_at: 2024-01-01
---
