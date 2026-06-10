# evals 目錄說明

此目錄包含 **各個 Skill** 的測試套件，用於驗證 Skill 是否能正確編譯與執行。每個子目錄代表一個 **scenario**，結構如下：

```
evals/suites/<skill-name>/<scenario-name>/
├── eval.json       # 任務描述與期望行為
├── eval.cs         # xUnit 驗證測試（執行期間對 AI 隱藏）
├── results.json    # 各模型執行結果
├── Program.cs      # 測試專案入口
├── *.csproj        # .NET 8 Web API 專案檔
└── Controllers/    # 空白 stub，供 Skill 實作
```

### 如何執行驗證
1. 進入欲測試的 `scenario` 目錄。
2. 執行 `dotnet test` 或 `dotnet run` 以跑通 xUnit 測試。
3. 測試成功代表該 Skill 符合 `eval.json` 所描述的預期行為。

此說明文件提供快速上手的指引，讓貢獻者能在本機驗證自己的 Skill 實作是否符合標準。
