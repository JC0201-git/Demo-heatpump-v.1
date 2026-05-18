# 研究報告：熱泵／熱水系統監控儀表板

**Branch**: `001-heatpump-dashboard-6pages` | **Date**: 2026-05-17  
**Phase**: 0 — 技術決策研究  
**輸入**: plan.md 技術背景中的 NEEDS CLARIFICATION 項目與各依賴項最佳實踐

---

## 研究 1：後端框架選擇（Express vs Fastify）

**決策**：選用 **Fastify 4**

**理由**：
- Fastify 原生支援 TypeScript，無需額外型別封裝
- 內建 JSON Schema 驗證（ajv），減少 API 輸入驗證程式碼
- `fast-json-stringify` 序列化比 JSON.stringify 快 2～3 倍，對 80 台設備輪詢有效益
- `@fastify/jwt` + `@fastify/cookie` 插件整合登入流程直接
- 社群插件（`@fastify/cors`、`@fastify/rate-limit`）完整覆蓋本案需求

**考慮過的替代方案**：
- Express 5（仍 beta）：生態豐富但 TypeScript 整合需額外設定
- Hono：超輕量但 ecosystem 較小，本案不需要 edge runtime

---

## 研究 2：InfluxDB 1.8 客戶端選擇

**決策**：使用 `influx` npm 套件（@5.x）

**理由**：
- `@influxdata/influxdb-client`（官方套件）預設使用 Flux，InfluxDB 1.8 僅支援 InfluxQL
- `influx` 套件專為 InfluxDB 1.x 設計，使用 HTTP API `/query` 端點，以 InfluxQL 查詢
- 支援 TypeScript，可自行定義 measurement 型別
- 支援 promise-based API，與 async/await 整合良好

**InfluxQL 查詢範例**：
```sql
-- 查詢 30 日每日用電彙總（優先從 energy_daily_summary）
SELECT mean("kwh_total") FROM "energy_daily_summary"
WHERE "device_id" = 'DEV-001'
  AND time >= now() - 30d
GROUP BY time(1d) fill(null)

-- 查詢最新設備狀態
SELECT last("operating_mode"), last("cop"), last("run_hours")
FROM "heatpump_status"
WHERE "device_id" = 'DEV-001'
  AND time >= now() - 5m
```

**考慮過的替代方案**：
- 直接使用 HTTP fetch 呼叫 InfluxDB REST API：可行但缺乏型別安全性，維護成本高

---

## 研究 3：MySQL ORM 選擇

**決策**：使用 **Drizzle ORM**

**理由**：
- TypeScript-first 設計，schema 定義即型別定義，無需額外 type generation 步驟
- SQL-like query builder，對熟悉 SQL 的開發者學習曲線低
- 支援 MySQL（透過 `drizzle-orm/mysql2`）
- 輕量（vs TypeORM 重量級反射機制）
- 自動生成 migration 文件
- MySQL 8.0 為開源、無授權費用，在 Ubuntu Linux 上安裝與維護成本低

**考慮過的替代方案**：
- TypeORM：功能完整但過度工程，decorator 語法對嚴格 TypeScript 設定有相容問題
- Prisma：schema 語言優雅，MySQL 支援完善，但 Prisma Client 體積大
- 原生 `mysql2` 套件：最輕量但需手動管理參數化查詢，SQL Injection 風險較高

---

## 研究 4：JWT vs Session 認證策略

**決策**：使用 **JWT（stateless）存於 httpOnly cookie**

**理由**：
- 系統部署於兩台 EC2（前端主機 A、資料庫主機 B），無共享 session store
- JWT stateless，後端 API 無需存儲 session，水平擴展容易
- httpOnly cookie 防止 JavaScript 竊取 token（XSS 防護）
- SameSite=Lax 防止 CSRF（Dashboard 為同一域名）
- Token 有效期 8 小時，配合值班工程師工作時段

**考慮過的替代方案**：
- Redis session：需額外 Redis 服務（Demo 階段過重）
- LocalStorage JWT：有 XSS 風險，不採用
- Refresh token：v1 不需要，MVP 可加入

**安全注意事項**：
- 登入失敗統一返回「帳號或密碼錯誤」，不區分原因（防帳號枚舉）
- 登入 API 限制 10 次/分鐘（防暴力破解）

---

## 研究 5：PDF 匯出策略

**決策**：使用 **jsPDF + html2canvas**（前端純客戶端）

**理由**：
- 規格明確要求「前端 PDF 函式庫，不需後端 PDF 服務」
- jsPDF 可直接產生 PDF；html2canvas 用於截取圖表 canvas 元素
- 不需要後端 PDF 微服務，降低部署複雜度
- 月報頁面已渲染完成，直接截圖轉 PDF 效率高

**實作方式**：
```typescript
// 點擊「匯出 PDF」後：
// 1. html2canvas 截取 #monthly-report DOM 節點為 canvas
// 2. jsPDF 建立 A4 文件，插入 canvas 圖片
// 3. jsPDF.save('月報-YYYY-MM.pdf') 觸發下載
```

**已知限制**：
- PDF 為截圖（點陣圖），非向量圖；字體稍模糊
- Demo 可接受；MVP 若需高品質 PDF 可改用 Puppeteer（後端）

---

## 研究 6：前端狀態管理（Zustand vs Redux）

**決策**：使用 **Zustand**

**理由**：
- 80 台設備、6 頁的規模，Zustand 足夠
- 無 boilerplate（無 action type、reducer）
- TypeScript 支援良好
- 與 React hooks 整合自然
- bundle size 遠小於 Redux Toolkit

**考慮過的替代方案**：
- Redux Toolkit：功能強大但本案規模過重
- React Query：適合伺服器狀態快取，可與 Zustand 搭配（MVP 可引入）
- Context API：效能問題（深層元件更新觸發）

---

## 研究 7：輪詢 vs WebSocket vs SSE

**決策**：使用 **定時輪詢（30 秒間隔）**

**理由**：
- 規格明確指定「每 30 秒向 API 重新取得」
- 80 台設備的資料量小，每次請求 ≤ 10 KB，30 秒輪詢開銷可接受
- 後端快取 TTL 25 秒，大多請求直接走快取，不觸及資料庫
- WebSocket/SSE 需要後端 push 架構，Demo 階段過重

**MVP 升級路線**：
- 可引入 Server-Sent Events（SSE）讓後端主動推送告警，降低輪詢頻率

---

## 研究 8：Docker Compose 跨 EC2 連線最佳實踐

**決策**：使用 **AWS VPC 私有 IP + EC2 Security Group 限制**

**理由**：
- 同一 VPC 內的 EC2 通訊使用私有 IP，延遲 < 1 ms，不計費
- Security Group 最小權限原則：InfluxDB/MySQL Port 僅對 EC2 A 的安全群組開放
- 比 VPN 或 PrivateLink 簡單，適合 Demo 規模

**環境變數管理**：
- 敏感設定（DB 密碼、JWT 密鑰）存於 EC2 A 的 `docker/.env`
- 不進 Git，提供 `.env.example` 作為範本
- 生產部署前需手動設定 EC2 上的 `.env` 文件

---

## 研究 9：InfluxDB Daily Summary 必要性評估

**決策**：**Demo 階段必要**，需要 `energy_daily_summary` 與 `heatpump_daily_summary`

**理由**：
- 30 日折線圖若每次都對 `power_meter`（高頻寫入的 measurement）做 GROUP BY time(1d) 聚合，查詢時間可能超過 5 秒（取決於資料量）
- `energy_daily_summary` 預先彙整後，30 日查詢只需掃描 30 筆記錄，查詢 < 50 ms
- 7 台真實設備每天寫入量估計：每台每分鐘 1 筆 × 60 × 24 ≈ 1440 筆/天，30 天 = 43,200 筆
- 即時聚合 43,200 筆 × 7 台 = 302,400 筆，超過可接受延遲

**實作方案**：
- Demo 階段：後端 node-cron 每日 00:05 彙整前一天資料並寫入 `energy_daily_summary`
- 初始化：匯入 7 台真實設備過去 30 天的歷史彙總資料（或直接用 Mock 資料補）

---

## 研究 10：Mock 資料量估算與格式設計

**決策**：73 個 JSON 文件，每個包含 30 天歷史資料 + 即時狀態

**估算**：
- 每台設備 JSON：30 筆 power + 30 筆 operation + 1 筆即時狀態 ≈ 61 筆
- 每筆 ≈ 100 bytes，每個 JSON ≈ 6 KB
- 73 台 × 6 KB ≈ 438 KB 總大小
- 後端啟動一次載入 438 KB 進記憶體，無效能問題

**加速 Demo 開發**：使用腳本批次產生 73 個 Mock JSON，隨機化數值以模擬真實波動。

---

## 研究 11：未處理告警逾時門檻設定

**決策**：未處理告警逾時門檻由 `system_settings.ALERT_OVERDUE_HOURS` 管理，預設值為 24 小時。

**理由**：
- 月報的「逾時未處理」屬營運管理門檻，未來可能因 SLA 或客戶合約調整，不應寫死在月報邏輯中
- `system_settings` 已用於輪詢間隔、查詢天數與維運容量設定，沿用同一設定來源可降低維護成本
- 24 小時符合 Demo 階段對「跨日未處理」告警的直覺判定，利於主管快速辨識延宕項目

**考慮過的替代方案**：
- 寫死在程式常數：實作最簡單，但後續調整需重新部署
- 由前端傳入 query parameter：彈性高，但會讓同一月份報告因使用者輸入而不一致
- 依告警嚴重性設定不同門檻：更精細，但 v1 規格未要求，Demo 階段過度複雜

---

## 研究總結：所有 NEEDS CLARIFICATION 已解決

| 原始問題 | 決策 |
|---------|------|
| Express vs Fastify | **Fastify 4** |
| InfluxDB client | **`influx` npm 套件（1.x 相容）** |
| MySQL ORM | **Drizzle ORM** |
| JWT vs Session | **JWT + httpOnly cookie** |
| PDF 匯出 | **jsPDF + html2canvas（純前端）** |
| 狀態管理 | **Zustand** |
| 輪詢 vs WebSocket | **定時輪詢（30 秒）** |
| 跨 EC2 連線 | **VPC 私有 IP + Security Group** |
| Daily summary 必要性 | **必要，Demo 即實作** |
| Mock 資料規模 | **73 個 JSON，啟動時載入** |
| 未處理告警逾時門檻 | **`system_settings.ALERT_OVERDUE_HOURS`，預設 24 小時** |
