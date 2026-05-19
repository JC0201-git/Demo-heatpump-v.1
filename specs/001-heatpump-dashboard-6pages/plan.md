# 技術規劃：熱泵／熱水系統監控儀表板（6 頁）

**分支**: `001-heatpump-dashboard-6pages` | **日期**: 2026-05-17 | **規格**: [spec.md](./spec.md)  
**輸入**: 功能規格 `/specs/001-heatpump-dashboard-6pages/spec.md`

---

## 技術摘要

本系統為熱泵與熱水設備維運監控 Dashboard，管理最多 80 台設備（7 台真實資料 + 73 台 Mock）。系統以「快速完成 Demo、可平順升級到 MVP」為雙目標：Demo 階段以靜態 Mock 資料填充、後端快速整合已知 InfluxDB / MySQL；MVP 階段再逐步替換 Mock 設備為真實資料，並加入自動告警判斷與角色權限。

**選定技術棧**：
- 前端：React 18 + TypeScript 5 + Vite + ECharts + Zustand
- 後端：Fastify 4 + TypeScript 5 + Drizzle ORM（MySQL 2）+ `influx`（InfluxDB 1.x）
- 資料庫：MySQL 8.0（管理資料）+ InfluxDB 1.8（時序資料）
- 認證：JWT（httpOnly cookie，8 小時有效期）
- 部署：Docker Compose + Nginx reverse-proxy，前端主機（EC2-A）與資料庫主機（EC2-B）

---

## 技術脈絡

**語言 / 版本**: TypeScript 5.x（前端 React 18、後端 Node.js 20 LTS）
**主要依賴**: Fastify 4、Drizzle ORM、influx（InfluxDB 1.x）、ECharts、Zustand、jsPDF + html2canvas
**儲存層**: MySQL 8.0（管理與告警資料）+ InfluxDB 1.8（時序用電與設備狀態）
**測試工具**: Vitest（前端）+ Jest + Supertest（後端 API）；覆蓋率目標 ≥ 80%
**目標平台**: Ubuntu Linux 22.04（AWS EC2）；桌面瀏覽器 Chrome / Firefox，1280px 以上
**專案類型**: web-service（前後端分離 + REST API）
**效能目標**: API p95 ≤ 500 ms；告警中心頁面載入 ≤ 3 秒；月報 PDF ≤ 30 秒；主要 UI 首次 render 與互動後 render p95 ≤ 500 ms
**限制條件**: 後端記憶體預算 ≤ 512 MB；前端 bundle ≤ 2 MB gzip；前端不可直接連接資料庫
**規模 / 範圍**: 80 台設備、6 頁面、~10 位並發使用者

---

## Constitution 合規檢查

*品質閘門：第 0 階段研究前須通過；第 1 階段設計後再複核。*

- [x] **I. Code Quality**：ESLint + Prettier（前端）、ESLint（後端）已確認；函式圈複雜度上限 10，超過者須拆分 service。
- [x] **II. Testing Standards**：Vitest（前端）/ Jest + Supertest（後端）已選定；目標覆蓋率 ≥ 80%；所有使用者故事、API handler 與風險分數計算均採 Red-Green-Refactor，任務清單以「測試先行」小節明確排序。
- [x] **III. UX Consistency**：設計 token（深綠黑底 `#0d1f1a`、強調色 `#a3e635`、警示色紅 `#ef4444`、離線色灰 `#6b7280`）；WCAG 2.1 AA 最低標準。
- [x] **IV. Performance Requirements**：API p95 ≤ 500 ms（快取輔助）；主要 UI render p95 ≤ 500 ms；後端記憶體 ≤ 512 MB；前端 bundle ≤ 2 MB；CI benchmark 覆蓋 API critical path 與 UI render；staging deployment 必須先於 production release。
- [x] **V. Documentation Language**：本計畫及所有 spec / quickstart 文件以繁體中文（zh-TW）撰寫；UI 文案、錯誤訊息均為繁體中文；程式模組名稱 / API 端點保留英文。

---

## 專案結構

### 文件（本功能）

```text
specs/001-heatpump-dashboard-6pages/
├── plan.md              # 本文件（/speckit.plan 輸出）
├── research.md          # 第 0 階段研究報告
├── data-model.md        # 第 1 階段資料模型
├── quickstart.md        # 第 1 階段快速入門
├── contracts/           # 第 1 階段 API 合約
│   ├── auth.md
│   ├── devices.md
│   ├── alerts.md
│   └── risk-reports-executive-system.md
└── tasks.md             # 第 2 階段任務清單（/speckit.tasks 輸出）
```

### 原始碼（儲存庫根目錄）

```text
Demo-heatpump-v.1/
├── frontend/
│   ├── src/
│   │   ├── components/       # 共用元件（StatusBadge、AlertBanner 等）
│   │   ├── pages/            # 六個主頁面元件
│   │   │   ├── DeviceList/
│   │   │   ├── RiskRanking/
│   │   │   ├── DeviceHistory/
│   │   │   ├── AlertCenter/
│   │   │   ├── MonthlyReport/
│   │   │   └── ExecutiveDashboard/
│   │   ├── stores/           # Zustand store（deviceStore、alertStore）
│   │   ├── services/         # API 呼叫層（axios instance）
│   │   ├── types/            # TypeScript 共用型別
│   │   └── utils/            # 日期格式化、顏色映射等
│   ├── tests/
│   │   ├── unit/
│   │   └── integration/
│   └── vite.config.ts
├── backend/
│   ├── src/
│   │   ├── routes/           # Fastify route handlers（auth、devices、risk、alerts 等）
│   │   ├── services/         # 業務邏輯（riskScoreService、dataSourceService 等）
│   │   ├── db/               # Drizzle schema + migrations（MySQL）
│   │   ├── influx/           # InfluxDB 1.x 查詢模組
│   │   ├── mock/             # Mock JSON 資料載入器
│   │   ├── jobs/             # node-cron 排程（daily summary 彙整）
│   │   ├── middleware/        # JWT 驗證、rate-limit
│   │   └── types/            # 共用 DTO 型別
│   ├── tests/
│   │   ├── unit/
│   │   ├── integration/
│   │   └── performance/
│   └── tsconfig.json
├── mock-data/
│   └── devices/              # 73 個 Mock JSON 檔（DEV-008 ～ DEV-080）
├── docker/
│   ├── docker-compose.yml
│   ├── nginx/
│   │   └── default.conf
│   └── env.example
├── docs/                     # 效能驗收截圖（perf-sc003.png、perf-sc004.png）
└── specs/
```

**結構決策**：採 Option 2 前後端分離，前後端各自為獨立 Docker service，透過 Nginx reverse-proxy 統一對外。

---

## 一、系統架構說明

```
┌─────────────────────────────────────────────────────┐
│  EC2-A（Dashboard 主機）                             │
│  ┌────────────────┐   ┌────────────────────────────┐ │
│  │  Nginx (80/443) │──▶│  frontend (React, port 80) │ │
│  └───────┬────────┘   └────────────────────────────┘ │
│          │ /api/*                                     │
│          ▼                                            │
│  ┌────────────────┐                                   │
│  │ backend-api    │  （Fastify, port 3001）            │
│  └───────┬────────┘                                   │
└──────────┼──────────────────────────────────────────┘
           │  AWS VPC 私有 IP（Security Group 限制）
┌──────────┼──────────────────────────────────────────┐
│  EC2-B（資料庫主機）                                  │
│  ├─ MySQL 8.0（port 3306）                           │
│  └─ InfluxDB 1.8（port 8086）                        │
└─────────────────────────────────────────────────────┘
```

**跨 EC2 連線安全**：
- EC2-B Security Group：port 3306 / 8086 僅允許 EC2-A 的 Security Group ID 進入
- 後端使用環境變數管理 DB 連線字串（不進 Git）
- CORS：後端只允許前端主機域名（`ALLOWED_ORIGIN` 環境變數）
- Nginx 負責 HTTPS 終止（MVP 加入 Let's Encrypt），Demo 階段可先 HTTP

---

## 二、前端架構規劃

### 技術選型

| 項目 | 選擇 | 理由 |
|------|------|------|
| 框架 | React 18 + TypeScript 5 | 規格指定 |
| 建構工具 | Vite 5 | 開發速度快，HMR 即時 |
| 圖表 | Apache ECharts（`echarts-for-react`）| 規格指定 |
| 狀態管理 | Zustand 4 | 輕量、TypeScript 友善 |
| HTTP 請求 | Axios + React hooks 封裝 | 攔截器統一處理 401 / 錯誤 |
| PDF 匯出 | jsPDF + html2canvas | 規格指定前端方案 |
| 路由 | React Router v6 | 標準選擇 |
| 樣式 | Tailwind CSS v3（深色主題）| 快速排版，主題 token 統一管理 |
| Linting | ESLint + Prettier | Constitution I 要求 |
| 測試 | Vitest + Testing Library | 與 Vite 生態整合 |

### 設計 Token

```typescript
// tailwind.config.ts 主題設定
colors: {
  bg: {
    primary: '#0d1f1a',    // 主背景（深綠黑）
    secondary: '#112820',  // 卡片 / 側欄背景
    tertiary: '#1a3a2e',   // hover / 強調背景
  },
  accent: {
    primary: '#a3e635',    // 黃綠色主強調（lime-400）
    secondary: '#84cc16',  // lime-500
  },
  status: {
    normal: '#22c55e',     // 綠色（正常）
    alert: '#ef4444',      // 紅色（異常）
    offline: '#6b7280',    // 灰色（離線）
    maintenance: '#f97316',// 橙色（待維修）
  }
}
```

### 頁面元件清單

| 頁面 | 元件路徑 | 主要子元件 |
|------|----------|-----------|
| 設備總覽 | `pages/DeviceList/` | `DeviceTable`、`StatusFilter`、`SearchBar` |
| 風險排序 | `pages/RiskRanking/` | `RiskTable`、`RankBadge`、`RankChangeBadge` |
| 單機履歷 | `pages/DeviceHistory/` | `DeviceInfoCard`、`PowerChart`、`OperationChart`、`AlertTimeline`、`WorkOrderList` |
| 告警中心 | `pages/AlertCenter/` | `AlertTable`、`AlertFilter`、`AssignModal`、`ResolveButton` |
| 月報雛形 | `pages/MonthlyReport/` | `MonthPicker`、`HealthSummaryChart`、`AnomalyBarChart`、`AlertRateCard`、`ExportPdfButton` |
| 老闆決策頁 | `pages/ExecutiveDashboard/` | `KpiCard`、`WorkloadTable`、`RiskClientList`、`CapacityGauge` |

### 資料刷新策略

```typescript
// hooks/usePolling.ts
// 全域輪詢服務集中管理設備狀態、告警與風險摘要刷新（系統設定 polling_interval_sec 可調）
// 使用者登入後啟動，每 30 秒重新取得最新資料；頁面切換時不重置計時器
// 登出或離開受保護區域時停止輪詢並清理 timer，避免背景請求殘留
// 各頁面透過共用 store 訂閱資料，不各自建立獨立 timer
// API 無回應時顯示「API 連線異常」橫幅，保留最後快取值
```

---

## 三、後端 API 架構規劃

### 技術選型（詳見 research.md 研究 1～4）

| 項目 | 選擇 | 理由 |
|------|------|------|
| 框架 | Fastify 4 | TypeScript 原生、內建 JSON Schema 驗證、序列化效能佳 |
| ORM | Drizzle ORM（mysql2）| TypeScript-first、輕量、SQL-like 語法 |
| InfluxDB | `influx` npm（@5.x）| 專為 InfluxDB 1.x InfluxQL 設計 |
| 認證 | `@fastify/jwt` + httpOnly cookie | stateless、安全 |
| 快取 | 記憶體快取（`node-cache`）| Demo 階段不需 Redis |
| 排程 | `node-cron` | daily summary 彙整 |
| 測試 | Jest + Supertest | API 整合測試 |

### 後端模組架構

```text
backend/src/
├── routes/
│   ├── auth.ts          # POST /api/auth/login, logout, GET /me
│   ├── devices.ts       # GET /api/devices, /:deviceId, /power, /operation, /alerts, /work-orders
│   ├── risk.ts          # GET /api/risk/top-devices, /top-clients, /rules; PUT /api/risk/rules
│   ├── alerts.ts        # GET /api/alerts; PUT /:alertId/assign, /:alertId/resolve
│   ├── technicians.ts   # GET /api/technicians（active 技師清單，供 AssignModal 使用）
│   ├── reports.ts       # GET /api/reports/monthly
│   ├── executive.ts     # GET /api/executive/summary, /capacity
│   └── system.ts        # GET /api/system/last-updated, /health
├── services/
│   ├── dataSourceService.ts   # 根據 data_source_type 路由至 real 或 mock
│   ├── riskScoreService.ts    # 風險分數計算
│   ├── alertService.ts        # 告警指派與解除業務邏輯
│   ├── reportService.ts       # 月報資料聚合
│   └── executiveService.ts    # 老闆決策頁資料聚合
├── db/
│   ├── schema.ts        # Drizzle schema（所有資料表）
│   └── migrations/      # 自動生成的 SQL migration
├── influx/
│   └── queries.ts       # 封裝 InfluxQL 查詢函式
├── mock/
│   └── loader.ts        # 啟動時載入 73 個 Mock JSON 至記憶體
├── jobs/
│   └── dailySummaryJob.ts  # node-cron：每日 00:05 彙整 energy/heatpump daily summary
└── middleware/
    └── auth.ts           # JWT 驗證 hook
```

### API 回應統一格式

```typescript
// 成功回應
{ "data": <payload>, "meta": { "updatedAt": "ISO8601", "total"?: number } }

// 錯誤回應
{ "error": "ERROR_CODE", "message": "繁體中文錯誤訊息", "statusCode": number }
```

### 快取策略

| 資料類型 | TTL | 說明 |
|---------|-----|------|
| 設備列表 / 即時狀態 | 25 秒 | 配合 30 秒輪詢，大多請求走快取 |
| 風險分數 Top 10 | 5 分鐘 | 分數每 5 分鐘重算一次 |
| 月報資料 | 5 分鐘 | 歷史彙整結果不頻繁變動 |
| 老闆決策頁 | 5 分鐘 | KPI 數據不需即時 |

---

## 四、InfluxDB 1.8 資料模型

（完整 DDL 與欄位定義見 [data-model.md](./data-model.md) 第二節）

### 必要 Measurement

| Measurement | 用途 | 寫入頻率 |
|-------------|------|---------|
| `power_meter` | 電錶即時資料（三相電壓/電流、kW、kWh、PF）| 每分鐘 |
| `heatpump_status` | 熱泵狀態（運轉模式、溫度、COP、開機次數）| 每分鐘 |
| `energy_daily_summary` | 每日用電彙總（由 node-cron 彙整）| 每日 00:05 |
| `heatpump_daily_summary` | 每日運轉彙總（運轉時數、開機次數、COP）| 每日 00:05 |

### 建議 Measurement（MVP 延後）

| Measurement | 用途 | 必要性 |
|-------------|------|--------|
| `operation_log` | 設備事件日誌（開機/關機/故障）| MVP 建議 |

### 缺欄位容錯

- 不支援 COP 設備：`cop` 欄位不寫入（非 null）
- 後端 InfluxQL 查詢缺 field → 回傳 `null`
- 前端 `supportsCoP: false` + `null` → 顯示「不適用」
- 前端 `supportsCoP: true` + `null` → 顯示 `--`（資料暫缺）

---

## 五、MySQL 資料表設計

（完整 DDL 見 [data-model.md](./data-model.md) 第三節）

### 資料表清單

| 資料表 | 用途 |
|--------|------|
| `clients` | 客戶主檔 |
| `sites` | 場域主檔（client 1:N site）|
| `devices` | 設備主檔（80 台，含 `data_source_type`）|
| `meters` | 電錶主檔（設備電錶 / 場域總電錶）|
| `device_meter_mappings` | 設備–電錶 N:M mapping（含 `share_ratio`）|
| `alerts` | 告警資料（含 `source` 欄位預留 auto）|
| `work_orders` | 維修工單 |
| `technicians` | 維運人員 |
| `users` | 登入帳號（含 `role` 欄位，v1 不啟用）|
| `system_settings` | 系統設定（輪詢間隔、告警門檻、維運容量等；含 `ALERT_OVERDUE_HOURS=24`）|
| `device_risk_snapshots` | 風險分數六維度 MySQL 快照欄位，供風險排序計算讀取 |
| `risk_score_weights` | 風險分數權重（6 項，加總 100）|

---

## 六、熱泵設備與電錶 Mapping 設計

### 設計目標

- 支援「多台熱泵共用一顆設備電錶」（`share_ratio` 欄位）
- 支援「場域總電錶」與「設備電錶」共存
- 熱泵 `device_id` ≠ 電錶 `meter_id`，必須透過 `device_meter_mappings` 關聯

### 典型場景

```
場域 A（site_id = 1）
├── meter: METER-001（site_meter，場域總電錶）
├── device: DEV-001 ── mapping ── METER-002（device_meter, share_ratio=1.0）
├── device: DEV-002 ──┐
│                    ├── mapping ── METER-003（device_meter, share_ratio=0.5）
└── device: DEV-003 ──┘
```

### 查詢設備用電（InfluxDB）

```sql
-- 1. 從 MySQL 查出 device 對應的 influx_meter_tag 與 share_ratio
-- 2. 查詢 InfluxDB energy_daily_summary
SELECT mean("kwh_total") * {share_ratio}
FROM "energy_daily_summary"
WHERE "meter_id" = '{influx_meter_tag}'
  AND time >= now() - 30d
GROUP BY time(1d) fill(null)
```

---

## 七、API Endpoint 規劃

（詳細 Request / Response 格式見 `contracts/` 目錄各合約文件）

### 端點總覽

| 模組 | 端點 | 說明 |
|------|------|------|
| Auth | `POST /api/auth/login` | 登入，設定 httpOnly JWT cookie |
| Auth | `POST /api/auth/logout` | 清除 cookie |
| Auth | `GET /api/auth/me` | 取得當前使用者資訊 |
| Devices | `GET /api/devices` | 設備列表（支援狀態篩選 / 搜尋 / 分頁）|
| Devices | `GET /api/devices/:deviceId` | 設備詳細資訊 |
| Devices | `GET /api/devices/:deviceId/power` | 30 日用電資料 |
| Devices | `GET /api/devices/:deviceId/operation` | 30 日運轉資料 |
| Devices | `GET /api/devices/:deviceId/alerts` | 設備異常事件列表 |
| Devices | `GET /api/devices/:deviceId/work-orders` | 設備維修工單列表 |
| Risk | `GET /api/risk/top-devices` | Top 10 高風險設備 |
| Risk | `GET /api/risk/top-clients` | Top 5 高風險客戶 |
| Risk | `GET /api/risk/rules` | 讀取風險分數權重 |
| Risk | `PUT /api/risk/rules` | 更新風險分數權重 |
| Alerts | `GET /api/alerts` | 告警列表（支援狀態 / 類型篩選 / 分頁）|
| Alerts | `PUT /api/alerts/:alertId/assign` | 指派負責人 |
| Alerts | `PUT /api/alerts/:alertId/resolve` | 更新為已解除 |
| Technicians | `GET /api/technicians` | 查詢 active 技師清單（供告警指派 AssignModal 使用）|
| Reports | `GET /api/reports/monthly` | 月報資料（`?month=YYYY-MM`）|
| Executive | `GET /api/executive/summary` | 老闆決策頁 KPI 與負載資料 |
| Executive | `GET /api/executive/capacity` | 擴張承載能力分析 |
| System | `GET /api/system/last-updated` | 最後資料更新時間 |
| System | `GET /api/system/health` | 後端健康狀態 |

### 通用策略

- **分頁**：`page` + `limit`（預設 limit=50，告警；devices 預設 80）
- **時間區間**：`?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD`（預設最近 30 天）
- **錯誤處理**：統一 `{ error, message, statusCode }` 格式；4xx 含繁中說明
- **認證**：除 `/api/auth/login`、`/api/system/health` 外，所有端點需有效 JWT

### 月報逾時未處理計算規則

- 月報 `alertStats.overdueCount` 統計狀態仍為 `open` 或 `in_progress`，且 `occurred_at` 距月報產生時間超過逾時門檻的告警。
- 逾時門檻來源為 `system_settings.ALERT_OVERDUE_HOURS`，預設值為 24 小時。
- 若設定值缺漏或無法解析為正整數，後端採 24 小時作為保守 fallback，並在服務日誌記錄設定異常。

### 擴張承載能力計算規則

- 安全承接線 v1 固定為總設備承載量的 95%，保留 5% 緩衝給突發維修、離線追查與未排程工單；此比例為 Demo 階段的業務保守門檻。
- `totalMaxCapacity = activeTechnicianCount × MAX_DEVICES_PER_TECH`；`MAX_DEVICES_PER_TECH` 來源為 `system_settings`，與工單產能用的 `MAX_WORK_ORDERS_PER_TECH` 不可混用。
- `maxSafeAddDevices = totalMaxCapacity × 0.95 − currentDevices`；顯示時向下取整，若結果小於 0 則顯示 0 並標示目前已超過安全線。
- `projectedUtilization = (currentDevices + addDevices) / totalMaxCapacity × 100`，供老闆決策頁判斷新增 N 台設備後是否仍低於 95% 安全線。
- MVP 若需要依季節、人員等級或 SLA 調整安全線，可將 95% 抽為 `system_settings.CAPACITY_SAFETY_FACTOR`，但 v1 不提供前端設定頁。

---

## 八、登入與安全性規劃

### 認證機制

- JWT（stateless）存於 httpOnly cookie（`hp_token`）
- `SameSite=Lax`，CSRF 防護
- 有效期 8 小時（配合值班工作時段）
- v1 不需 refresh token（MVP 可加）

### 密碼安全

- bcrypt 雜湊，cost factor = 12
- 登入失敗統一回傳「帳號或密碼錯誤」（不區分原因，防帳號枚舉）
- 登入 API 限流：10 次 / 分鐘 / IP

### 跨域與網路安全

- Nginx 設定：`X-Frame-Options: DENY`、`X-Content-Type-Options: nosniff`、`Content-Security-Policy`
- CORS：後端只允許 `ALLOWED_ORIGIN` 環境變數指定的域名
- EC2-B Security Group：只允許 EC2-A Security Group ID 存取 3306 / 8086

### 環境變數管理

```dotenv
JWT_SECRET=<至少 64 字元隨機字串>
MYSQL_PASSWORD=<不進 Git>
INFLUXDB_PASSWORD=<不進 Git>
ALERT_OVERDUE_HOURS=24
ALERT_EVALUATION_ENABLED=false
```

> `.env` 加入 `.gitignore`；提供 `docker/env.example` 範本

---

## 九、Mock / Real 資料來源整合策略

### 資料來源抽象層（`dataSourceService.ts`）

```typescript
async function getDevicePower(deviceCode: string, days: number): Promise<PowerDailySummary[]> {
  const device = await db.query.devices.findFirst({ where: eq(devices.deviceCode, deviceCode) });
  if (device.dataSourceType === 'real') {
    return influxQueries.getPowerSummary(device.influxDeviceTag, days);
  } else {
    return mockLoader.getPowerSummary(device.mockDataFile, days);
  }
}
```

### 原則

- 前端不知道資料來自 real 或 mock（API response 格式完全一致）
- `devices.data_source_type` 決定路由
- 73 個 Mock JSON 後端啟動時一次載入至記憶體（~438 KB）
- 將 mock 改為 real：只需更新 `devices` 表的 `data_source_type`、`influx_device_tag`，前端零修改

### Mock JSON 結構（每台設備一個 JSON）

Mock JSON 欄位命名以 `data-model.md` 第六節與 T011 為準，避免 mock loader 與測試資料產生器使用不同 schema。

```json
{
  "deviceCode": "DEV-008",
  "realtimeStatus": { "status": "normal", "powerKw": 4.8 },
  "powerDailySummary": [
    { "date": "2026-04-18", "kwhTotal": 115.2, "kwhPeak": 18.4, "avgPowerKw": 4.8, "anomalyFlag": false }
  ],
  "operationDailySummary": [
    { "date": "2026-04-18", "runHours": 18.5, "startupCount": 3, "avgCop": 3.2 }
  ],
  "alerts": [],
  "workOrders": []
}
```

---

## 十、風險分數計算設計

### Demo 版本公式（v1）

業務方已確認公式（存於 `risk_score_weights` 資料表，可動態調整）：

```
riskScore = Σ (dimension_score_i × weight_i / 100)

維度：
  alert_severity      (w=30)：高告警×10 + 中告警×5 + 低告警×2，正規化至0-100
  recent_anomaly_7d   (w=20)：近7日異常次數 × 2，上限20，正規化至0-100
  offline_hours       (w=20)：今日離線時數 × 5，上限20，正規化至0-100
  open_work_orders    (w=15)：未完成工單數 × 7.5，上限15，正規化至0-100
  energy_anomaly      (w=10)：超過歷史均值20% → 10分，否則0分
  overdue_maintenance (w= 5)：距上次完工 >180 天 → 5分，否則0分
```

風險分數計算的直接資料來源為 MySQL `device_risk_snapshots` 快照欄位與 `risk_score_weights`。`riskSnapshotService` 每 5 分鐘從 MySQL 告警、工單、設備狀態與已同步的能耗異常快照更新六維度分數；`riskScoreService` 不直接查 InfluxDB 或 Mock daily summary。

### MVP 版本公式升級路線

- 加入 InfluxDB 維度（COP 下降趨勢、功率異常比率）
- 業務方提供新公式後，更新 `risk_score_weights` 即可，無需改程式
- 若需自訂計算邏輯（非線性），預留 `rule_type` 欄位支援 `linear` / `custom` 模式

---

## 十一、告警中心 v1 與 MVP 演進設計

### v1（Demo）：顯示型告警中心

```
MySQL alerts 表 ──▶ GET /api/alerts ──▶ 前端告警列表
                       ├── PUT /:id/assign   → 更新 assigned_to、status='in_progress'
                       └── PUT /:id/resolve  → 更新 resolved_at、status='resolved'
```

- 告警資料由人工寫入 MySQL（或從現有系統匯入）
- 未指派告警置於列表最上方
- 高嚴重性告警紅色背景視覺突出

### MVP 演進：判斷型告警中心

本階段只保留 schema 與 feature flag 預留，不建立 `AlertEvaluationJob` 模組。以下為 MVP 才新增的目標資料流：

```
InfluxDB 時序資料 ──▶ AlertEvaluationJob（每分鐘執行）
                        ├── 設備離線 >5 min → 新增 alert（source='auto'）
                        ├── COP < 2.0 持續 30 min → 新增 alert
                        ├── 功率超過閾值 20% → 新增 alert
                        └── 長時間未心跳 → 新增 alert
```

- Demo 階段：僅設計 `alerts.source = 'auto'` 欄位與 `ALERT_EVALUATION_ENABLED=false` feature flag 預留，不排入實作任務
- MVP 階段：新增 `AlertEvaluationJob`、判斷規則、測試與部署監控後，才可開啟 feature flag

---

## 十二、Docker Compose 部署規劃

### Demo 部署（EC2-A）

```yaml
# docker/docker-compose.yml
services:
  frontend:
    build: ./frontend
    expose: ["80"]

  backend-api:
    build: ./backend
    expose: ["3001"]
    env_file: ./docker/.env
    depends_on: []  # MySQL / InfluxDB 在 EC2-B，不進 compose

  reverse-proxy:
    image: nginx:1.25-alpine
    ports: ["80:80"]
    volumes:
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on: [frontend, backend-api]
```

**Nginx 路由規則**：
```nginx
location /api/ { proxy_pass http://backend-api:3001; }
location /     { proxy_pass http://frontend:80; }
```

### EC2-B（MySQL / InfluxDB）

- 現有服務不納入 Docker Compose
- 後端透過 VPC 私有 IP 連線（`MYSQL_HOST`、`INFLUXDB_HOST` 環境變數）

### MVP 升級方式

1. 加入 HTTPS（Nginx + Let's Encrypt certbot）
2. 可選加入 Redis service（session 快取 / 短路保護）
3. 加入 CI/CD（GitHub Actions 自動 build + deploy）

---

## 十三、Demo 階段開發順序

| 順序 | 階段 | 主要任務 |
|------|------|---------|
| 1 | 基礎設施 | Docker Compose、Nginx、環境變數、DB Migration 腳本 |
| 2 | 後端骨架 | Fastify 專案初始化、JWT 認證、health endpoint |
| 3 | Mock 資料 | 73 個 Mock JSON 產生腳本、mock loader |
| 4 | MySQL Seed | 80 台設備、客戶、場域初始資料 |
| 5 | 設備總覽 API | GET /api/devices（real + mock 整合）|
| 6 | 前端骨架 | React 專案、Tailwind 深色主題、導覽列、登入頁 |
| 7 | 全域輪詢與狀態基礎 | 全域 polling、PageStatusHeader、stale 資料顯示 |
| 8 | 設備總覽頁 | 列表、篩選、搜尋、狀態標籤 |
| 9 | 告警中心 API | alerts CRUD、assign / resolve |
| 10 | 告警中心頁 | 列表、篩選、指派 Modal |
| 11 | 風險排序 API | 風險分數計算（MySQL 維度）、Top 10 endpoint |
| 12 | 風險排序頁 | 排名列表、排名變動標示 |
| 13 | 單機履歷 API | power / operation / alerts / work-orders endpoint |
| 14 | 單機履歷頁 | 四個子頁籤、ECharts 折線圖 |
| 15 | 月報 API | monthly report 聚合 |
| 16 | 月報頁 | 圖表、PDF 匯出 |
| 17 | 老闆決策 API + 頁面 | KPI、負載、容量 |
| 18 | 整合測試 | 80 台設備完整流程驗證 |
| 19 | 效能測試 | 告警中心 ≤3 秒、月報 PDF ≤30 秒 |

---

## 十四、Demo 隔天進入 MVP 的升級路線

| 升級項目 | 工作量 | 說明 |
|---------|--------|------|
| 替換 Mock 設備 | 低 | 更新 `devices.data_source_type`，無前端改動 |
| 自動告警判斷 | 中 | 新增 `AlertEvaluationJob`、判斷規則與測試後，再開啟 feature flag |
| 角色權限控管 | 中 | `users.role` 欄位已就位，加入 middleware 判斷 |
| HTTPS | 低 | Nginx + certbot，無應用程式改動 |
| React Query 狀態快取 | 低 | 取代部分 Zustand 的輪詢邏輯，降低請求數 |
| 月報品質提升 | 中 | 改用 Puppeteer 後端 PDF 取代 html2canvas（若需要）|
| InfluxDB 維度風險分數 | 中 | 加入 COP / 功率異常維度，更新 `risk_score_weights` |

---

## 十五、測試策略

### 前端測試（Vitest + Testing Library）

| 測試類型 | 目標 | 範例 |
|---------|------|------|
| 元件渲染 | 各頁面主要元件正確渲染 | `DeviceTable` 顯示 80 台設備 |
| UI render 效能 | 主要頁面首次 render 與互動後 render p95 ≤ 500 ms | `AlertCenterPage` 80 筆告警資料 render benchmark |
| 篩選 / 搜尋 | 狀態篩選、關鍵字搜尋 | 篩選「異常」後只顯示異常設備 |
| 圖表資料 | ECharts 接收正確 series 資料 | 30 日折線圖 x 軸 = 30 個日期 |
| 缺欄位容錯 | `null` 顯示 `--` 或「不適用」 | COP 欄位 null 且 supportsCoP=false |
| 錯誤橫幅 | API 無回應顯示連線異常橫幅 | mock fetch 回傳 500 |

### 後端測試（Jest + Supertest）

| 測試類型 | 目標 |
|---------|------|
| API 單元測試 | 每個 route handler 回應格式正確 |
| 風險分數計算 | 各維度加權計算結果符合預期 |
| MySQL 查詢測試 | Drizzle query 回傳正確結構（使用測試 DB）|
| InfluxDB 查詢測試 | 模擬 InfluxQL 回應，驗證解析邏輯 |
| Mock / real 切換 | dataSourceService 根據 data_source_type 正確路由 |
| 認證 | 未帶 cookie 回傳 401；偽造 token 回傳 401 |
| 限流 | 登入超過 10 次 / 分鐘回傳 429 |

### 整合測試

| 情境 | 驗證 |
|------|------|
| 設備總覽 | 80 台設備（real + mock）正確渲染，篩選功能正常 |
| 風險排序 | Top 10 依分數降序，排名變動標示正確 |
| 單機履歷 | 四個頁籤資料正確，30 日圖表正常，缺資料顯示 `--` |
| 告警指派 | 指派後 status 變 in_progress，指派人顯示 |
| 告警解除 | 解除後記錄 resolved_at，從未處理列表移除 |
| 月報生成 | 選月份後統計數字正確，`ALERT_OVERDUE_HOURS` 逾時未處理計算正確，PDF 成功下載 |
| 老闆決策頁 | KPI 數字正確，擴張計算邏輯符合預期 |

### 效能測試（k6）

| 場景 | 目標 |
|------|------|
| 告警中心（80 筆告警）| 頁面載入 ≤ 3 秒 |
| 30 日趨勢圖 | API 回應 ≤ 500 ms（走 daily summary 快取）|
| 月報 PDF 產生 | ≤ 30 秒 |
| 主要 UI render | 首次 render 與互動後 render p95 ≤ 500 ms |
| 30 秒輪詢（10 並發）| 無記憶體洩漏，CPU < 50% |

### CI/CD 與 Staging Gate

- 每個 pull request 必須執行 lint、unit tests、integration tests、coverage threshold、build 與關鍵路徑效能 benchmark；任一失敗必須阻擋合併。
- 修改 critical path（設備列表、告警中心、風險排序、月報、老闆決策頁）時，CI 必須執行 API p95 與 UI render p95 benchmark。
- production release 前必須完成 staging deployment；staging smoke test 至少覆蓋 Docker 啟動、健康檢查、登入、六頁主要路由與 API health。

---

## 十六、技術風險與緩解措施

| 風險 | 可能性 | 影響 | 緩解措施 |
|------|--------|------|---------|
| InfluxDB 1.8 查詢效能不足 | 中 | 高 | 使用 `energy_daily_summary` 預聚合；查詢加 tag 過濾 |
| Mock JSON 與 real API 格式不一致 | 中 | 中 | 共用 TypeScript DTO 型別；整合測試強制驗證 |
| EC2 跨主機網路延遲影響 API 回應 | 低 | 中 | VPC 私有 IP 延遲 <1ms；快取降低 DB 查詢頻率 |
| PDF 匯出在不同瀏覽器圖表截圖失敗 | 中 | 低 | html2canvas 渲染等待圖表動畫完成後再截圖；加逾時保護 |
| JWT Secret 外洩 | 低 | 高 | `.env` 不進 Git；EC2 存取限制；定期輪換 |
| 80 台設備同時輪詢 API 導致 DB 壓力 | 中 | 中 | 快取 TTL 25 秒；大多請求不觸及 DB |
| Mock 資料量隨設備增加而膨脹 | 低 | 低 | 目前 438 KB 可接受；超過 10 MB 時改為按需載入 |

---

## 十七、不納入本階段的項目

- 手機版 / 響應式設計（RWD）
- 角色權限控管（`users.role` 已就位，但 v1 不啟用）
- WebSocket / SSE 即時推送（v1 使用輪詢）
- 後端 PDF 服務（Puppeteer）
- 自動告警判斷邏輯（本階段僅保留 `alerts.source` schema 與 feature flag，不建立 `AlertEvaluationJob`）
- 資料收集機制（IoT 閘道器、MQTT 等）
- 報表排程自動寄送（e-mail / LINE Notify）
- 多語言（i18n）支援
- 稽核日誌（Audit Log）
- 備份與災難恢復計畫

---

## 設計產物連結

| 產物 | 路徑 |
|------|------|
| 功能規格 | [spec.md](./spec.md) |
| 第 0 階段研究報告 | [research.md](./research.md) |
| 資料模型（InfluxDB + MySQL DDL）| [data-model.md](./data-model.md) |
| API 合約（Auth）| [contracts/auth.md](./contracts/auth.md) |
| API 合約（設備）| [contracts/devices.md](./contracts/devices.md) |
| API 合約（告警）| [contracts/alerts.md](./contracts/alerts.md) |
| API 合約（風險 / 月報 / 老闆決策）| [contracts/risk-reports-executive-system.md](./contracts/risk-reports-executive-system.md) |
| 快速入門指南 | [quickstart.md](./quickstart.md) |
