---
description: "Task list for 熱泵／熱水系統監控儀表板（6 頁）"
---

# Tasks: 熱泵／熱水系統監控儀表板（6 頁）

**Input**: Design documents from `/specs/001-heatpump-dashboard-6pages/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

> **語言規範（Constitution V）**：本任務清單使用繁體中文（zh-TW）撰寫，與 spec.md 及 plan.md 保持一致。

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: 可平行執行（不同檔案，無相依未完成任務）
- **[Story]**: 對應使用者故事（US1–US6，對應 spec.md 優先順序）
- 說明中含完整檔案路徑

## 依賴關係

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational) ← 所有 US 的阻塞性先決條件
    ↓
Phase 3 (US1 P1) ──┐
Phase 4 (US4 P1) ──┤ 可在 Phase 2 完成後平行實作
Phase 5 (US2 P2) ──┤
Phase 6 (US3 P2) ──┤
Phase 7 (US5 P3) ──┤
Phase 8 (US6 P3) ──┘
    ↓
Final Phase (Polish)
```

---

## Phase 1: Setup（專案初始化）

**Purpose**: 建立 Monorepo 目錄結構、安裝所有依賴、設定開發工具鏈與 Docker 基礎架構

- [ ] T001 建立 Monorepo 目錄結構：`frontend/`、`backend/`、`mock-data/devices/`、`docker/`、`scripts/`（依 plan.md 專案結構）
- [ ] T002 初始化前端專案：在 `frontend/` 執行 `npm create vite@latest . -- --template react-ts`，安裝 react-router-dom@6、recharts、zustand、axios、jspdf、html2canvas 及相關 TypeScript 型別套件至 `frontend/package.json`
- [ ] T003 初始化後端專案：在 `backend/` 執行 `npm init -y`，安裝 fastify@4、@fastify/jwt、@fastify/cookie、@fastify/cors、@fastify/rate-limit、influx@5、drizzle-orm、drizzle-kit、mysql2、node-cache、node-cron、bcryptjs 及相關 TypeScript 型別套件至 `backend/package.json`
- [ ] T004 [P] 設定根目錄 ESLint + Prettier（TypeScript strict mode）：`eslint.config.mjs`、`.prettierrc`、根目錄 `tsconfig.base.json`（strict: true, target: ES2022）
- [ ] T005 [P] 設定前端 `frontend/tsconfig.json` 繼承根目錄 base，設定 Vite path alias；設定後端 `backend/tsconfig.json` 繼承根目錄 base，加入 `paths` 與 `outDir: dist`
- [ ] T006 [P] 設定前端測試框架：Vitest + @vitest/coverage-v8（coverage ≥ 80%）於 `frontend/vitest.config.ts`，建立 `frontend/tests/` 目錄
- [ ] T007 [P] 設定後端測試框架：Node.js built-in test runner + supertest，設定 `backend/package.json` test script，建立 `backend/tests/unit/`、`backend/tests/integration/` 目錄
- [ ] T007a [P] 建立 CI 流程設定（GitHub Actions）：在 `.github/workflows/ci.yml` 設定 PR 觸發 workflow，依序執行 lint（eslint）、前端測試（vitest --coverage，coverage ≥ 80% 為 fail threshold）、後端測試（node --test + supertest）、效能基準（autocannon `GET /api/alerts?limit=80` p95 ≤ 500 ms 斷言）；任何步驟失敗均 block merge
- [ ] T008 建立 Docker Compose 設定（frontend :3000、backend-api :3001、nginx :80）於 `docker/docker-compose.yml`
- [ ] T009 [P] 建立 Nginx 反向代理設定：`/api/*` 代理至 backend-api:3001，`/*` 服務 React SPA 於 `docker/nginx.conf`
- [ ] T010 [P] 建立環境變數範本（含 JWT_SECRET、MYSQL_*、INFLUXDB_*、DEVICE_CACHE_TTL=25、REPORT_CACHE_TTL=300、MAX_DEVICES_PER_TECH=20）於 `docker/env.example`
- [ ] T011 [P] 建立根目錄 `.gitignore`（排除 `docker/.env`、`node_modules/`、`dist/`、`coverage/`）
- [ ] T012 建立根目錄 `package.json` workspace scripts（`dev:frontend`、`dev:backend`、`build`、`test`）

**Checkpoint**: 開發工具鏈就緒，可開始後端與前端基礎建設

---

## Phase 2: Foundational（共用基礎建設）

**Purpose**: 後端伺服器、資料庫連線、認證機制、Mock 資料載入、前端路由與版面骨架，為所有使用者故事提供阻塞性先決條件

**⚠️ CRITICAL**: 所有使用者故事均須等此 Phase 完成後才可開始

### 後端基礎建設

- [ ] T013 建立後端環境變數載入器（讀取 process.env，含型別驗證與預設值）於 `backend/src/config/env.ts`
- [ ] T014 定義所有 Drizzle ORM schema（對應 data-model.md DDL：clients、sites、devices、meters、device_meter_mappings、alerts、work_orders、technicians、users、system_settings、risk_score_weights）於 `backend/src/db/schema.ts`
- [ ] T015 建立 MySQL 8.0 連線（mysql2）與 Drizzle client 實例於 `backend/src/db/index.ts`；建立 Drizzle 設定檔 `backend/drizzle.config.ts`
- [ ] T016 [P] 建立 InfluxDB 1.8 client 實例（influx@5）及 InfluxQL 查詢輔助函式（`executeQuery<T>`, `executeQueryRaw`）於 `backend/src/influx/client.ts`
- [ ] T017 [P] 定義所有後端共用 TypeScript DTO 型別（對應 contracts/ 所有 API 回應：DeviceDTO、DeviceDetailDTO、AlertDTO、RiskDeviceDTO、MonthlyReportDTO、ExecutiveSummaryDTO、CapacityDTO 等）於 `backend/src/types/index.ts`
- [ ] T018 [P] 建立 node-cache 實例與快取輔助函式（`getOrSet<T>`, `invalidate`）於 `backend/src/config/cache.ts`
- [ ] T019 建立 Fastify 伺服器（app.ts）：註冊 @fastify/cors、@fastify/jwt（httpOnly cookie）、@fastify/cookie、@fastify/rate-limit，設定全域 setErrorHandler（統一 JSON 錯誤格式 `{ error, message, statusCode }`）於 `backend/src/app.ts`
- [ ] T020 實作 JWT 認證 preHandler hook：驗證 httpOnly cookie `hp_token`，無效 token 返回 401 `UNAUTHORIZED` 於 `backend/src/auth/authGuard.ts`
- [ ] T021 實作認證路由（POST /api/auth/login：bcrypt 密碼驗證、設定 httpOnly cookie、rate-limit 10次/分；POST /api/auth/logout：清除 cookie；GET /api/auth/me）於 `backend/src/routes/auth.ts`
- [ ] T022 [P] 建立系統狀態路由（GET /api/system/health、GET /api/system/last-updated）於 `backend/src/routes/system.ts`
- [ ] T023 建立 MySQL schema migration runner 與 DB seed 腳本（初始化 clients、sites、devices 80 台、technicians、users、risk_score_weights）於 `backend/src/db/migrate.ts` 與 `backend/src/db/seed.ts`
- [ ] T024 建立 Mock 資料產生器腳本：批次產生 73 個 Mock JSON（DEV-008 ～ DEV-080），每份含設備資訊、目前狀態、30 日用電歷史、運轉歷史、告警紀錄，並隨機化數值於 `scripts/generateMockData.ts`
- [ ] T025 建立 Mock 資料載入器：伺服器啟動時一次讀取 `mock-data/devices/*.json` 並常駐記憶體；提供 `getMockDevice(id)`、`getMockDeviceList()` 方法於 `backend/src/services/mockDataLoader.ts`
- [ ] T026 建立 DataSourceRouter：依 `data_source_type`（real / mock）將設備查詢路由至 InfluxDB/MySQL 或 Mock JSON；提供 `getDeviceRealtimeStatus(id)`、`getDeviceHistory(id, type)` 方法於 `backend/src/services/dataSourceRouter.ts`

### 前端基礎建設

- [ ] T027 設定 Vite 開發代理 `/api` → `http://localhost:3001` 於 `frontend/vite.config.ts`
- [ ] T028 建立 React Router 路由設定（Login、DeviceOverview、RiskRanking、DeviceDetail、AlertCenter、MonthlyReport、Executive 共 7 條路由）於 `frontend/src/main.tsx`
- [ ] T029 建立全域深色主題 CSS 變數與設計 token（深綠黑底色 `--color-bg`、黃綠強調色 `--color-accent`、狀態語意色 `--color-status-normal/alert/offline/maintenance`）於 `frontend/src/styles/theme.css`
- [ ] T030 [P] 建立共用版面元件：左側持續顯示的 Sidebar 導覽（6 頁連結）+ 頂部最後更新時間 Header 於 `frontend/src/components/Layout.tsx`
- [ ] T031 [P] 建立 StatusBadge 共用元件（顏色語意：綠＝normal、紅＝alert、灰＝offline、橘＝maintenance）於 `frontend/src/components/StatusBadge.tsx`
- [ ] T032 [P] 建立 Axios 實例（帶 withCredentials=true、baseURL=/api）於 `frontend/src/services/api.ts`
- [ ] T033 [P] 建立前端共用 TypeScript 型別（與 backend/src/types/index.ts 對齊：DeviceDTO、AlertDTO、RiskDeviceDTO 等）於 `frontend/src/types/index.ts`
- [ ] T034 [P] 建立 Zustand 輪詢 store（30 秒定時器、startPolling、stopPolling actions）於 `frontend/src/stores/pollingStore.ts`
- [ ] T035 [P] 建立 Zustand 設備 store（devices 陣列、filters 狀態、setDevices、setFilters actions）於 `frontend/src/stores/devicesStore.ts`
- [ ] T036 [P] 建立 Zustand 告警 store（alerts 陣列、filters 狀態、setAlerts、updateAlert actions）於 `frontend/src/stores/alertsStore.ts`
- [ ] T037 建立 LoginPage 元件（帳號/密碼表單 + 登入 API 呼叫）與 AuthGuard HOC（未登入重導至 /login）於 `frontend/src/pages/LoginPage.tsx` 與 `frontend/src/components/AuthGuard.tsx`
- [ ] T038 建立前端認證 API service（login、logout、getMe）於 `frontend/src/services/authService.ts`

**Checkpoint**: 基礎建設完成，所有使用者故事可開始平行實作

---

## Phase 3: User Story 1 — 設備總覽（Priority: P1）🎯 MVP

**Goal**: 工程師可查看 80 台設備的狀態列表，依狀態篩選、依關鍵字搜尋，並點擊進入單機履歷頁

**Independent Test**: 帶入 80 台設備 mock 資料後，驗證 `GET /api/devices` 回傳正確列表、狀態篩選有效、點擊導向 `/devices/:id`

### 後端實作

> **Constitution II 規範**：整合測試任務 T043 必須先撰寫並確認失敗後，再開始對應實作任務。

- [ ] T043 [P] [US1] ⚠️ 先行撰寫（Red-Green-Refactor）：撰寫 devices 端點整合測試（驗證回傳 80 筆、status 篩選、search 搜尋）於 `backend/tests/integration/devices.test.ts`
- [ ] T039 [US1] 實作 `DeviceService.getDeviceList()`（讀取 MySQL + Mock JSON 彙整、依 status/search 篩選、依 alert→maintenance→offline→normal + riskScore 排序、node-cache TTL 25s）於 `backend/src/services/deviceService.ts`
- [ ] T040 [US1] 實作 GET /api/devices 路由 handler（套用 authGuard、解析 query params：status、search、page、limit）於 `backend/src/routes/devices.ts`
- [ ] T041 [US1] 實作 `DeviceService.getDeviceById()`（MySQL 查詢 + mock fallback、回傳 DeviceDetailDTO）於 `backend/src/services/deviceService.ts`
- [ ] T042 [US1] 實作 GET /api/devices/:deviceId 路由 handler（404 DEVICE_NOT_FOUND 錯誤處理）於 `backend/src/routes/devices.ts`

### 前端實作

- [ ] T044 [P] [US1] 建立前端 devices API service（`getDevices(filters)`, `getDeviceById(id)`）於 `frontend/src/services/deviceService.ts`
- [ ] T045 [P] [US1] 建立 DeviceFilters 元件（狀態 select 篩選 + 搜尋 input）於 `frontend/src/components/DeviceFilters.tsx`
- [ ] T046 [P] [US1] 建立 DeviceTable 元件（欄位：設備編號、客戶名稱、地點、StatusBadge、最後心跳時間；可點擊列）於 `frontend/src/components/DeviceTable.tsx`
- [ ] T047 [US1] 建立 DeviceOverviewPage 頁面元件：整合 DeviceFilters + DeviceTable + pollingStore（30s 自動刷新）+ 點擊列導向 `/devices/:id` 於 `frontend/src/pages/DeviceOverviewPage.tsx`

**Checkpoint**: DeviceOverviewPage 可獨立運作並測試，80 台設備完整顯示

---

## Phase 4: User Story 4 — 告警中心（Priority: P1）

**Goal**: 值班工程師可查看所有告警、依狀態/類型篩選、指派技師、更新狀態為已解除；高嚴重性告警視覺突出

**Independent Test**: 帶入模擬告警資料，驗證 assign + resolve API 正確更新狀態，前端列表即時反映異動

### 後端實作

> **Constitution II 規範**：整合測試任務 T054、T054a 必須先撰寫並確認失敗後，再開始對應實作任務。

- [ ] T054 [P] [US4] ⚠️ 先行撰寫（Red-Green-Refactor）：撰寫 alerts 端點整合測試（驗證 assign 流程、resolve 流程、409 重複解除、GET /api/technicians 回傳 active 人員清單）於 `backend/tests/integration/alerts.test.ts`
- [ ] T054a [P] [US4] ⚠️ 先行撰寫（SC-004 效能基準）：撰寫告警中心效能基準測試（使用 `autocannon`：情境為 80 台設備同時各有 1 筆 pending alert、並發 10 個請求、持續 10s；斷言 `GET /api/alerts` p95 回應時間 ≤ 500 ms）於 `backend/tests/perf/alerts-load.test.ts`；此測試須整合至 CI workflow（T007a）
- [ ] T048 [US4] 實作 `AlertService.getAlerts()`（依 status/alert_type/severity 篩選、排序：未指派置頂→severity→occurredAt DESC、node-cache TTL 10s）於 `backend/src/services/alertService.ts`
- [ ] T049 [US4] 實作 GET /api/alerts 路由 handler（套用 authGuard、支援 status/alert_type/severity/page/limit query params）於 `backend/src/routes/alerts.ts`
- [ ] T050 [US4] 實作 `AlertService.assignAlert(alertId, technicianId)`（驗證技師存在且 active、更新 status→in_progress、記錄 assigned_at）於 `backend/src/services/alertService.ts`
- [ ] T051 [US4] 實作 PUT /api/alerts/:alertId/assign 路由 handler（404 ALERT_NOT_FOUND、422 TECHNICIAN_NOT_FOUND 錯誤處理）於 `backend/src/routes/alerts.ts`
- [ ] T052 [US4] 實作 `AlertService.resolveAlert(alertId, resolutionNote)`（驗證告警非 resolved 狀態、更新 status→resolved、記錄 resolved_at）於 `backend/src/services/alertService.ts`
- [ ] T053 [US4] 實作 PUT /api/alerts/:alertId/resolve 路由 handler（409 ALERT_ALREADY_RESOLVED 錯誤處理）於 `backend/src/routes/alerts.ts`
- [ ] T053a [P] [US4] 實作 GET /api/technicians 路由 handler（套用 authGuard；查詢 technicians 表 status=active 的人員清單，回傳 `{ id, name, employeeCode }[]`；供前端指派告警 modal 的下拉選單使用）於 `backend/src/routes/technicians.ts`

### 前端實作

- [ ] T055 [P] [US4] 建立前端 alerts API service（`getAlerts(filters)`, `assignAlert(id, techId)`, `resolveAlert(id, note)`）於 `frontend/src/services/alertService.ts`
- [ ] T056 [P] [US4] 建立 AlertFilters 元件（status select + alert_type select）於 `frontend/src/components/AlertFilters.tsx`
- [ ] T057 [P] [US4] 建立 AlertRow 元件（欄位：ID、設備、客戶、類型、時間、status badge、負責人；高嚴重性 severity=high 紅色背景；未指派置頂標示）於 `frontend/src/components/AlertRow.tsx`
- [ ] T058 [US4] 建立 AlertCenterPage 頁面元件：整合 AlertFilters + AlertRow 列表 + pollingStore（30s 刷新）+ 指派技師 modal + 解除告警 action 於 `frontend/src/pages/AlertCenterPage.tsx`

**Checkpoint**: AlertCenterPage 可獨立運作，指派與解除流程完整

---

## Phase 5: User Story 2 — 風險排序（Priority: P2）

**Goal**: 主管可查看 Top 10 高風險設備，依風險分數排序，了解風險主因與建議行動，追蹤排名變動

**Independent Test**: 帶入設備告警與健康分數資料，驗證 Top 10 依 riskScore 降序排列，rankChange 標示正確

### 後端實作

> **Constitution II 規範**：整合測試任務 T063 必須先撰寫並確認失敗後，再開始對應實作任務。

- [ ] T063 [P] [US2] ⚠️ 先行撰寫（Red-Green-Refactor）：撰寫 risk 端點整合測試（驗證 Top 10 排序、suggestedAction 分類邏輯）於 `backend/tests/integration/risk.test.ts`
- [ ] T059 [US2] 實作 `RiskService.calculateRiskScore(device)`（依 risk_score_weights 表中規則：alert_severity × 30 + consecutive_alerts × 25 + pending_work_orders × 20 + offline_hours × 15 + energy_anomaly × 10 等）於 `backend/src/services/riskService.ts`
- [ ] T060 [US2] 實作 `RiskService.getTopDevices()`（計算全部設備分數、取前 10、比對前次排名計算 rankChange/rankDelta、依 riskScore 判斷 suggestedAction：≥70=緊急/≥40=本週/<40=本月）於 `backend/src/services/riskService.ts`
- [ ] T061 [US2] 實作 GET /api/risk/top-devices 路由 handler（套用 authGuard）於 `backend/src/routes/risk.ts`
- [ ] T062 [P] [US2] 實作 GET /api/risk/rules 與 PUT /api/risk/rules 路由 handler（weight sum 驗證：enabled 規則加總必須 = 100、422 INVALID_WEIGHT_SUM）於 `backend/src/routes/risk.ts`

### 前端實作

- [ ] T064 [P] [US2] 建立前端 risk API service（`getTopDevices()`, `getRules()`, `updateRules(rules)`）於 `frontend/src/services/riskService.ts`
- [ ] T065 [P] [US2] 建立 RiskCard 元件（排名、設備編號、客戶名稱、風險分數、風險主因 tags、建議行動 badge、rankChange 箭頭 ↑↓）於 `frontend/src/components/RiskCard.tsx`
- [ ] T066 [US2] 建立 RiskRankingPage 頁面元件：整合 RiskCard 清單（Top 10）+ pollingStore（30s 刷新）+ 點擊 RiskCard 導向 `/devices/:id` 於 `frontend/src/pages/RiskRankingPage.tsx`

**Checkpoint**: RiskRankingPage 可獨立運作，Top 10 清單與排名變動顯示正確

---

## Phase 6: User Story 3 — 單機履歷（Priority: P2）

**Goal**: 工程師可查看單台設備的 4 個子頁籤（用電、運轉、異常、維修），包含 30 日折線圖與歷史列表

**Independent Test**: 選定 DEV-001，帶入歷史資料，驗證 4 個子頁籤 API 各自回傳正確的時序資料與統計摘要

### 後端實作

> **Constitution II 規範**：整合測試任務 T073 必須先撰寫並確認失敗後，再開始對應實作任務。

- [ ] T073 [P] [US3] ⚠️ 先行撰寫（Red-Green-Refactor）：撰寫 device detail 端點整合測試（驗證 power/operation 回傳 30 日資料、alerts/work-orders 分頁正確）於 `backend/tests/integration/deviceDetail.test.ts`
- [ ] T067 [US3] 實作 `DeviceService.getDevicePowerHistory(deviceId, from, to)`（從 InfluxDB `energy_daily_summary` 查詢 30 日每日彙總 + 從 `power_meter` 查即時資料；mock 設備從 JSON 讀取；安裝未滿 30 天只回傳有資料的日期）於 `backend/src/services/deviceService.ts`
- [ ] T068 [US3] 實作 GET /api/devices/:deviceId/power 路由 handler（from/to query params 解析，預設 30 天前至今）於 `backend/src/routes/devices.ts`
- [ ] T069 [US3] 實作 `DeviceService.getDeviceOperationHistory(deviceId, from, to)`（從 InfluxDB `heatpump_daily_summary` 查詢 30 日彙總 + 即時狀態；支援 supportsCoP/supportsPressure null 處理）於 `backend/src/services/deviceService.ts`
- [ ] T070 [US3] 實作 GET /api/devices/:deviceId/operation 路由 handler 於 `backend/src/routes/devices.ts`
- [ ] T071 [P] [US3] 實作 GET /api/devices/:deviceId/alerts 路由 handler（從 MySQL alerts 表分頁查詢，依 occurred_at DESC）於 `backend/src/routes/devices.ts`
- [ ] T072 [P] [US3] 實作 GET /api/devices/:deviceId/work-orders 路由 handler（從 MySQL work_orders 表分頁查詢，依 dispatched_at DESC）於 `backend/src/routes/devices.ts`

### 前端實作

- [ ] T074 [P] [US3] 建立前端 deviceDetail API service（`getDevicePower(id, from, to)`, `getDeviceOperation(id, from, to)`, `getDeviceAlerts(id, params)`, `getDeviceWorkOrders(id, params)`）於 `frontend/src/services/deviceDetailService.ts`
- [ ] T075 [P] [US3] 建立 PowerChart 元件（Recharts LineChart：x 軸日期、y 軸 kwhTotal、anomalyFlag=true 資料點標記紅點；無資料日期不補空值）於 `frontend/src/components/PowerChart.tsx`
- [ ] T076 [P] [US3] 建立 OperationChart 元件（Recharts ComposedChart：左 y 軸運轉時數折線、右 y 軸開機次數柱狀、COP 趨勢折線；supportsCoP=false 顯示「不適用」）於 `frontend/src/components/OperationChart.tsx`
- [ ] T077 [P] [US3] 建立 AlertTimeline 元件（時間軸列表：發生時間、告警類型 badge、描述、持續時間、解除方式；空狀態提示）於 `frontend/src/components/AlertTimeline.tsx`
- [ ] T078 [P] [US3] 建立 WorkOrderList 元件（列表：工單編號、派工/完工時間、技師姓名、問題描述、處置方式；空狀態提示）於 `frontend/src/components/WorkOrderList.tsx`
- [ ] T079 [US3] 建立 DeviceDetailPage 頁面元件：頂部設備基本資訊區塊（編號、型號、安裝日期、客戶、地點、StatusBadge）+ 4 個 Tab（用電/運轉/異常/維修）分別渲染對應元件於 `frontend/src/pages/DeviceDetailPage.tsx`

**Checkpoint**: DeviceDetailPage 4 個子頁籤均可獨立顯示，圖表與清單正確渲染

---

## Phase 7: User Story 5 — 月報雛形（Priority: P3）

**Goal**: 主管可選擇月份查看設備健康分數摘要、異常統計、告警處理率，並匯出為 PDF

**Independent Test**: 選定 2026-04，帶入該月資料，驗證健康分數平均值、異常次數與已解除率各數字正確計算並完整顯示

### 後端實作

> **Constitution II 規範**：整合測試任務 T083 必須先撰寫並確認失敗後，再開始對應實作任務。

- [ ] T083 [P] [US5] ⚠️ 先行撰寫（Red-Green-Refactor）：撰寫 monthly report 端點整合測試（驗證 alertStats 計算邏輯、anomalyStats byType 正確）於 `backend/tests/integration/reports.test.ts`
- [ ] T080 [US5] 實作 `ReportService.getMonthlyReport(month)`（從 MySQL 計算 alertStats：總數/已解除率/平均解除時間/逾時數；從 devices 計算 deviceHealthSummary：平均 riskScore 轉健康分數（healthScore = 100 - riskScore）、分布計算；從 alerts 統計 anomalyStats：按類型分類、Top 5 設備）於 `backend/src/services/reportService.ts`
- [ ] T081 [US5] 實作 GET /api/reports/monthly 路由 handler（month=YYYY-MM 參數驗證、422 INVALID_MONTH；套用 authGuard；REPORT_CACHE_TTL 300s 快取）於 `backend/src/routes/reports.ts`
- [ ] T082 [P] [US5] 建立 node-cron 每日彙總 Job（每日 00:05 執行：讀取 InfluxDB `heatpump_status`/`power_meter`，彙整後寫入 `energy_daily_summary` 與 `heatpump_daily_summary` measurements）於 `backend/src/jobs/dailySummaryJob.ts`

### 前端實作

- [ ] T084 [P] [US5] 建立前端 reports API service（`getMonthlyReport(month)`）於 `frontend/src/services/reportService.ts`
- [ ] T085 [P] [US5] 建立 HealthScoreDistributionChart 元件（Recharts BarChart：4 個分數區間 90-100/70-89/50-69/0-49 各自設備數量）於 `frontend/src/components/HealthScoreDistributionChart.tsx`
- [ ] T086 [P] [US5] 建立 AnomalyTypeChart 元件（Recharts BarChart：各 alertType 異常次數橫條圖）於 `frontend/src/components/AnomalyTypeChart.tsx`
- [ ] T087 [P] [US5] 建立 TopAnomalyDevicesTable 元件（前 5 台異常最多設備：設備碼、客戶名、異常次數）於 `frontend/src/components/TopAnomalyDevicesTable.tsx`
- [ ] T088 [US5] 建立 MonthlyReportPage 頁面元件：月份選擇器 + 健康分數摘要區塊（avgScore + DistributionChart）+ 異常統計區塊（AnomalyTypeChart + TopAnomalyDevicesTable）+ 告警處理率區塊（resolvedRate、avgResolveHours、overdueCount）+ 「匯出 PDF」按鈕於 `frontend/src/pages/MonthlyReportPage.tsx`
- [ ] T089 [US5] 實作 PDF 匯出功能：`html2canvas` 截取 `#monthly-report` DOM 節點為 canvas，`jsPDF` 建立 A4 文件插入 canvas 圖片，`jsPDF.save('月報-YYYY-MM.pdf')` 觸發下載；需在 ≤ 30s 內完成於 `frontend/src/pages/MonthlyReportPage.tsx`

**Checkpoint**: MonthlyReportPage 完整顯示三個統計區塊，PDF 可正確下載

---

## Phase 8: User Story 6 — 老闆決策頁（Priority: P3）

**Goal**: 老闆可一頁掌握維運 KPI、技師負載、風險客戶清單，以及擴張承載能力評估與產能曲線

**Independent Test**: 帶入維運負載與客戶風險資料，驗證三個核心區塊數字正確，maxSafeAddDevices 計算邏輯符合規格

### 後端實作

> **Constitution II 規範**：整合測試任務 T094 必須先撰寫並確認失敗後，再開始對應實作任務。

- [ ] T094 [P] [US6] ⚠️ 先行撰寫（Red-Green-Refactor）：撰寫 executive 端點整合測試（驗證 KPI 計算、maxSafeAddDevices 邏輯）於 `backend/tests/integration/executive.test.ts`
- [ ] T090 [US6] 實作 `ExecutiveService.getSummary()`（KPI：totalDevices=80、totalTechnicians from DB、avgDevicesPerTech；technicianWorkload：每位技師的 activeWorkOrders + completedThisMonth + utilizationRate；topRiskClients：Top 5 by avgRiskScore）於 `backend/src/services/executiveService.ts`
- [ ] T091 [US6] 實作 GET /api/executive/summary 路由 handler（套用 authGuard、快取 TTL 25s）於 `backend/src/routes/executive.ts`
- [ ] T092 [P] [US6] 實作 `ExecutiveService.getCapacity(addDevices?)`（計算 maxSafeAddDevices = totalMaxCapacity × 0.95 - currentDevices；產生 addDevices 0/5/10/15/20 的 capacityCurve；MAX_DEVICES_PER_TECH 從 system_settings 讀取）於 `backend/src/services/executiveService.ts`
- [ ] T093 [P] [US6] 實作 GET /api/executive/capacity 路由 handler（addDevices query param，預設 0）於 `backend/src/routes/executive.ts`

### 前端實作

- [ ] T095 [P] [US6] 建立前端 executive API service（`getExecutiveSummary()`, `getCapacity(addDevices?)`）於 `frontend/src/services/executiveService.ts`
- [ ] T096 [P] [US6] 建立 KPICards 元件（3 張 KPI 卡片：總管理設備數、維運人員數、每人平均負責設備數）於 `frontend/src/components/KPICards.tsx`
- [ ] T097 [P] [US6] 建立 TechnicianWorkloadTable 元件（每位技師：姓名、當前工單數、本月完成工單數、產能利用率 % 進度條）於 `frontend/src/components/TechnicianWorkloadTable.tsx`
- [ ] T098 [P] [US6] 建立 RiskClientsList 元件（Top 5 風險客戶：客戶名稱、設備數、本月異常次數、風險評級 badge、建議行動）於 `frontend/src/components/RiskClientsList.tsx`
- [ ] T099 [P] [US6] 建立 CapacityCurveChart 元件（Recharts LineChart：x 軸 addDevices、y 軸 utilization %；參考線標示 95% 安全上限）於 `frontend/src/components/CapacityCurveChart.tsx`
- [ ] T100 [US6] 建立 ExecutiveDashboardPage 頁面元件：整合 KPICards + TechnicianWorkloadTable + RiskClientsList + CapacityCurveChart（含 addDevices 試算 input）+ 頁面資料透過 getExecutiveSummary + getCapacity 載入於 `frontend/src/pages/ExecutiveDashboardPage.tsx`

**Checkpoint**: ExecutiveDashboardPage 所有 4 個區塊正確顯示，產能曲線試算有效

---

## Final Phase: Polish & 跨頁通用項目

**Purpose**: 系統完整性收尾：確保 6 頁導覽流暢、深色主題一致、效能達標、Docker 環境可部署

- [ ] T101 確認 Layout.tsx Sidebar 所有 6 個頁面連結正確（路由路徑、active 狀態高亮），且持續顯示於所有頁面於 `frontend/src/components/Layout.tsx`
- [ ] T102 [P] 於 Header 顯示最後更新時間（呼叫 GET /api/system/last-updated，每 30 秒更新）於 `frontend/src/components/Layout.tsx`
- [ ] T103 [P] 驗證並補齊深色主題：確認所有 6 頁使用 `--color-bg`、`--color-accent` 等 CSS 變數，所有 Recharts 圖表設定深色背景 + 高對比色彩（WCAG 2.1 AA 對比度）
- [ ] T104 [P] 確認離線設備顯示邏輯：數值欄位（用電量、COP 等）顯示「--」、StatusBadge 顯示灰色「離線」、附最後成功更新時間戳記，跨所有相關頁面一致
- [ ] T105 [P] 確認設備安裝未滿 30 天的邊界情況：PowerChart 與 OperationChart 只渲染有資料的日期，不補空值，圖表標示起始日期說明
- [ ] T106 最終化 Docker Compose 設定：確認 frontend production build（`vite build`）、backend-api 容器化、Nginx 靜態資源 + API 代理均正確，所有環境變數由 `docker/.env` 注入於 `docker/docker-compose.yml`
- [ ] T107 [P] 設定 Vite production build 最佳化（code splitting、asset hash、gzip via Nginx）於 `frontend/vite.config.ts`
- [ ] T108 [P] 在後端加入 `/api/system/health` 端點回應：MySQL 連線狀態、InfluxDB 連線狀態、process uptime，並在 docker compose 設定 healthcheck 於 `backend/src/routes/system.ts`
- [ ] T109 建立專案 README.md：包含本機開發快速啟動（對應 quickstart.md 步驟）、Docker Compose 部署說明、資料庫初始化指令，以繁體中文撰寫於 `README.md`

**Checkpoint**: 所有 6 頁面功能完整、主題一致、Docker 環境可一鍵啟動

---

## 依賴關係圖（User Story 完成順序）

```
Setup (T001-T012)
    ↓
Foundational (T013-T038)
    ↓
┌─────────────────────────────────────────────────────┐
│  可平行執行（Phase 2 完成後）                         │
│                                                     │
│  US1 設備總覽 (T039-T047) ← P1 MVP                  │
│  US4 告警中心 (T048–T053a–T054a–T058) ← P1          │
│  US2 風險排序 (T059-T066) ← P2（依賴 US1 路由）     │
│  US3 單機履歷 (T067-T079) ← P2（依賴 US1 入口）     │
│  US5 月報雛形 (T080-T089) ← P3                      │
│  US6 老闆決策 (T090-T100) ← P3                      │
└─────────────────────────────────────────────────────┘
    ↓
Polish (T101-T109)
```

## 平行執行範例

### MVP Sprint（US1 完整交付，最小可測試增量）
```
T013→T014→T015 (MySQL schema + connection)
           ↓
T023 (seed data) + T024→T025 (mock data)
           ↓
T039→T040→T041→T042 (DeviceService + routes)
           ↓
T027→T028→T029→T035 (frontend base)
T044 [P] + T045 [P] + T046 [P] (frontend components)
           ↓
T047 (DeviceOverviewPage 整合完成)
```

### US4 平行於 US1 開發（P1 雙線進行）
```
T048→T049 (AlertService + GET) ← 同時
T050→T051 (assign)             ← 進行
T052→T053 (resolve)            ← US1
           ↓
T055 [P] + T056 [P] + T057 [P]
           ↓
T058 (AlertCenterPage)
```

---

## 實作策略

1. **MVP 優先**：僅完成 Phase 1 + Phase 2 + Phase 3（US1 設備總覽），即可交付第一個可展示增量
2. **P1 衝刺**：完成 US1 + US4，系統具備維運核心功能（設備監控 + 告警管理）
3. **P2 擴充**：加入 US2 + US3，強化診斷能力（風險排序 + 單機履歷）
4. **P3 完整**：加入 US5 + US6，完成報告與策略層功能
5. **測試策略**：每個 US phase 含至少一個整合測試（Constitution II 要求），確保可獨立驗收

---

## 任務計數摘要

| Phase | 任務數 | 說明 |
|-------|--------|------|
| Phase 1: Setup | 13 (T001–T007a–T012) | 專案初始化（含 CI）|
| Phase 2: Foundational | 26 (T013–T038) | 後端 + 前端基礎建設 |
| Phase 3: US1 設備總覽 | 9 (T039–T047) | P1 MVP |
| Phase 4: US4 告警中心 | 13 (T048–T053a–T054a–T058) | P1 |
| Phase 5: US2 風險排序 | 8 (T059–T066) | P2 |
| Phase 6: US3 單機履歷 | 13 (T067–T079) | P2 |
| Phase 7: US5 月報雛形 | 10 (T080–T089) | P3 |
| Phase 8: US6 老闆決策 | 11 (T090–T100) | P3 |
| Final: Polish | 9 (T101–T109) | 收尾 |
| **合計** | **112** | |

| 使用者故事 | 後端任務數 | 前端任務數 | 整合測試 |
|-----------|----------|----------|--------|
| US1 設備總覽 | 4 | 4 | ✅ T043 |
| US4 告警中心 | 9 | 4 | ✅ T054, T054a |
| US2 風險排序 | 4 | 3 | ✅ T063 |
| US3 單機履歷 | 6 | 6 | ✅ T073 |
| US5 月報雛形 | 4 | 5 | ✅ T083 |
| US6 老闆決策 | 5 | 6 | ✅ T094 |

**平行機會**：109 個任務中，標記 [P] 的任務共 **52 個**，可大幅縮短實際開發時程。

**建議 MVP 範圍**：Phase 1 + Phase 2 + Phase 3（T001–T047），共 47 個任務，交付設備總覽核心功能。
