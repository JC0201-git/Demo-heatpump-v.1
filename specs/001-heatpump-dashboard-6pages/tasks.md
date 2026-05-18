---
description: "熱泵／熱水系統監控儀表板（6 頁）任務清單"
---

# 任務清單：熱泵／熱水系統監控儀表板（6 頁）

**輸入**：設計文件來自 `/specs/001-heatpump-dashboard-6pages/`  
**必要前置文件**：plan.md ✅、spec.md ✅、research.md ✅、data-model.md ✅、contracts/ ✅、quickstart.md ✅  
**測試**：Constitution II 明確要求 TDD、每個使用者故事至少一個整合測試、修改模組覆蓋率 ≥ 80%；本任務清單將測試任務排在對應實作任務之前。  
**組織方式**：任務依使用者故事分組，支援各故事獨立實作與驗收。

## 格式說明

- **[P]**：可平行執行（不同檔案，且不依賴尚未完成的任務）
- **[Story]**：使用者故事標籤（US1–US6）；專案建置、基礎設施與收尾任務不加故事標籤
- 每個任務均包含可落地的檔案路徑
- 測試先行任務必須先寫好並確認失敗，再開始同階段實作

---

## 第 1 階段：專案建置

**目標**：建立前後端專案骨架、開發工具設定與 Docker 部署基礎。

- [ ] T001 建立前端專案架構（Vite 5 + React 18 + TypeScript 5 + Tailwind CSS v3 + React Router v6 + ECharts `echarts-for-react` + Zustand + Axios + jsPDF + html2canvas）→ `frontend/`
- [ ] T002 [P] 建立後端專案架構（Fastify 4 + TypeScript 5 + Drizzle ORM + mysql2 + influx@5 + bcryptjs + node-cron + @fastify/jwt + @fastify/cookie + @fastify/cors + @fastify/rate-limit + node-cache）→ `backend/`
- [ ] T003 [P] 設定前端 ESLint、Prettier、Vitest 與 Testing Library 基礎設定（Constitution I/II）→ `frontend/.eslintrc.cjs`、`frontend/.prettierrc`、`frontend/vite.config.ts`
- [ ] T004 [P] 設定後端 ESLint、Prettier、Jest 與 Supertest 基礎設定（Constitution I/II）→ `backend/.eslintrc.cjs`、`backend/.prettierrc`、`backend/jest.config.ts`
- [ ] T005 [P] 建立 Docker Compose 服務定義與 Nginx 反向代理（`/api/*` → backend-api:3001，`/*` → frontend:80）→ `docker/docker-compose.yml`、`docker/nginx/default.conf`
- [ ] T006 [P] 建立環境變數範本與 git ignore（JWT_SECRET、MYSQL_*、INFLUXDB_*、DEVICE_CACHE_TTL=25、REPORT_CACHE_TTL=300、MAX_DEVICES_PER_TECH=20、MAX_WORK_ORDERS_PER_TECH=10、ALERT_OVERDUE_HOURS=24）→ `docker/env.example`、`.gitignore`

**檢查點**：前後端可各自安裝依賴並啟動；`docker compose up --build` 可啟動 frontend、backend-api、reverse-proxy。

---

## 第 2 階段：基礎設施

**目標**：資料庫 Schema、資料來源抽象、認證、系統端點、Mock/Real 混合資料、前端共用基礎。  
**關鍵**：本階段完成前，不得開始任何使用者故事實作。

### 2A：後端基礎設施

- [ ] T007 定義 Drizzle ORM MySQL Schema（clients、sites、devices、device_risk_snapshots、meters、device_meter_mappings、alerts、work_orders、technicians、users、system_settings、risk_score_weights；含風險六維度快照欄位、索引與 CHECK constraint）→ `backend/src/db/schema.ts`
- [ ] T008 建立 Drizzle 初始 migration SQL（完整對應 data-model.md DDL 與索引）→ `backend/src/db/migrations/0001_init.sql`
- [ ] T009 [P] 建立 seed 腳本（80 台 devices：DEV-001～DEV-007 為 real、DEV-008～DEV-080 為 mock；為每台設備建立 device_risk_snapshots 六維度初始快照；system_settings 含 polling_interval_sec、alert_page_size、risk_score_refresh_min、default_query_days、MAX_DEVICES_PER_TECH、MAX_WORK_ORDERS_PER_TECH、ALERT_OVERDUE_HOURS；risk_score_weights 6 條；users 與 technicians 初始資料）→ `backend/src/db/seed.ts`
- [ ] T010 [P] 建立 InfluxDB 1.x client 與 InfluxQL 查詢封裝（power_meter、heatpump_status、energy_daily_summary、heatpump_daily_summary；包含缺欄位回傳 null）→ `backend/src/influx/client.ts`、`backend/src/influx/queries.ts`
- [ ] T011 [P] 建立 Mock 資料產生腳本與 73 台 Mock JSON（每檔含 realtimeStatus、powerDailySummary、operationDailySummary、alerts、workOrders；數值隨機但可重現）→ `scripts/generate-mock-data.ts`、`mock-data/devices/DEV-008.json`
- [ ] T012 建立 Mock 資料載入器（啟動時讀取 `mock-data/devices/` 至記憶體；提供 getMockDevice、getMockDeviceList、getPowerSummary、getOperationSummary）→ `backend/src/mock/loader.ts`
- [ ] T013 建立 dataSourceService（依 `devices.data_source_type` 路由至 real InfluxDB/MySQL 或 mock loader；統一 API response DTO；real API 失敗時保留最後快取值並標記 stale）→ `backend/src/services/dataSourceService.ts`
- [ ] T014 初始化 Fastify 應用程式（註冊 cors、jwt、cookie、rate-limit；全域錯誤格式 `{error,message,statusCode}`；掛載 protected route preHandler）→ `backend/src/app.ts`、`backend/src/server.ts`
- [ ] T015 實作 JWT 認證 preHandler hook（驗證 `hp_token` httpOnly cookie；驗證失敗回傳 401 UNAUTHORIZED 與繁中錯誤訊息）→ `backend/src/middleware/auth.ts`
- [ ] T016 [P] 定義後端共用 DTO 型別（DeviceListItem、DeviceDetail、AlertItem、WorkOrder、RiskDevice、MonthlyReport、ExecutiveSummary、CapacityResult、ApiMeta）→ `backend/src/types/device.ts`、`backend/src/types/alert.ts`、`backend/src/types/common.ts`
- [ ] T017 [P] 系統端點整合測試（GET /api/system/health 驗 mysql/influxdb 狀態與 503 降級；GET /api/system/last-updated 驗 ISO8601 updatedAt；AAA；測試先於 T018）→ `backend/tests/integration/system.test.ts`
- [ ] T018 實作系統端點（GET /api/system/health、GET /api/system/last-updated；health 不需登入，其餘端點受 JWT 保護）→ `backend/src/routes/system.ts`
- [ ] T019 [P] dailySummaryJob 單元測試（stub Influx client；驗 energy_daily_summary 與 heatpump_daily_summary 寫入；InfluxDB 失敗時記錄錯誤且不拋未攔截例外；測試先於 T020）→ `backend/tests/unit/jobs/dailySummaryJob.test.ts`
- [ ] T020 建立 node-cron 每日彙總工作（每日 00:05 聚合 power_meter 與 heatpump_status，支援 `triggerDailySummary()` 手動觸發）→ `backend/src/jobs/dailySummaryJob.ts`

### 2B：認證 API

- [ ] T021 [P] 認證 API 整合測試（login 成功設 httpOnly cookie；logout 清 cookie；me 回傳使用者；登入錯誤不暴露帳號存在；第 11 次/分鐘回 429；測試先於 T022）→ `backend/tests/integration/auth.test.ts`
- [ ] T022 實作認證路由（POST /api/auth/login、POST /api/auth/logout、GET /api/auth/me；bcrypt cost=12；JWT 8 小時；rate-limit 10 次/分鐘）→ `backend/src/routes/auth.ts`

### 2C：前端基礎設施

- [ ] T023 [P] 定義前端共用 TypeScript 型別（與後端 DTO 對齊，含 stale/meta 欄位與繁中 label 型別）→ `frontend/src/types/device.ts`、`frontend/src/types/alert.ts`、`frontend/src/types/risk.ts`、`frontend/src/types/common.ts`
- [ ] T024 建立 React App 主架構（React Router v6、ProtectedRoute、MainLayout、左側 Sidebar 六頁導覽、登入路由 `/login`、預設設備總覽 `/`）→ `frontend/src/App.tsx`、`frontend/src/components/Layout/Sidebar.tsx`、`frontend/src/components/Layout/MainLayout.tsx`
- [ ] T025 [P] 設定 Tailwind CSS 設計 Token（深綠黑背景、黃綠強調色、normal/alert/offline/maintenance 狀態色、AA 對比基準）→ `frontend/tailwind.config.ts`
- [ ] T026 [P] 建立 Axios 實例與攔截器（withCredentials=true、baseURL=/api、401 導向 /login、讀取 meta.updatedAt 與 stale 標記）→ `frontend/src/services/api.ts`
- [ ] T027 [P] 建立共用 StatusBadge 元件（綠 normal、紅 alert、灰 offline、橘 maintenance；輸出繁中 label）→ `frontend/src/components/StatusBadge.tsx`
- [ ] T028 [P] 建立共用 AlertBanner 元件（「API 連線異常」頁面橫幅與「資料可能過期」行內標籤）→ `frontend/src/components/AlertBanner.tsx`
- [ ] T029 建立登入頁元件（帳號密碼表單、錯誤訊息繁中、成功後導向 `/`）→ `frontend/src/pages/Login/LoginPage.tsx`
- [ ] T030 [P] 建立 authStore 與 useAuth Hook（登入使用者資訊、載入 me、登出方法）→ `frontend/src/stores/authStore.ts`、`frontend/src/hooks/useAuth.ts`
- [ ] T031 [P] 建立 ProtectedRoute（未登入者重導 `/login`，登入中顯示可存取的載入狀態）→ `frontend/src/components/ProtectedRoute.tsx`
- [ ] T032 [P] 建立 usePolling Hook（預設 30 秒，可 start/stop，頁面卸載清理 timer）→ `frontend/src/hooks/usePolling.ts`
- [ ] T033 [P] 建立 LastUpdatedBadge 元件（顯示最後資料更新時間，支援 stale 標記）→ `frontend/src/components/LastUpdatedBadge.tsx`
- [ ] T034 [P] 建立 PageStatusHeader 共用元件（每個受保護頁面統一放置 AlertBanner + LastUpdatedBadge，確保 FR-034/FR-035 跨頁一致）→ `frontend/src/components/PageStatusHeader.tsx`

**檢查點**：`GET /api/system/health` 回應；登入頁可登入；受保護路由正常；系統具備 real/mock 混合資料基礎。

---

## 第 3 階段：使用者故事 1 — 設備總覽（優先順序：P1）🎯 MVP

**目標**：維運工程師可一眼掌握 80 台設備狀態，依狀態篩選、依關鍵字搜尋，並導向單機履歷。  
**獨立驗收測試**：以 7 台 real fixture/stub + 73 台 mock 載入設備列表，驗證 80 台完整顯示、狀態篩選、前綴搜尋、離線顯示與點擊導向。

### 測試先行（US1）

- [ ] T035 [US1] 設備列表整合測試（GET /api/devices 使用 7 real fixture/stub + 73 mock；驗 status/search/page/limit、real API 失敗時 stale/cache 行為、欄位完整；SC-001 人工計時結果寫入驗收紀錄；測試先於 T037/T038）→ `backend/tests/integration/devices.test.ts`、`docs/acceptance-sc001.md`
- [ ] T036 [P] [US1] 設備總覽前端單元測試（DeviceTable、StatusFilter、SearchBar；驗 StatusBadge 色彩 token、篩選、搜尋 debounce、離線欄位顯示「--」、PageStatusHeader 顯示最後更新時間）→ `frontend/tests/unit/DeviceList/`

### 後端實作（US1）

- [ ] T037 [US1] 實作 deviceService.getDeviceList()（整合 MySQL devices + dataSourceService；排序 alert > maintenance > offline > normal 再 riskScore DESC；node-cache TTL 25s）→ `backend/src/services/deviceService.ts`
- [ ] T038 [US1] 實作 GET /api/devices 路由（authGuard、status/search/page/limit query、SQL `LIKE 'keyword%'` 不分大小寫、統一回應 meta.total/updatedAt）→ `backend/src/routes/devices.ts`

### 前端實作（US1）

- [ ] T039 [US1] 建立 deviceStore（Zustand；輪詢 GET /api/devices、儲存 filter/search/page、保留 stale cache）→ `frontend/src/stores/deviceStore.ts`
- [ ] T040 [P] [US1] 建立 DeviceTable 元件（設備編號、客戶名稱、地點、StatusBadge、最後心跳；離線即時欄位「--」；點擊列導向 `/devices/:deviceId`）→ `frontend/src/pages/DeviceList/DeviceTable.tsx`
- [ ] T041 [P] [US1] 建立 StatusFilter 元件（全部/正常/異常/離線/待維修，顯示各狀態數量）→ `frontend/src/pages/DeviceList/StatusFilter.tsx`
- [ ] T042 [P] [US1] 建立 SearchBar 元件（設備編號或客戶名稱前綴模糊搜尋，顯示篩選結果數量）→ `frontend/src/pages/DeviceList/SearchBar.tsx`
- [ ] T043 [US1] 組裝 DeviceList 頁面（PageStatusHeader + StatusFilter + SearchBar + DeviceTable；30 秒輪詢；桌面 1280px 以上版面）→ `frontend/src/pages/DeviceList/DeviceListPage.tsx`

**檢查點**：US1 可獨立展示登入後的設備總覽 MVP。

---

## 第 4 階段：使用者故事 4 — 告警中心（優先順序：P1）

**目標**：值班工程師可集中管理即時告警、指派負責人、標記已解除；未指派告警置頂，高嚴重性視覺突出。  
**獨立驗收測試**：帶入告警資料後，驗未指派置頂、高嚴重性高亮、狀態/類型篩選、指派與解除狀態正確寫回。

### 測試先行（US4）

- [ ] T044 [US4] 告警中心整合測試（GET /api/alerts 驗未指派置頂、severity=high 排序、limit=50 分頁；PUT assign 驗 in_progress/assigned_at；PUT resolve 驗 resolved_at；SC-002 三步驟驗收寫入紀錄；測試先於 T046-T050）→ `backend/tests/integration/alerts.test.ts`、`docs/acceptance-sc002.md`
- [ ] T045 [P] [US4] 告警中心前端單元測試（AlertTable、AlertFilter、AssignModal、ResolveButton；驗高嚴重性紅色背景、未指派置頂、技師下拉、解除確認、PageStatusHeader）→ `frontend/tests/unit/AlertCenter/`

### 後端實作（US4）

- [ ] T046 [US4] 實作 alertService.getAlerts()（排序：未指派置頂 → severity high/medium/low → occurredAt DESC；支援 status/alert_type/severity；node-cache TTL 10s）→ `backend/src/services/alertService.ts`
- [ ] T047 [US4] 實作 GET /api/alerts 路由（authGuard、status/alert_type/severity/page/limit、meta.total/updatedAt）→ `backend/src/routes/alerts.ts`
- [ ] T048 [P] [US4] 實作 alertService.assignAlert() 與 PUT /api/alerts/:alertId/assign（驗 active 技師、422 TECHNICIAN_NOT_FOUND、404 ALERT_NOT_FOUND）→ `backend/src/services/alertService.ts`、`backend/src/routes/alerts.ts`
- [ ] T049 [P] [US4] 實作 alertService.resolveAlert() 與 PUT /api/alerts/:alertId/resolve（拒絕重複解除、409 ALERT_ALREADY_RESOLVED、記錄 resolutionNote）→ `backend/src/services/alertService.ts`、`backend/src/routes/alerts.ts`
- [ ] T050 [P] [US4] 實作 GET /api/technicians 路由（只回傳 status=active 技師，供 AssignModal 下拉）→ `backend/src/routes/technicians.ts`

### 前端實作（US4）

- [ ] T051 [US4] 建立 alertStore（告警列表、篩選條件、分頁、樂觀更新指派/解除、錯誤回滾）→ `frontend/src/stores/alertStore.ts`
- [ ] T052 [P] [US4] 建立 AlertTable 元件（告警 ID、設備、客戶、異常類型、發生時間、狀態、負責人；未指派與高嚴重性視覺突出）→ `frontend/src/pages/AlertCenter/AlertTable.tsx`
- [ ] T053 [P] [US4] 建立 AlertFilter 元件（未處理/處理中/已解除與異常類型篩選）→ `frontend/src/pages/AlertCenter/AlertFilter.tsx`
- [ ] T054 [P] [US4] 建立 AssignModal 元件（技師下拉、呼叫 assign API、繁中結果回饋、鍵盤可操作）→ `frontend/src/pages/AlertCenter/AssignModal.tsx`
- [ ] T055 [P] [US4] 建立 ResolveButton 元件（確認對話框、resolutionNote、呼叫 resolve API、更新 store）→ `frontend/src/pages/AlertCenter/ResolveButton.tsx`
- [ ] T056 [US4] 組裝 AlertCenter 頁面（PageStatusHeader + AlertFilter + AlertTable + AssignModal + ResolveButton；30 秒輪詢）→ `frontend/src/pages/AlertCenter/AlertCenterPage.tsx`

**檢查點**：US4 可獨立驗收即時告警管理流程。

---

## 第 5 階段：使用者故事 2 — 風險排序（優先順序：P2）

**目標**：維運主管可快速看到 Top 10 高風險設備，了解風險主因與建議行動，追蹤排名變動。  
**獨立驗收測試**：帶入設備告警、工單、離線與能耗資料後，驗 Top 10 依風險分數降序，風險主因、建議行動與排名變動正確。

### 測試先行（US2）

- [ ] T057 [US2] 風險排序整合測試（GET /api/risk/top-devices 以 MySQL device_risk_snapshots fixture 驗恰好 10 筆、risk_score DESC、riskReasons、suggestedAction、rankChange/rankDelta、5 分鐘快取；測試先於 T060/T061）→ `backend/tests/integration/risk.test.ts`
- [ ] T058 [P] [US2] 風險排序前端單元測試（RiskTable、RankBadge、RankChangeBadge；驗 Top 3 標示、↑/↓/不變、建議行動標籤、點擊導向單機履歷、PageStatusHeader）→ `frontend/tests/unit/RiskRanking/`
- [ ] T059 [P] [US2] riskScoreService 單元測試（六維度計算、權重加總、輸出夾至 [0,100]；所有維度分數只讀 MySQL device_risk_snapshots 快照欄位，energy_anomaly 使用 energy_anomaly_score；不得直接查 energy_daily_summary 或 mock powerDailySummary；測試先於 T060）→ `backend/tests/unit/services/riskScoreService.test.ts`

### 後端實作（US2）

- [ ] T060 [US2] 實作 riskSnapshotService 與 riskScoreService（riskSnapshotService 每 5 分鐘從 MySQL alerts、work_orders、devices 狀態與已同步能耗異常快照 upsert device_risk_snapshots；riskScoreService 只讀 device_risk_snapshots 六維度快照欄位與 risk_score_weights 計算 riskScore，寫回 devices.risk_score；保存前次排名供 rankChange）→ `backend/src/services/riskSnapshotService.ts`、`backend/src/services/riskScoreService.ts`
- [ ] T061 [US2] 實作 GET /api/risk/top-devices 路由（Top 10、riskReasons、suggestedAction：≥70 緊急/≥40 本週/<40 本月、rankChange/rankDelta、5 分鐘快取）→ `backend/src/routes/risk.ts`

### 前端實作（US2）

- [ ] T062 [P] [US2] 建立 RiskTable 元件（排名、設備編號、客戶、風險分數、風險主因 tag、建議行動、RankChangeBadge；點擊列導向 `/devices/:deviceId`）→ `frontend/src/pages/RiskRanking/RiskTable.tsx`
- [ ] T063 [P] [US2] 建立 RankBadge 元件（Top 3 金色、其餘中性色；符合深色主題 AA 對比）→ `frontend/src/pages/RiskRanking/RankBadge.tsx`
- [ ] T064 [P] [US2] 建立 RankChangeBadge 元件（上升/下降/不變，使用圖示與文字輔助，不只靠顏色）→ `frontend/src/pages/RiskRanking/RankChangeBadge.tsx`
- [ ] T065 [US2] 組裝 RiskRanking 頁面（PageStatusHeader + RiskTable；30 秒輪詢但尊重後端 5 分鐘風險快取）→ `frontend/src/pages/RiskRanking/RiskRankingPage.tsx`

**檢查點**：US2 可獨立驗收 Top 10 風險排序。

---

## 第 6 階段：使用者故事 3 — 單機履歷（優先順序：P2）

**目標**：維運工程師可查看單台設備的用電、運轉、異常、維修四個子頁籤與完整歷史。  
**獨立驗收測試**：選定一台設備，驗設備標頭、30 日圖表、不足 30 天說明、COP/pressure 缺欄位容錯、異常與工單分頁。

### 測試先行（US3）

- [ ] T066 [US3] 單機履歷整合測試（GET /api/devices/:deviceId、/power、/operation、/alerts、/work-orders；驗 404、安裝不足 30 天不補零、分頁、supportsCoP/supportsPressure 容錯；測試先於 T068-T072）→ `backend/tests/integration/deviceHistory.test.ts`
- [ ] T067 [P] [US3] 單機履歷前端單元測試（DeviceInfoCard、PowerChart、OperationChart、AlertTimeline、WorkOrderList；驗「不適用」/「--」、resolutionNote、空狀態、PageStatusHeader）→ `frontend/tests/unit/DeviceHistory/`

### 後端實作（US3）

- [ ] T068 [US3] 實作 GET /api/devices/:deviceId 與 DeviceDetail service（基本資訊、supportsCoP、supportsPressure、404 DEVICE_NOT_FOUND）→ `backend/src/routes/devices.ts`、`backend/src/services/deviceService.ts`
- [ ] T069 [P] [US3] 實作 GET /api/devices/:deviceId/power（real 查 energy_daily_summary + device_meter_mappings/share_ratio；mock 讀 JSON；安裝不足 30 天僅回實際日期）→ `backend/src/routes/devices.ts`
- [ ] T070 [P] [US3] 實作 GET /api/devices/:deviceId/operation（real 查 heatpump_daily_summary；mock 讀 JSON；COP null 依 supportsCoP 處理）→ `backend/src/routes/devices.ts`
- [ ] T071 [P] [US3] 實作 GET /api/devices/:deviceId/alerts（MySQL alerts 分頁，依 occurred_at DESC；含 alertType、severity、description、resolutionNote）→ `backend/src/routes/devices.ts`
- [ ] T072 [P] [US3] 實作 GET /api/devices/:deviceId/work-orders（MySQL work_orders 分頁，依 dispatched_at DESC；含 woCode、priority、status、assignedToName、issueDesc、resolutionDesc）→ `backend/src/routes/devices.ts`

### 前端實作（US3）

- [ ] T073 [P] [US3] 建立 DeviceInfoCard 元件（設備編號、型號、安裝日期、客戶、地點、StatusBadge、最後心跳）→ `frontend/src/pages/DeviceHistory/DeviceInfoCard.tsx`
- [ ] T074 [P] [US3] 建立 PowerChart 元件（ECharts 折線圖；kWh、異常值標記、不足 30 天資料期間說明）→ `frontend/src/pages/DeviceHistory/PowerChart.tsx`
- [ ] T075 [P] [US3] 建立 OperationChart 元件（runHours/startupCount/COP；supportsCoP=false 顯示「不適用」；supportsCoP=true 且 null 顯示「--」）→ `frontend/src/pages/DeviceHistory/OperationChart.tsx`
- [ ] T076 [P] [US3] 建立 AlertTimeline 元件（異常時間軸、severity badge、持續時間、解除方式、空狀態提示）→ `frontend/src/pages/DeviceHistory/AlertTimeline.tsx`
- [ ] T077 [P] [US3] 建立 WorkOrderList 元件（工單號、優先級、技師、派工/完工時間、問題描述、處置方式、空狀態提示）→ `frontend/src/pages/DeviceHistory/WorkOrderList.tsx`
- [ ] T078 [US3] 組裝 DeviceHistory 頁面（PageStatusHeader + DeviceInfoCard + 四子頁籤；頁籤切換不重抓標頭）→ `frontend/src/pages/DeviceHistory/DeviceHistoryPage.tsx`

**檢查點**：US3 可獨立驗收單台設備診斷流程。

---

## 第 7 階段：使用者故事 5 — 月報雛形（優先順序：P3）

**目標**：維運主管可選月份查看設備健康摘要、異常統計、告警處理率，並匯出 PDF。  
**獨立驗收測試**：選定月份後，驗健康分布、異常 Top 5、每日平均、告警處理率、逾時未處理、PDF 匯出與 5 分鐘內準備流程。

### 測試先行（US5）

- [ ] T079 [US5] 月報整合測試（GET /api/reports/monthly?month=YYYY-MM；驗健康平均與分布、異常 Top 5 同次數時 `device_code ASC`、28/29/30/31 天每日平均、ALERT_OVERDUE_HOURS 逾時計算、422 INVALID_MONTH；測試先於 T081/T082）→ `backend/tests/integration/reports.test.ts`
- [ ] T080 [P] [US5] 月報前端單元測試（MonthPicker、HealthSummaryChart、AnomalyBarChart、AlertRateCard、ExportPdfButton；驗月份切換、每日平均、載入中、PDF 觸發、PageStatusHeader）→ `frontend/tests/unit/MonthlyReport/`

### 後端實作（US5）

- [ ] T081 [US5] 實作 reportService.getMonthlyReport()（聚合健康分數、異常類型、Top 5 異常設備 tie-breaker、告警總數/已解除率/平均解除時間/逾時未處理；每日平均除以實際天數）→ `backend/src/services/reportService.ts`
- [ ] T082 [US5] 實作 GET /api/reports/monthly 路由（month=YYYY-MM 驗證、authGuard、REPORT_CACHE_TTL=300、422 INVALID_MONTH）→ `backend/src/routes/reports.ts`

### 前端實作（US5）

- [ ] T083 [P] [US5] 建立 MonthPicker 元件（預設當月，切換後重新取資料）→ `frontend/src/pages/MonthlyReport/MonthPicker.tsx`
- [ ] T084 [P] [US5] 建立 HealthSummaryChart 元件（90-100、70-89、50-69、0-49 分布與平均健康分）→ `frontend/src/pages/MonthlyReport/HealthSummaryChart.tsx`
- [ ] T085 [P] [US5] 建立 AnomalyBarChart 元件（異常類型水平長條圖、月總量、每日平均、Top 5 設備清單）→ `frontend/src/pages/MonthlyReport/AnomalyBarChart.tsx`
- [ ] T086 [P] [US5] 建立 AlertRateCard 元件（告警總數、已解除率、平均解除時間、逾時未處理數、每日平均）→ `frontend/src/pages/MonthlyReport/AlertRateCard.tsx`
- [ ] T087 [P] [US5] 建立 ExportPdfButton 元件（html2canvas 截取 `#monthly-report`，jsPDF A4 輸出 `月報-YYYY-MM.pdf`，顯示載入狀態，目標 ≤30 秒）→ `frontend/src/pages/MonthlyReport/ExportPdfButton.tsx`
- [ ] T088 [US5] 組裝 MonthlyReport 頁面（PageStatusHeader + MonthPicker + ExportPdfButton + `#monthly-report` 報表內容）→ `frontend/src/pages/MonthlyReport/MonthlyReportPage.tsx`
- [ ] T089 [US5] 建立 SC-007 月報準備流程驗收記錄（從進入月報頁、選月份、確認圖表、匯出 PDF 至完成，目標 ≤5 分鐘）→ `docs/acceptance-sc007.md`

**檢查點**：US5 可獨立驗收月報查看與匯出。

---

## 第 8 階段：使用者故事 6 — 老闆決策頁（優先順序：P3）

**目標**：高階主管可一頁掌握維運 KPI、技師負載、高風險客戶與擴張承載能力。  
**獨立驗收測試**：帶入維運負載與客戶風險資料，驗 KPI、負載、Top 5 客戶、產能試算公式與 5 分鐘決策目標。

### 測試先行（US6）

- [ ] T090 [US6] 老闆決策頁整合測試（GET /api/executive/summary 驗 KPI、technicianWorkload、topRiskClients；GET /api/executive/capacity?addDevices=10 驗 maxSafeAddDevices = totalMaxCapacity × 0.95 − currentDevices；測試先於 T092-T095）→ `backend/tests/integration/executive.test.ts`
- [ ] T091 [P] [US6] 老闆決策頁前端單元測試（KpiCard、WorkloadTable、RiskClientList、CapacityGauge；驗數值格式、進度條、風險評級、95% 安全線、PageStatusHeader）→ `frontend/tests/unit/ExecutiveDashboard/`

### 後端實作（US6）

- [ ] T092 [US6] 實作 executiveService（totalDevices、totalTechnicians、avgDevicesPerTech、activeWorkOrders、completedThisMonth、MAX_WORK_ORDERS_PER_TECH 利用率、MAX_DEVICES_PER_TECH 擴張承載能力）→ `backend/src/services/executiveService.ts`
- [ ] T093 [US6] 實作 GET /api/executive/summary 路由（kpi、technicianWorkload、topRiskClients、authGuard、TTL 300s）→ `backend/src/routes/executive.ts`
- [ ] T094 [P] [US6] 實作 GET /api/executive/capacity 路由（addDevices query、projectedUtilization、maxSafeAddDevices、capacityCurve 0/5/10/15/20）→ `backend/src/routes/executive.ts`
- [ ] T095 [P] [US6] 實作 GET /api/risk/top-clients 路由（Top 5 高風險客戶、avgRiskScore、riskTier：≥70 高/40-69 中/<40 低、suggestedAction）→ `backend/src/routes/risk.ts`

### 前端實作（US6）

- [ ] T096 [P] [US6] 建立 KpiCard 元件（三個 KPI：總設備數、維運人員數、每人平均設備數）→ `frontend/src/pages/ExecutiveDashboard/KpiCard.tsx`
- [ ] T097 [P] [US6] 建立 WorkloadTable 元件（技師姓名、當前工單、本月完工、產能利用率進度條）→ `frontend/src/pages/ExecutiveDashboard/WorkloadTable.tsx`
- [ ] T098 [P] [US6] 建立 RiskClientList 元件（Top 5 客戶、設備數、本月異常、風險評級、建議行動）→ `frontend/src/pages/ExecutiveDashboard/RiskClientList.tsx`
- [ ] T099 [P] [US6] 建立 CapacityGauge 元件（ECharts 半圓儀表、擴張負載曲線、95% 安全承接線）→ `frontend/src/pages/ExecutiveDashboard/CapacityGauge.tsx`
- [ ] T100 [US6] 組裝 ExecutiveDashboard 頁面（PageStatusHeader + KPI 卡片 + WorkloadTable + RiskClientList + CapacityGauge + addDevices 試算輸入）→ `frontend/src/pages/ExecutiveDashboard/ExecutiveDashboardPage.tsx`
- [ ] T101 [US6] 建立 SC-005 決策流程驗收記錄（業務背景測試者從進入頁面到完成是否承接 N 台設備判斷，目標 ≤5 分鐘）→ `docs/acceptance-sc005.md`

**檢查點**：US6 可獨立驗收管理決策頁。

---

## 第 9 階段：收尾與橫切面

**目標**：快取、風險規則管理、安全、效能、覆蓋率、無障礙、CI/CD、staging 與 quickstart 驗證。

- [ ] T102 [P] 快取 HTTP 標頭中介軟體測試（驗設備列表 25s、月報/歷史資料 300s、風險/老闆頁 300s；不取代 service 層 node-cache；測試先於 T103）→ `backend/tests/unit/middleware/cache.test.ts`
- [ ] T103 實作後端 API Cache-Control 中介軟體（依路由設定快取標頭，與 node-cache 職責分離）→ `backend/src/middleware/cache.ts`
- [ ] T104 [P] 風險規則 API 整合測試（GET /api/risk/rules；PUT /api/risk/rules 驗啟用權重加總 = 100，否則 422 INVALID_WEIGHT_SUM；測試先於 T105）→ `backend/tests/integration/riskRules.test.ts`
- [ ] T105 [P] 實作 GET/PUT /api/risk/rules 端點（讀寫 risk_score_weights，繁中錯誤訊息，authGuard）→ `backend/src/routes/risk.ts`
- [ ] T106 [P] 建立深色主題與圖表對比自動檢查（Tailwind token、ECharts 背景與高對比色、狀態色語意一致）→ `frontend/tests/accessibility/theme-contrast.test.ts`
- [ ] T107 [P] 建立離線與 stale 資料跨頁一致性整合測試（DeviceList、AlertCenter、RiskRanking、DeviceHistory、MonthlyReport、ExecutiveDashboard 均顯示 PageStatusHeader 與「資料可能過期」）→ `frontend/tests/integration/stale-data.test.ts`
- [ ] T108 [P] 建立 lint/format 最終驗證報告產生腳本（frontend/backend ESLint + Prettier；零錯誤，必要 suppression 必須有註解）→ `scripts/quality-check.sh`、`docs/lint-report.md`
- [ ] T109 [P] 建立 API 效能基準（k6：GET /api/devices、/api/alerts、/api/risk/top-devices、/api/reports/monthly、/api/executive/summary p95 ≤500ms；整合 CI）→ `backend/tests/performance/api.k6.ts`、`.github/workflows/perf.yml`
- [ ] T110 [P] 建立告警中心 SC-004 效能驗收（80 筆告警、GET /api/alerts?limit=50 p95 ≤500ms、前端頁面載入 ≤3 秒，截圖/結果入文件）→ `backend/tests/performance/alertCenter.perf.ts`、`docs/perf-sc004.md`
- [ ] T111 [P] 建立月報 PDF SC-003 效能驗收（量測 html2canvas + jsPDF save 完成時間 ≤30 秒，記錄瓶頸與截圖）→ `frontend/src/utils/pdfPerfTest.ts`、`docs/perf-sc003.md`
- [ ] T112 [P] 建立測試覆蓋率 gate（前端 Vitest coverage、後端 Jest coverageThreshold；修改模組 ≥80%，輸出 lcov）→ `frontend/vite.config.ts`、`backend/jest.config.ts`、`.github/workflows/ci.yml`
- [ ] T113 [P] 建立 WCAG 2.1 AA 無障礙測試（jest-axe 掃描 StatusBadge、AlertBanner、DeviceTable、AlertTable、RiskTable 與六頁主要元件；axe 違規歸零）→ `frontend/tests/accessibility/`
- [ ] T114 [P] 建立使用者工作流程可用性審查文件（逐一走查 US1–US6、導覽、告警三步驟、月報匯出、決策頁；待改善項須列入追蹤）→ `docs/ux-review.md`
- [ ] T115 [P] 建立完整 PR CI workflow（frontend/backend lint、unit、integration、coverage、build、critical path benchmark；任一失敗阻擋合併）→ `.github/workflows/ci.yml`
- [ ] T116 [P] 建立前端 render 與 bundle 預算基準（六頁首次 render/互動後 render p95 ≤500ms；gzip bundle ≤2MB）→ `frontend/tests/performance/render.benchmark.ts`、`frontend/tests/performance/bundle-budget.test.ts`
- [ ] T117 [P] 建立後端資源預算與輪詢壓測（後端記憶體 ≤512MB、10 並發 30 秒輪詢 CPU <50%、無記憶體洩漏；整合 perf workflow）→ `backend/tests/performance/resource-budget.k6.ts`、`docs/perf-resource-budget.md`
- [ ] T118 建立 staging 部署驗證流程（production 前必須 staging；docker compose smoke test、health、登入、六頁主要路由、API health）→ `.github/workflows/staging.yml`、`docs/staging-release-checklist.md`
- [ ] T119 [P] 補齊安全強化與驗證（Nginx CSP/X-Frame-Options/X-Content-Type-Options；CORS 僅 ALLOWED_ORIGIN；JWT_SECRET ≥64；cookie httpOnly/SameSite=Lax；登入限流與防帳號枚舉測試）→ `docker/nginx/default.conf`、`backend/src/app.ts`、`backend/tests/integration/security.test.ts`
- [ ] T120 驗證 Docker Compose 全端整合啟動（nginx 代理、前後端連線、健康檢查、登入與主要路由 smoke test）→ `docker/docker-compose.yml`、`docs/docker-smoke-test.md`
- [ ] T121 [P] 執行 quickstart.md 驗證並修正驗證紀錄（本機啟動、migration、seed、前後端測試、Docker Compose、常見問題命令可執行；結果以繁中記錄）→ `specs/001-heatpump-dashboard-6pages/quickstart.md`、`docs/quickstart-validation.md`
- [ ] T122 [P] 同步最終規格追溯矩陣（FR-001～FR-036、SC-001～SC-007 對應任務 ID；供 PR 描述引用）→ `docs/spec-traceability.md`

---

## 依賴關係圖

```text
第 1 階段（專案建置）
    └── 第 2 階段（基礎設施：DB Schema + Auth + React 骨架 + real/mock 資料來源）
            ├── 第 3 階段（US1 設備總覽 P1）🎯 MVP
            ├── 第 4 階段（US4 告警中心 P1）
            ├── 第 5 階段（US2 風險排序 P2）
            ├── 第 6 階段（US3 單機履歷 P2）
            ├── 第 7 階段（US5 月報雛形 P3）
            └── 第 8 階段（US6 老闆決策頁 P3）

第 9 階段（收尾與橫切面）
    └── 依賴要納入 release 的故事完成後執行
```

### 使用者故事依賴

- **US1 設備總覽（P1）**：第 2 階段後可開始；MVP 最小可展示範圍。
- **US4 告警中心（P1）**：第 2 階段後可開始；依 devices/technicians/alerts schema，但不依賴 US1 前端。
- **US2 風險排序（P2）**：第 2 階段後可開始；依 MySQL device_risk_snapshots、alerts、work_orders、devices 狀態與 risk_score_weights，不直接依賴 daily summary/mock 能耗資料。
- **US3 單機履歷（P2）**：第 2 階段後可開始；依 devices routes、Influx queries、mock loader。
- **US5 月報雛形（P3）**：第 2 階段後可開始；依 reportService 聚合 alerts/devices/risk_score。
- **US6 老闆決策頁（P3）**：第 2 階段後可開始；依 executiveService、work_orders、risk top clients。

### 平行執行範例

- **Setup**：T002、T003、T004、T005、T006 可平行。
- **基礎設施**：T009、T010、T011、T016、T017、T019、T021、T023、T025～T028、T030～T034 可在不同檔案平行。
- **P1 故事**：US1（T035～T043）與 US4（T044～T056）可由不同人同時推進。
- **P2 故事**：US2（T057～T065）與 US3（T066～T078）可平行，但共用 `backend/src/routes/devices.ts` 的 US3 任務需協調。
- **P3 故事**：US5（T079～T089）與 US6（T090～T101）可平行。
- **收尾**：T102、T104、T106～T117、T119、T121、T122 多數可平行；T118/T120 建議在 Docker 與 CI 初步完成後執行。

---

## 實作策略

### MVP 優先

1. 完成第 1 階段：專案建置（T001～T006）。
2. 完成第 2 階段：基礎設施（T007～T034）。
3. 完成第 3 階段：US1 設備總覽（T035～T043）。
4. 停下來驗收：登入後設備總覽可顯示 7 real + 73 mock 的 80 台設備、篩選/搜尋/導向可用、SC-001 達標。

### 漸進式交付

| 里程碑 | 交付內容 | 任務範圍 |
|--------|----------|----------|
| M1 MVP | 登入 + 設備總覽 | T001～T043 |
| M2 P1 完成 | + 告警中心 | T044～T056 |
| M3 P2 完成 | + 風險排序 + 單機履歷 | T057～T078 |
| M4 全功能 | + 月報 + 老闆決策頁 | T079～T101 |
| Release Gate | 品質、安全、效能、staging | T102～T122 |

### 品質閘門

- 每個故事的測試任務必須先完成並確認失敗。
- 所有新增/修改模組覆蓋率 ≥ 80%。
- API p95 與主要 UI render p95 必須 ≤500ms。
- 告警中心 80 筆告警頁面載入 ≤3 秒。
- 月報 PDF 產生 ≤30 秒，月報準備流程 ≤5 分鐘。
- 後端記憶體 ≤512MB，前端 gzip bundle ≤2MB。
- 所有使用者可見文字與文件維持繁體中文（zh-TW）。

---

## 任務計數摘要

| 階段 | 任務數 | 說明 |
|------|--------|------|
| 第 1 階段：專案建置 | 6 | T001～T006 |
| 第 2 階段：基礎設施 | 28 | T007～T034 |
| 第 3 階段：US1 設備總覽 | 9 | T035～T043 |
| 第 4 階段：US4 告警中心 | 13 | T044～T056 |
| 第 5 階段：US2 風險排序 | 9 | T057～T065 |
| 第 6 階段：US3 單機履歷 | 13 | T066～T078 |
| 第 7 階段：US5 月報雛形 | 11 | T079～T089 |
| 第 8 階段：US6 老闆決策頁 | 12 | T090～T101 |
| 第 9 階段：收尾與橫切面 | 21 | T102～T122 |
| **合計** | **122** | |

**平行機會**：標記 [P] 的任務可在不同檔案與不互相依賴時平行執行。  
**建議 MVP 範圍**：T001～T043，交付登入、共用基礎、real/mock 混合設備總覽。
