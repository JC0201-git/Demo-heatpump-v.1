---
description: "熱泵／熱水系統監控儀表板（6 頁）任務清單"
---

# Tasks: 熱泵／熱水系統監控儀表板（6 頁）

**輸入**：設計文件來自 `/specs/001-heatpump-dashboard-6pages/`  
**必要前置文件**：plan.md ✅、spec.md ✅、research.md ✅、data-model.md ✅、contracts/ ✅、quickstart.md ✅  
**測試**：spec.md Constitution II 明確規範「TDD 用於 API handler 與風險分數計算」，相關整合測試任務已含入各故事 Phase。  
**組織方式**：任務依使用者故事分組，支援各故事獨立實作與驗收。

## 格式說明

- **[P]**：可平行執行（不同檔案，無對尚未完成任務的依賴）
- **[Story]**：所屬使用者故事標籤（US1–US6）；Setup / Foundational / Polish 階段不附此標籤
- 說明中含精確的檔案路徑

---

## Phase 1：專案建置（Setup）

**目標**：建立前後端專案骨架、開發工具設定、Docker 部署基礎

- [ ] T001 建立前端專案架構（Vite 5 + React 18 + TypeScript 5 + Tailwind CSS v3 + React Router v6 + ECharts `echarts-for-react` + Zustand + Axios + jsPDF + html2canvas）→ `frontend/`
- [ ] T002 [P] 建立後端專案架構（Fastify 4 + TypeScript 5 + Drizzle ORM + mysql2 + influx@5 + bcryptjs + node-cron + @fastify/jwt + @fastify/cookie + @fastify/cors + @fastify/rate-limit）→ `backend/`
- [ ] T003 [P] 設定前端 ESLint + Prettier 規則（Constitution I）→ `frontend/.eslintrc.cjs`、`frontend/.prettierrc`
- [ ] T004 [P] 設定後端 ESLint 規則（Constitution I）→ `backend/.eslintrc.cjs`
- [ ] T005 [P] 建立 Docker Compose 服務定義（nginx :80 + frontend :3000 + backend-api :3001）與 Nginx 反向代理設定（`/api/*` → backend-api:3001，`/*` → React SPA）→ `docker/docker-compose.yml`、`docker/nginx/default.conf`
- [ ] T006 [P] 建立環境變數範本（JWT_SECRET、MYSQL_*、INFLUXDB_*、DEVICE_CACHE_TTL=25、REPORT_CACHE_TTL=300、MAX_DEVICES_PER_TECH=20、MAX_WORK_ORDERS_PER_TECH=10）與 `.gitignore`（排除 `docker/.env`）→ `docker/env.example`、`.gitignore`

**Checkpoint**：前後端可各自 `npm install` 並啟動；`docker compose up --build` 可啟動三個容器

---

## Phase 2：基礎設施（Foundational）

**目標**：資料庫 Schema、認證框架、Mock 資料、前端共用基礎——所有使用者故事都依賴本階段

**⚠️ 關鍵**：本階段完成前，任何使用者故事均不可開始實作

### 2A：後端基礎設施

- [ ] T007 定義 Drizzle ORM MySQL Schema（11 張表：clients、sites、devices、meters、device_meter_mappings、alerts、work_orders、technicians、users、system_settings、risk_score_weights；完整對應 data-model.md DDL）→ `backend/src/db/schema.ts`
- [ ] T008 建立 Drizzle migration 初始腳本（含所有 DDL Index 與 CHECK constraint）→ `backend/src/db/migrations/0001_init.sql`
- [ ] T009 [P] 建立資料庫 seed 腳本（system_settings 5 條（含 MAX_DEVICES_PER_TECH=20 及 MAX_WORK_ORDERS_PER_TECH=10 兩個獨立設定項）+ risk_score_weights 6 條 + 7 台 real 設備測試資料；至少 1 筆 users（帳號 admin、bcrypt hash 密碼，供登入測試）；3–5 筆 technicians（status=active，供告警指派下拉使用）；對應 clients 與 sites 基礎資料）→ `backend/src/db/seed.ts`
- [ ] T010 [P] 建立 InfluxDB 1.x 查詢模組（連線設定 + InfluxQL 查詢函式，支援 power_meter、heatpump_status、energy_daily_summary、heatpump_daily_summary）→ `backend/src/influx/client.ts`、`backend/src/influx/queries.ts`
- [ ] T011 [P] 建立 73 台 Mock 設備 JSON 資料（DEV-008 ～ DEV-080；每檔含 realtimeStatus、30 日用電與運轉歷史、告警紀錄、工單紀錄；數值隨機化）→ `mock-data/devices/DEV-008.json` … `mock-data/devices/DEV-080.json`
- [ ] T012 建立 Mock 資料載入器（伺服器啟動時一次讀取所有 JSON 至記憶體；提供 `getMockDevice(id)`、`getMockDeviceList()` 方法）→ `backend/src/mock/loader.ts`
- [ ] T013 建立 dataSourceService（依 `data_source_type` 路由至 real InfluxDB/MySQL 或 mock loader）→ `backend/src/services/dataSourceService.ts`
- [ ] T014 初始化 Fastify 應用程式（註冊 @fastify/cors、@fastify/jwt httpOnly cookie、@fastify/cookie、@fastify/rate-limit；設定全域 setErrorHandler 統一 JSON 錯誤格式 `{error, message, statusCode}`）→ `backend/src/app.ts`、`backend/src/server.ts`
- [ ] T015 實作 JWT 認證 preHandler hook（驗證 `hp_token` httpOnly cookie；驗失回傳 401 UNAUTHORIZED）→ `backend/src/middleware/auth.ts`
- [ ] T016 [P] 定義後端共用 TypeScript DTO 型別（DeviceListItem、DeviceDetail、AlertItem、WorkOrder、RiskDevice、MonthlyReport、ExecutiveSummary、CapacityResult 等）→ `backend/src/types/device.ts`、`backend/src/types/alert.ts`、`backend/src/types/common.ts`
- [ ] T017 [P] 實作系統健康檢查端點（`GET /api/system/health` 回傳 influxdb + mysql 連線狀態；`GET /api/system/last-updated`）→ `backend/src/routes/system.ts`
- [ ] T065 建立 node-cron 每日彙總工作（每日 00:05 執行：聚合前一日 `power_meter` 寫入 InfluxDB `energy_daily_summary`；聚合 `heatpump_status` 寫入 `heatpump_daily_summary`；依賴 T010 InfluxDB queries + T007 MySQL schema；同時為 US3 單機履歷（T055/T056）與 US5 月報（T066）提供彙整資料來源；開發環境提供 `triggerDailySummary()` 手動觸發方法）→ `backend/src/jobs/dailySummaryJob.ts`
- [ ] T106 [P] 單元測試 dailySummaryJob（Arrange：以 stub 注入 InfluxDB client 與 queries；Act：呼叫 `triggerDailySummary()`；Assert：驗 energy_daily_summary 寫入呼叫恰好一次、heatpump_daily_summary 寫入呼叫恰好一次、InfluxDB 連線失敗時錯誤被記錄且不拋出未攔截例外；Constitution II TDD：測試先於 T065 完整實作；覆蓋率目標 ≥ 80%）→ `backend/tests/unit/jobs/dailySummaryJob.test.ts`

### 2B：認證 API（Auth Backend）

- [ ] T018 實作認證路由（`POST /api/auth/login`：bcrypt 驗密 + 設定 httpOnly JWT cookie + rate-limit 10次/分；`POST /api/auth/logout`：清除 cookie；`GET /api/auth/me`：回傳登入資訊；登入失敗統一回傳「帳號或密碼錯誤」防帳號枚舉）→ `backend/src/routes/auth.ts`

### 2C：前端基礎設施

- [ ] T019 [P] 定義前端共用 TypeScript 型別（DeviceStatus、DeviceListItem、AlertItem、RiskDevice 等；與後端 DTO 對齊）→ `frontend/src/types/device.ts`、`frontend/src/types/alert.ts`、`frontend/src/types/risk.ts`
- [ ] T020 建立 React App 主架構（React Router v6 路由結構 + ProtectedRoute + MainLayout + 左側 Sidebar 導覽列包含 6 頁連結）→ `frontend/src/App.tsx`、`frontend/src/components/Layout/Sidebar.tsx`、`frontend/src/components/Layout/MainLayout.tsx`
- [ ] T021 [P] 設定 Tailwind CSS 設計 Token（主背景 `#0d1f1a`、卡片背景 `#112820`、強調色 `#a3e635`、四種狀態色 normal/alert/offline/maintenance）→ `frontend/tailwind.config.ts`
- [ ] T022 [P] 建立 Axios 實例與攔截器（withCredentials=true、baseURL=/api、401 自動重導 /login、回應時間戳快取標記）→ `frontend/src/services/api.ts`
- [ ] T023 [P] 建立共用 StatusBadge 元件（四色語意：綠 normal / 紅 alert / 灰 offline / 橘 maintenance）→ `frontend/src/components/StatusBadge.tsx`
- [ ] T024 [P] 建立共用 AlertBanner 元件（「API 連線異常」頁面頂部橫幅 + 「資料可能過期」行內標籤）→ `frontend/src/components/AlertBanner.tsx`
- [ ] T025 建立登入頁元件（帳號密碼表單 → `POST /api/auth/login` → 成功導向 `/devices`）→ `frontend/src/pages/Login/LoginPage.tsx`
- [ ] T026 [P] 建立 authStore（Zustand）與 useAuth Hook（儲存登入使用者資訊、登出方法）→ `frontend/src/stores/authStore.ts`、`frontend/src/hooks/useAuth.ts`
- [ ] T027 [P] 建立路由守衛 ProtectedRoute（未登入者重導至 `/login`）→ `frontend/src/components/ProtectedRoute.tsx`
- [ ] T028 [P] 建立 usePolling Hook（可設定間隔的定時器，預設 30s；提供 start/stop 方法）→ `frontend/src/hooks/usePolling.ts`
- [ ] T029 [P] 建立 LastUpdatedBadge 元件（顯示頁面頂部最後資料更新時間，整合過期資料偵測）→ `frontend/src/components/LastUpdatedBadge.tsx`

**Checkpoint**：`GET /api/system/health` 回應健康；前端顯示登入頁並可登入後進入受保護路由

---

## Phase 3：使用者故事 1 — 設備總覽（Priority: P1）🎯 MVP

**目標**：維運工程師可一眼掌握 80 台設備狀態，依狀態篩選、依關鍵字搜尋，並導向單機履歷

**獨立驗收測試**：帶入 80 台設備 mock 資料 → 列表顯示全部設備；狀態篩選僅顯示符合條件設備；點擊設備列導向 `/devices/:deviceId`

### 後端實作（US1）

- [ ] T030 [US1] 實作 deviceService.getDeviceList()（讀取 MySQL + Mock JSON 彙整；依 status/search 篩選；排序：alert > maintenance > offline > normal 再依 riskScore 降序；node-cache TTL 25s）→ `backend/src/services/deviceService.ts`
- [ ] T031 [US1] 實作 `GET /api/devices` 路由（套用 authGuard；解析 status、search、page、limit query params；search 欄位採 `LIKE 'keyword%'` 前綴模糊比對，不區分大小寫）→ `backend/src/routes/devices.ts`

### 前端實作（US1）

- [ ] T032 [US1] 建立 deviceStore（Zustand）整合 usePolling（30s 輪詢 `/api/devices`，支援快取過期偵測）→ `frontend/src/stores/deviceStore.ts`
- [ ] T033 [P] [US1] 建立 DeviceTable 元件（欄位：設備編號、客戶名稱、地點、StatusBadge、最後心跳時間；離線設備即時欄位顯示「--」；點擊列導向 `/devices/:deviceId`）→ `frontend/src/pages/DeviceList/DeviceTable.tsx`
- [ ] T034 [P] [US1] 建立 StatusFilter 元件（全部 / 正常 / 異常 / 離線 / 待維修 篩選按鈕，顯示各狀態數量）→ `frontend/src/pages/DeviceList/StatusFilter.tsx`
- [ ] T035 [P] [US1] 建立 SearchBar 元件（依設備編號或客戶名稱即時搜尋，顯示篩選結果數量）→ `frontend/src/pages/DeviceList/SearchBar.tsx`
- [ ] T036 [US1] 組裝 DeviceList 頁面（整合 AlertBanner + LastUpdatedBadge + StatusFilter + SearchBar + DeviceTable）→ `frontend/src/pages/DeviceList/DeviceListPage.tsx`
- [ ] T090 [US1] US1 整合測試：設備列表 happy-path（GET /api/devices 帶入 80 台 mock 資料 → 驗回傳設備清單欄位完整、status 篩選結果正確、search 模糊搜尋符合預期；AAA 模式；TDD：測試先於實作；**SC-001 人工驗收**：完成後需計時「工程師進入設備總覽頁 → 識別所有異常設備」流程 ≤ 30 秒，結果記錄於驗收報告）→ `backend/tests/integration/devices.test.ts`
- [ ] T100 [P] [US1] US1 前端單元測試：DeviceTable / StatusFilter / SearchBar 元件（Vitest + Testing Library；測試項目：StatusBadge 顏色 token 正確渲染、篩選按鈕點擊觸發 store 更新、搜尋輸入 debounce 行為、離線設備顯示「--」；覆蓋率 ≥ 80%；TDD：測試先於元件實作）→ `frontend/tests/unit/DeviceList/`

**Checkpoint**：US1 可獨立測試——80 台設備完整顯示；篩選 / 搜尋正常；點擊導向設備路由

---

## Phase 4：使用者故事 4 — 告警中心（Priority: P1）

**目標**：值班工程師可集中管理即時告警、指派負責人、標記已解除；未指派告警置頂，高嚴重性視覺突出

**獨立驗收測試**：帶入 mock 告警資料 → 未指派置頂；高嚴重性紅色高亮；完成指派後狀態更新為「處理中」；解除後記錄 resolved_at

### 後端實作（US4）

- [ ] T037 [US4] 實作 alertService.getAlerts()（排序：未指派置頂 → severity 降序 → occurredAt 降序；依 status / alert_type / severity 篩選；node-cache TTL 10s）→ `backend/src/services/alertService.ts`
- [ ] T038 [US4] 實作 `GET /api/alerts` 路由（套用 authGuard；支援 status、alert_type、severity、page、limit params）→ `backend/src/routes/alerts.ts`
- [ ] T039 [P] [US4] 實作 alertService.assignAlert()（驗證技師存在且 active；更新 assigned_to、assigned_at；status → in_progress）與 `PUT /api/alerts/:alertId/assign` 路由（422 TECHNICIAN_NOT_FOUND；404 ALERT_NOT_FOUND）→ `backend/src/services/alertService.ts`、`backend/src/routes/alerts.ts`
- [ ] T040 [P] [US4] 實作 alertService.resolveAlert()（驗證告警非 resolved；記錄 resolved_at；status → resolved）與 `PUT /api/alerts/:alertId/resolve` 路由（409 ALERT_ALREADY_RESOLVED）→ `backend/src/services/alertService.ts`、`backend/src/routes/alerts.ts`
- [ ] T041 [P] [US4] 實作 `GET /api/technicians` 路由（查詢 status=active 技師清單，供前端 AssignModal 下拉使用）→ `backend/src/routes/technicians.ts`

### 前端實作（US4）

- [ ] T042 [US4] 建立 alertStore（Zustand；儲存告警列表、篩選條件；支援樂觀更新指派 / 解除狀態）→ `frontend/src/stores/alertStore.ts`
- [ ] T043 [P] [US4] 建立 AlertTable 元件（欄位：告警 ID、設備編號、客戶、異常類型 label、發生時間、status badge、負責人；severity=high 列紅色背景；未指派標示置頂）→ `frontend/src/pages/AlertCenter/AlertTable.tsx`
- [ ] T044 [P] [US4] 建立 AlertFilter 元件（依狀態：未處理 / 處理中 / 已解除；依異常類型篩選）→ `frontend/src/pages/AlertCenter/AlertFilter.tsx`
- [ ] T045 [P] [US4] 建立 AssignModal 元件（技師下拉選擇器 Modal；呼叫 assign API；顯示指派結果回饋）→ `frontend/src/pages/AlertCenter/AssignModal.tsx`
- [ ] T046 [P] [US4] 建立 ResolveButton 元件（確認對話框 → 呼叫 resolve API → 更新 alertStore）→ `frontend/src/pages/AlertCenter/ResolveButton.tsx`
- [ ] T047 [US4] 組裝 AlertCenter 頁面（整合 AlertBanner + LastUpdatedBadge + AlertFilter + AlertTable + AssignModal + ResolveButton；整合 usePolling 30s 自動刷新）→ `frontend/src/pages/AlertCenter/AlertCenterPage.tsx`
- [ ] T091 [US4] US4 整合測試：告警中心 happy-path（GET /api/alerts → 驗未指派告警置頂、severity=high 排序正確；PUT /api/alerts/:id/assign → 驗 status 更新為 in_progress 並記錄 assigned_at；PUT /api/alerts/:id/resolve → 驗 resolved_at 正確記錄；AAA 模式；TDD：測試先於實作；**SC-002 人工驗收**：完成後需確認指派流程恰好 3 個互動步驟（點擊告警列 → 開啟 AssignModal 選擇技師 → 點擊確認），結果記錄於驗收報告）→ `backend/tests/integration/alerts.test.ts`
- [ ] T101 [P] [US4] US4 前端單元測試：AlertTable / AlertFilter / AssignModal / ResolveButton 元件（Vitest + Testing Library；測試項目：severity=high 列紅色背景渲染、未指派告警置頂排序、AssignModal 技師下拉選擇觸發 API 呼叫、ResolveButton 確認對話框流程；覆蓋率 ≥ 80%；TDD：測試先於元件實作）→ `frontend/tests/unit/AlertCenter/`

**Checkpoint**：US4 可獨立測試——告警列表排序正確；指派使狀態更新為「處理中」；解除正確記錄 resolved_at

---

## Phase 5：使用者故事 2 — 風險排序（Priority: P2）

**目標**：維運主管可快速看到 Top 10 高風險設備，了解風險主因與建議行動，追蹤排名變動

**獨立驗收測試**：帶入設備告警與健康分數資料 → Top 10 依風險分數降序；排名變動標示（↑/↓/−）符合預期

### 後端實作（US2）

- [ ] T048 [US2] 實作 riskScoreService（依 risk_score_weights 6 條規則計算：alert_severity 30% + recent_anomaly_7d 20% + offline_hours 20% + open_work_orders 15% + energy_anomaly 10% + overdue_maintenance 5%；寫回 `devices.risk_score`；記錄前次排名供 rankChange 計算）→ `backend/src/services/riskScoreService.ts`
- [ ] T049 [US2] 實作 `GET /api/risk/top-devices` 路由（Top 10 + riskReasons 陣列 + suggestedAction：≥70=緊急/≥40=本週/<40=本月 + rankChange/rankDelta；5 分鐘快取）→ `backend/src/routes/risk.ts`

### 前端實作（US2）

- [ ] T050 [P] [US2] 建立 RiskTable 元件（欄位：排名、設備編號、客戶、風險分數 badge、風險主因 tag 列表、建議行動標籤、RankChangeBadge；點擊列導向單機履歷）→ `frontend/src/pages/RiskRanking/RiskTable.tsx`
- [ ] T051 [P] [US2] 建立 RankBadge 元件（圓形排名數字；Top 3 金色 / 其餘白色）→ `frontend/src/pages/RiskRanking/RankBadge.tsx`
- [ ] T052 [P] [US2] 建立 RankChangeBadge 元件（↑ N 綠色 / ↓ N 紅色 / − 灰色）→ `frontend/src/pages/RiskRanking/RankChangeBadge.tsx`
- [ ] T053 [US2] 組裝 RiskRanking 頁面（整合 LastUpdatedBadge + RiskTable + RankBadge + RankChangeBadge；usePolling 30s 刷新）→ `frontend/src/pages/RiskRanking/RiskRankingPage.tsx`
- [ ] T092 [US2] US2 整合測試：風險排序 happy-path（GET /api/risk/top-devices → 驗回傳恰好 10 筆、依 risk_score 降序排列、每筆含 riskReasons 陣列與 suggestedAction 及 rankChange；AAA 模式；TDD：測試先於實作）→ `backend/tests/integration/risk.test.ts`
- [ ] T102 [P] [US2] US2 前端單元測試：RiskTable / RankBadge / RankChangeBadge 元件（Vitest；測試項目：Top 3 金色 badge 渲染、↑/↓/− 方向標示正確、建議行動標籤依分數正確顯示；覆蓋率 ≥ 80%；TDD：測試先於元件實作）→ `frontend/tests/unit/RiskRanking/`

**Checkpoint**：US2 可獨立測試——Top 10 排序正確；排名變動標示正確

---

## Phase 6：使用者故事 3 — 單機履歷（Priority: P2）

**目標**：維運工程師可查看單台設備的四個子頁籤（用電、運轉、異常、維修）完整歷史

**獨立驗收測試**：選定 DEV-001 → 設備標頭正確顯示；四個子頁籤各自正確載入時序資料；安裝未滿 30 天的設備圖表附說明文字

### 後端實作（US3）

- [ ] T054 [US3] 實作 `GET /api/devices/:deviceId` 路由（回傳 DeviceDetail 含 supportsCoP / supportsPressure；404 DEVICE_NOT_FOUND）→ `backend/src/routes/devices.ts`（附加）、`backend/src/services/deviceService.ts`（擴充）
- [ ] T055 [P] [US3] 實作 `GET /api/devices/:deviceId/power` 路由（優先查 InfluxDB `energy_daily_summary`，mock 設備讀 JSON；回傳 dailySummary + realtimePower；安裝不足 30 天僅回傳有資料的日期，不補空值）→ `backend/src/routes/devices.ts`（附加）
- [ ] T056 [P] [US3] 實作 `GET /api/devices/:deviceId/operation` 路由（查 `heatpump_daily_summary`；回傳 runHours、startupCount、avgCop；COP null 依 supportsCoP 標記處理）→ `backend/src/routes/devices.ts`（附加）
- [ ] T057 [P] [US3] 實作 `GET /api/devices/:deviceId/alerts` 路由（MySQL alerts 表分頁查詢，依 occurred_at DESC；含 alertType、severity、occurredAt、resolvedAt、description、resolutionNote）→ `backend/src/routes/devices.ts`（附加）
- [ ] T058 [P] [US3] 實作 `GET /api/devices/:deviceId/work-orders` 路由（MySQL work_orders 分頁查詢，依 dispatched_at DESC；含 woCode、status、assignedToName、dispatchedAt、completedAt、issueDesc、resolutionDesc）→ `backend/src/routes/devices.ts`（附加）

### 前端實作（US3）

- [ ] T059 [P] [US3] 建立 DeviceInfoCard 元件（設備頁頂部標頭：設備編號、型號、安裝日期、客戶、地點、StatusBadge；離線設備顯示最後心跳時間）→ `frontend/src/pages/DeviceHistory/DeviceInfoCard.tsx`
- [ ] T060 [P] [US3] 建立 PowerChart 元件（ECharts 折線圖；X 軸日期；Y 軸 kWh；anomalyFlag=true 日期紅色標記；安裝不足 30 天附「資料期間：安裝日 ～ 今日（共 N 天）」說明文字）→ `frontend/src/pages/DeviceHistory/PowerChart.tsx`
- [ ] T061 [P] [US3] 建立 OperationChart 元件（ECharts 雙 Y 軸圖；柱狀：每日開機次數；折線：COP 趨勢；supportsCoP=false 顯示「不適用」；cop=null + supportsCoP=true 顯示「--」）→ `frontend/src/pages/DeviceHistory/OperationChart.tsx`
- [ ] T062 [P] [US3] 建立 AlertTimeline 元件（時間軸列表；顯示發生時間、異常類型 label、severity badge、描述、持續時間、解除方式（resolutionNote：resolved 狀態顯示解除方式文字、未解除顯示「—」）；空狀態提示）→ `frontend/src/pages/DeviceHistory/AlertTimeline.tsx`
- [ ] T063 [P] [US3] 建立 WorkOrderList 元件（工單列表；欄位：工單號、優先級、指派技師、派工 / 完工時間、問題描述、處置方式；空狀態提示）→ `frontend/src/pages/DeviceHistory/WorkOrderList.tsx`
- [ ] T064 [US3] 組裝 DeviceHistory 頁面（頂部 DeviceInfoCard + 四個子頁籤：用電紀錄 / 運轉紀錄 / 異常紀錄 / 維修紀錄；頁籤切換不重新取設備標頭）→ `frontend/src/pages/DeviceHistory/DeviceHistoryPage.tsx`
- [ ] T093 [US3] US3 整合測試：單機履歷 happy-path（GET /api/devices/:deviceId → 驗基本資訊欄位完整；GET /api/devices/:deviceId/power → 驗 dailySummary 陣列及安裝不足 30 天邊界；GET /api/devices/:deviceId/alerts + /work-orders → 驗分頁正確；AAA 模式；TDD：測試先於實作）→ `backend/tests/integration/deviceHistory.test.ts`- [ ] T103 [P] [US3] US3 前端單元測試：PowerChart / OperationChart / AlertTimeline / WorkOrderList 元件（Vitest；測試項目：安裝未滿 30 天顯示說明文字、COP supportsCoP=false 顯示「不適用」、resolutionNote 未解除顯示「—」、空狀態提示；覆蓋率 ≥ 80%；TDD：測試先於元件實作）→ `frontend/tests/unit/DeviceHistory/`
**Checkpoint**：US3 可獨立測試——四個子頁籤各自顯示正確資料；ECharts 圖表在深色主題下清晰

---

## Phase 7：使用者故事 5 — 月報雛形（Priority: P3）

**目標**：維運主管可選擇月份查看設備健康摘要、異常統計、告警處理率，並匯出 PDF

**獨立驗收測試**：選定 2026-04 月份 → 健康分數平均值、異常分類統計、告警處理率各數字正確；「匯出 PDF」可下載含圖表的 PDF 檔

### 後端實作（US5）

- [ ] T066 [US5] 實作 reportService.getMonthlyReport()（聚合 MySQL：健康分數分布、異常類型統計、Top 5 異常設備、告警處理率；各計數同時附 ÷ 實際天數每日平均值；正確處理閏年與各月天數差異）→ `backend/src/services/reportService.ts`
- [ ] T067 [US5] 實作 `GET /api/reports/monthly` 路由（month=YYYY-MM 格式驗證；422 INVALID_MONTH；套用 authGuard；REPORT_CACHE_TTL 300s）→ `backend/src/routes/reports.ts`

### 前端實作（US5）

- [ ] T068 [P] [US5] 建立 MonthPicker 元件（月份選擇器；預設當月；選擇後觸發重新取資料）→ `frontend/src/pages/MonthlyReport/MonthPicker.tsx`
- [ ] T069 [P] [US5] 建立 HealthSummaryChart 元件（ECharts 柱狀分布圖：90-100 / 70-89 / 50-69 / 0-49 各段設備數；顯示整體平均分）→ `frontend/src/pages/MonthlyReport/HealthSummaryChart.tsx`
- [ ] T070 [P] [US5] 建立 AnomalyBarChart 元件（ECharts 水平長條圖；依異常類型分類；每類顯示月總量與每日平均值；列出 Top 5 異常設備清單）→ `frontend/src/pages/MonthlyReport/AnomalyBarChart.tsx`
- [ ] T071 [P] [US5] 建立 AlertRateCard 元件（顯示：告警總數、已解除率 %、平均解除時間（小時）、逾時未處理數；各計數附每日平均值）→ `frontend/src/pages/MonthlyReport/AlertRateCard.tsx`
- [ ] T072 [P] [US5] 建立 ExportPdfButton 元件（點擊後 html2canvas 截取 `#monthly-report` DOM；jsPDF 建立 A4 文件插入截圖；呼叫 `save('月報-YYYY-MM.pdf')` 觸發下載；期間顯示 Loading 狀態；≤ 30s 完成）→ `frontend/src/pages/MonthlyReport/ExportPdfButton.tsx`
- [ ] T073 [US5] 組裝 MonthlyReport 頁面（頂部 MonthPicker + ExportPdfButton；主體 id=`monthly-report`，依序排列：HealthSummaryChart + AnomalyBarChart + AlertRateCard）→ `frontend/src/pages/MonthlyReport/MonthlyReportPage.tsx`
- [ ] T094 [US5] US5 整合測試：月報 happy-path（GET /api/reports/monthly?month=YYYY-MM → 驗健康分數平均值與分布、異常統計 Top 5 設備、告警處理率欄位；閏年及 28/30/31 日月份每日平均值計算正確；AAA 模式；TDD：測試先於實作）→ `backend/tests/integration/reports.test.ts`- [ ] T104 [P] [US5] US5 前端單元測試：MonthPicker / HealthSummaryChart / AnomalyBarChart / AlertRateCard / ExportPdfButton 元件（Vitest；測試項目：月份切換觸發重新取資料、PDF 匯出按鈕顯示 Loading 狀態、每日平均値計算渲染正確；覆蓋率 ≥ 80%；TDD：測試先於元件實作）→ `frontend/tests/unit/MonthlyReport/`
**Checkpoint**：US5 可獨立測試——選擇月份後三個統計區塊正確顯示；PDF 匯出含所有圖表

---

## Phase 8：使用者故事 6 — 老闆決策頁（Priority: P3）

**目標**：公司高階主管可一頁掌握維運 KPI、技師負載、高風險客戶清單，及擴張承載能力評估

**獨立驗收測試**：帶入維運負載與客戶風險資料 → KPI 卡片數值正確；`maxSafeAddDevices` 計算符合公式（totalMaxCapacity × 0.95 − currentDevices）

### 後端實作（US6）

- [ ] T074 [US6] 實作 executiveService（KPI 計算：totalDevices / totalTechnicians / avgDevicesPerTech；technicianWorkload：每位技師 activeWorkOrders + completedThisMonth + utilizationRate（公式：`activeWorkOrders / MAX_WORK_ORDERS_PER_TECH × 100`）；擴張承載能力：maxSafeAddDevices = totalMaxCapacity × 0.95 - currentDevices（totalMaxCapacity = totalTechnicians × `MAX_DEVICES_PER_TECH`）；兩個設定項分別從 system_settings 讀取）→ `backend/src/services/executiveService.ts`
- [ ] T075 [US6] 實作 `GET /api/executive/summary` 路由（回傳 kpi + technicianWorkload + topRiskClients；套用 authGuard；TTL 300s）→ `backend/src/routes/executive.ts`
- [ ] T076 [P] [US6] 實作 `GET /api/executive/capacity` 路由（接受 addDevices query param；計算 projectedUtilization + maxSafeAddDevices + capacityCurve 0/5/10/15/20 節點）→ `backend/src/routes/executive.ts`（附加）
- [ ] T077 [P] [US6] 實作 `GET /api/risk/top-clients` 路由（Top 5 高風險客戶：clientName、deviceCount、alertCount、avgRiskScore、riskTier、suggestedAction）→ `backend/src/routes/risk.ts`（附加）

### 前端實作（US6）

- [ ] T078 [P] [US6] 建立 KpiCard 元件（三個核心 KPI 卡片：總設備數 / 維運人員數 / 每人平均設備數）→ `frontend/src/pages/ExecutiveDashboard/KpiCard.tsx`
- [ ] T079 [P] [US6] 建立 WorkloadTable 元件（每位技師：姓名、當前工單數、本月完成工單數、產能利用率進度條）→ `frontend/src/pages/ExecutiveDashboard/WorkloadTable.tsx`
- [ ] T080 [P] [US6] 建立 RiskClientList 元件（Top 5 高風險客戶：名稱、設備數、本月異常次數、風險評級 badge、建議行動）→ `frontend/src/pages/ExecutiveDashboard/RiskClientList.tsx`
- [ ] T081 [P] [US6] 建立 CapacityGauge 元件（ECharts 半圓儀表：目前產能利用率；折線圖：新增設備後預估負載曲線；標示 95% 安全承接上限）→ `frontend/src/pages/ExecutiveDashboard/CapacityGauge.tsx`
- [ ] T082 [US6] 組裝 ExecutiveDashboard 頁面（頂部 KpiCard × 3；中段 WorkloadTable + RiskClientList；底部 CapacityGauge + addDevices 試算輸入框）→ `frontend/src/pages/ExecutiveDashboard/ExecutiveDashboardPage.tsx`
- [ ] T095 [US6] US6 整合測試：老闆決策頁 happy-path（GET /api/executive/summary → 驗 kpi 欄位、technicianWorkload 長度符合技師人數、topRiskClients 恰好 5 筆；GET /api/executive/capacity?addDevices=10 → 驗 maxSafeAddDevices = totalMaxCapacity × 0.95 − currentDevices 公式正確；AAA 模式；TDD：測試先於實作）→ `backend/tests/integration/executive.test.ts`
- [ ] T105 [P] [US6] US6 前端單元測試：KpiCard / WorkloadTable / RiskClientList / CapacityGauge 元件（Vitest；測試項目：KPI 數値格式化渲染、產能利用率進度條寬度計算、風險評級 badge 渲染、CapacityGauge 95% 安全線標示；覆蓋率 ≥ 80%；TDD：測試先於元件實作）→ `frontend/tests/unit/ExecutiveDashboard/`

**Checkpoint**：US6 可獨立測試——三個核心區塊正確顯示；產能試算邏輯符合公式

---

## Phase 9：收尾與橫切面（Polish）

**目標**：效能優化、過期資料提示、風險規則管理端點、全端整合驗證

- [ ] T083 實作後端 API 回應快取 HTTP 標頭中介軟體（設定 `Cache-Control` 標頭供瀏覽器 / CDN 使用：設備列表 25s、月報與歷史資料 300s；**注意**：此中介軟體僅負責 HTTP 標頭層快取；各 service 層已獨立使用 node-cache 作為伺服器端記憶體快取（T030 25s / T037 10s / T049 5min / T067 300s），兩層職責不同、互不衝突）→ `backend/src/middleware/cache.ts`
- [ ] T084 [P] 實作前端過期資料偵測工具函式（比較回應時間戳與現在時間；超過 TTL 顯示「資料可能過期」標籤；快取值保留至 API 恢復）→ `frontend/src/utils/staleDataHelper.ts`
- [ ] T085 [P] 實作 `GET /api/risk/rules` 與 `PUT /api/risk/rules` 端點（PUT 驗證啟用規則 weight 加總 = 100；422 INVALID_WEIGHT_SUM：「啟用的權重加總必須等於 100，目前為 N」）→ `backend/src/routes/risk.ts`（附加）
- [ ] T086 [P] 確認深色主題一致性（全部 6 頁使用 Tailwind 設計 Token；ECharts 圖表設定深色背景 + 高對比色；WCAG 2.1 AA 對比度驗證）
- [ ] T087 [P] 確認離線設備跨頁一致顯示（即時數值欄位顯示「--」；StatusBadge 灰色；附最後心跳時間戳；跨 DeviceList、AlertCenter、RiskRanking 一致）
- [ ] T088 [P] 對全專案執行 ESLint + Prettier 最終校正（frontend/ + backend/；確認 Constitution I 通過）
- [ ] T096 [P] 建立 CI 效能基準測試腳本（`GET /api/devices` p95 ≤500ms + `GET /api/alerts` p95 ≤500ms；採用 Autocannon 腳本於 local Docker 環境執行；整合至 CI pipeline，PR 觸發條件：修改 routes/devices.ts 或 routes/alerts.ts；確認 Constitution IV 合規）→ `backend/tests/performance/benchmark.ts`、`.github/workflows/perf.yml`
- [ ] T097 [P] 驗收告警中心 SC-004 效能（80 筆告警下頁面載入 ≤3 秒）：seed 80 筆 mock 告警，Supertest 量測 `GET /api/alerts?limit=50` p95 ≤500ms；確認 node-cache TTL 10s 快取命中；人工驗收前端 AlertCenter 首次載入達標，記錄截圖至 `docs/perf-sc004.png` → `backend/tests/performance/alertCenter.perf.ts`
- [ ] T098 [P] 驗收月報 PDF SC-003 效能（SC-003：PDF 產生 ≤30 秒）：於前端開發環境以計時腳本截取完整 `#monthly-report` DOM 並量測 `jsPDF.save()` 完成時間；若平均超過 30s，分析 html2canvas 渲染瓶頸（imageQuality 調整、圖層拆分）；人工驗收後記錄截圖至 `docs/perf-sc003.png` → `frontend/src/utils/pdfPerfTest.ts`
- [ ] T099 [P] 驗證前後端測試覆蓋率達標（Constitution II）：**前置條件：T100–T105 前端單元測試任務須已完成**；前端執行 `vitest run --coverage` 驗證各模組覆蓋率 ≥ 80%；後端執行 `jest --coverage --coverageThreshold` 驗證相同門櫛；CI pipeline（`.github/workflows/ci.yml`）整合覆蓋率閥値檢查，低於門櫛則阻斷 PR 合並；輸出 lcov 格式報告 → `frontend/vite.config.ts`（coverage 設定）、`backend/jest.config.ts`（coverageThreshold）、`.github/workflows/ci.yml`
- [ ] T089 驗證 Docker Compose 全端整合啟動（nginx 代理、前後端連線、健康檢查端點回應 healthy）→ `docker/docker-compose.yml`

---

## 依賴關係圖

```
Phase 1（Setup）
    └── Phase 2（Foundational：DB Schema + Auth + React 骨架）
            ├── Phase 3（US1 設備總覽 P1）🎯 MVP
            ├── Phase 4（US4 告警中心 P1）
            │       └─ alertService 使用 devices 表做設備存在驗證
            ├── Phase 5（US2 風險排序 P2）
            │       └─ riskScoreService 依賴 alerts + work_orders 資料
            ├── Phase 6（US3 單機履歷 P2）
            │       └─ device routes 共用同一 Router 檔（devices.ts）
            ├── Phase 7（US5 月報雛形 P3）
            │       └─ reportService 聚合 alerts + devices 月度資料
            └── Phase 8（US6 老闆決策頁 P3）
                    └─ executiveService 依賴 work_orders + riskScoreService

Phase 9（Polish）
    └─ 依賴所有前序 Phase 完成後整合
```

### 各故事可平行執行示範

- **Phase 3 + Phase 4 可同時進行**：後端各自獨立 service，前端各自獨立 page 目錄
- **Phase 5 + Phase 6 可同時進行**：riskScoreService 與 deviceHistory routes 互不依賴
- **Phase 7 + Phase 8 可同時進行**：reportService 與 executiveService 互不依賴

---

## 實作策略

### MVP 建議範圍（Phase 1 ～ Phase 3）

| 里程碑 | 交付內容 | 累計任務數 |
|--------|----------|-----------|
| M1 MVP | 登入 + 設備總覽 | ~39 個任務（Phase 1–3）|
| M2 P1 完成 | + 告警中心 | ~52 個任務（+ Phase 4）|
| M3 P2 完成 | + 風險排序 + 單機履歷 | ~73 個任務（+ Phase 5–6）|
| M4 全功能 | + 月報 + 老闆決策頁 + 收尾 | 105 個任務（+ Phase 7–9）|

### 漸進式交付原則

1. **MVP 優先**：Phase 1 + 2 + 3（US1 設備總覽）即可完成第一個可展示增量
2. **P1 衝刺**：加入 US4（告警中心），系統具備維運核心功能
3. **P2 擴充**：加入 US2 + US3，強化診斷能力（風險排序 + 單機履歷）
4. **P3 完整**：加入 US5 + US6，完成報告與策略層功能
5. **品質保證**：Constitution II 要求 TDD 用於 API handler 與風險分數計算；後端任務中已於各 US Phase 含入 deviceService / alertService / riskScoreService 的單元測試責任

---

## 任務計數摘要

| Phase | 任務數 | 說明 |
|-------|--------|------|
| Phase 1: Setup | 6（T001–T006）| 專案初始化 |
| Phase 2: Foundational | 25（T007–T029、T065、T106）| 後端 + 前端基礎建設 + Auth + 每日彙總工作 |
| Phase 3: US1 設備總覽 | 9（T030–T036、T090、T100）| P1 🎯 MVP |
| Phase 4: US4 告警中心 | 13（T037–T047、T091、T101）| P1 |
| Phase 5: US2 風險排序 | 8（T048–T053、T092、T102）| P2 |
| Phase 6: US3 單機履歷 | 13（T054–T064、T093、T103）| P2 |
| Phase 7: US5 月報雛形 | 10（T066–T073、T094、T104）| P3 |
| Phase 8: US6 老闆決策頁 | 11（T074–T082、T095、T105）| P3 |
| Phase 9: Polish | 11（T083–T089、T096–T099）| 收尾 |
| **合計** | **106** | |

**平行機會**：106 個任務中，標記 [P] 的任務共 **54 個**，可大幅縮短實際開發時程。

**建議 MVP 範圍**：Phase 1 + Phase 2 + Phase 3（T001–T036、T065、T106、T090、T100），共 40 個任務，交付設備總覽核心功能。
