# 實作規劃：熱泵／熱水系統監控儀表板（6 頁）

**Branch**: `001-heatpump-dashboard-6pages` | **Date**: 2026-05-17 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/001-heatpump-dashboard-6pages/spec.md`

---

## 摘要

本系統為熱泵與熱水設備監控 Dashboard，涵蓋 6 個主要頁面（設備總覽、風險排序、單機履歷、告警中心、月報雛形、老闆決策頁），管理最多 80 台設備（7 台真實資料 + 73 台 Mock 資料）。

技術架構採 **React + TypeScript 前端** + **Node.js/Fastify TypeScript 後端 API**，資料來源整合 **InfluxDB 1.8 時序資料** 與 **SQL Server Express 管理資料**，部署於 AWS EC2，使用 Docker Compose 管理容器。

規劃原則：**Demo 版本快速交付（7 日內）**，架構同步支援 **MVP 隔日升級**，不做一次性展示架構。

## 技術背景

**Language/Version**: TypeScript 5.x（前端 React 18、後端 Node.js 20 LTS）  
**Primary Dependencies**: React 18、Vite、ECharts、Fastify 4、Drizzle ORM、influx（InfluxDB 1.x client）  
**Storage**: InfluxDB 1.8（時序資料）、SQL Server Express（管理資料）；同位於 EC2 主機 B  
**Testing**: Vitest（前端）、Jest（後端）；coverage ≥ 80%  
**Target Platform**: AWS EC2 Ubuntu；桌面瀏覽器 Chrome/Edge 1280px+  
**Project Type**: Web 監控儀表板（React SPA + Fastify REST API）  
**Performance Goals**:
- 告警中心頁面載入 ≤ 3 秒（80 台設備全告警場景）
- API p95 延遲 ≤ 500 ms（Constitution IV）
- 月報 PDF 產生 ≤ 30 秒
- 30 秒輪詢週期內每次請求 ≤ 200 ms

**Constraints**:
- 前端不可直接連接 InfluxDB 或 SQL Server
- InfluxDB 1.8 使用 InfluxQL（不支援 Flux）
- SQL Server Express（無 SQL Agent，排程需用 Node.js cron）
- Docker Compose 部署；InfluxDB + SQL Server Express 為既有服務

**Scale/Scope**: 80 台設備、6 頁、多帳號登入、v1 無角色權限

## Constitution Check

*GATE: 在 Phase 0 研究前必須通過。Phase 1 設計完成後再次確認。*

- [x] **I. Code Quality**: ESLint + Prettier（前端）、ESLint（後端）；cyclomatic complexity ≤ 10；TypeScript strict mode 開啟
- [x] **II. Testing Standards**: Vitest（前端）、Jest（後端）；coverage ≥ 80%；TDD 應用於 API 層與資料轉換層
- [x] **III. UX Consistency**: 深綠黑主題設計 token；WCAG 2.1 AA 需求確認用於所有新 UI 元件；錯誤訊息使用繁體中文
- [x] **IV. Performance Requirements**: p95 API ≤ 500 ms；告警列表 ≤ 3 秒；輪詢週期 30 秒；InfluxDB 歷史查詢使用快取
- [x] **V. Documentation Language**: 本規劃與所有連結文件使用繁體中文（zh-TW）；UI 文字、錯誤訊息、欄位名稱均為繁體中文

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
frontend/
├── src/
│   ├── components/         # 共用 UI 元件（StatusBadge、AlertCard、KpiCard 等）
│   ├── pages/              # 6 個主要頁面
│   │   ├── DeviceOverview/ # 設備總覽
│   │   ├── RiskRanking/    # 風險排序
│   │   ├── DeviceHistory/  # 單機履歷
│   │   ├── AlertCenter/    # 告警中心
│   │   ├── MonthlyReport/  # 月報雛形
│   │   └── ExecutiveDashboard/ # 老闆決策頁
│   ├── services/           # API 呼叫層（axios 封裝）
│   ├── hooks/              # React hooks（useDevices、useAlerts、usePolling 等）
│   ├── store/              # Zustand 全域狀態
│   ├── types/              # TypeScript 型別定義
│   └── theme/              # 設計 token（深綠黑主題）
└── tests/
    ├── unit/
    └── integration/

backend/
├── src/
│   ├── routes/             # Fastify 路由
│   ├── services/           # 業務邏輯層
│   │   ├── influx/         # InfluxDB 查詢服務
│   │   ├── sqlserver/      # SQL Server 查詢服務
│   │   ├── mock/           # Mock 資料服務
│   │   ├── risk/           # 風險分數計算
│   │   └── alert/          # 告警處理（含 AlertEvaluationService 空實作）
│   ├── data-source/        # DataSourceRouter（根據 data_source_type 路由）
│   ├── middleware/         # 認證中介層、錯誤處理
│   ├── models/             # 型別定義與 DTO
│   └── config/             # 環境變數設定
└── tests/
    ├── unit/
    └── integration/

mock-data/
└── devices/                # 73 台 Mock 設備靜態 JSON 檔

docker/
├── docker-compose.yml
├── nginx/
│   └── nginx.conf
└── .env.example
```

**Structure Decision**: 採用 Web 應用程式結構，前後端分離 Monorepo。Mock 資料獨立存放於 `mock-data/`，Docker 設定集中於 `docker/`。

## Complexity Tracking

| 違規項目 | 原因 | 更簡方案被拒絕之原因 |
|---------|------|-----------------|
| 兩個獨立資料庫（InfluxDB + SQL Server） | InfluxDB 處理時序資料效能優異；SQL Server 為既有資料庫 | 單一資料庫無法同時滿足時序查詢效能與關聯式管理資料需求 |
| 資料來源抽象層（DataSourceRouter） | 7 台真實 + 73 台 Mock 資料需透明整合 | 無抽象層則路由層需自行判斷資料來源，造成邏輯散落 |

---

## 一、技術摘要

| 類別 | 選擇 | 理由 |
|------|------|------|
| 前端框架 | React 18 + TypeScript + Vite | 生態成熟、TypeScript 嚴格型別、Vite 建置速度快 |
| 圖表 | Apache ECharts | 規格指定；深色主題支援佳；折線圖、長條圖、時間軸均支援 |
| 後端框架 | **Fastify 4** | 原生 TypeScript 支援、Schema 驗證內建、效能優於 Express 約 2x |
| 後端語言 | Node.js 20 LTS + TypeScript | 一致語言降低上下文切換；I/O 密集場景表現佳 |
| SQL Server ORM | Drizzle ORM | TypeScript-first、query builder 接近 SQL、輕量 |
| InfluxDB Client | `influx` npm 套件（InfluxDB 1.x 相容）| InfluxDB 1.8 使用 InfluxQL，不支援 Flux |
| 全域狀態管理 | Zustand | 輕量、無 boilerplate；適合本案規模 |
| HTTP Client（前端） | Axios | 攔截器易設定；JWT 自動附加 |
| 認證 | JWT（stateless）| 跨 EC2 部署無 session 共享問題；前端存於 httpOnly cookie |
| 部署 | Docker Compose + Nginx | 規格指定；易於 Demo → MVP 升級 |
| PDF 匯出 | jsPDF + html2canvas | 純前端；不需後端 PDF 服務；符合規格 |
| 快取 | node-cache（記憶體）| Demo 階段足夠；MVP 可換 Redis |

### Express vs Fastify 評估

| 評估項目 | Express | Fastify |
|---------|---------|---------|
| TypeScript 原生支援 | 需額外設定 | ✅ 內建 |
| Schema 驗證 | 需 Joi/Zod 額外整合 | ✅ JSON Schema 內建 |
| 效能（req/s） | 基準 1x | ✅ ~2x |
| 插件生態 | 豐富 | 足夠本案 |
| 序列化速度 | 標準 | ✅ fast-json-stringify 加速 |

**決策：選用 Fastify 4**，因其原生 TypeScript 支援與 Schema 驗證機制可減少手動驗證程式碼，效能更適合 30 秒輪詢場景。

---

## 二、系統架構

```
┌─────────────────────────────────────────────────────────────────┐
│  EC2 主機 A（Dashboard）                                        │
│  ┌───────────┐  ┌────────────────────────────────────────────┐ │
│  │  Nginx    │  │  Docker Compose                            │ │
│  │ (reverse  │──│  ┌────────────┐   ┌───────────────────┐   │ │
│  │  proxy)   │  │  │  frontend  │   │   backend-api     │   │ │
│  │  :443/:80 │  │  │  (React)   │   │   (Fastify)       │   │ │
│  └───────────┘  │  │  :3000     │   │   :4000           │   │ │
│                 │  └────────────┘   └─────────┬─────────┘   │ │
│                 └────────────────────────────┼──────────────┘ │
└────────────────────────────────────────────┼─────────────────┘
                                              │ HTTPS（VPC 私有 IP）
┌─────────────────────────────────────────────▼─────────────────┐
│  EC2 主機 B（資料庫）                                          │
│  ┌──────────────────────┐  ┌──────────────────────────────┐   │
│  │  InfluxDB 1.8        │  │  SQL Server Express          │   │
│  │  :8086（InfluxQL）   │  │  :1433                       │   │
│  └──────────────────────┘  └──────────────────────────────┘   │
└────────────────────────────────────────────────────────────────┘
```

**資料流**：
1. 瀏覽器 → Nginx :443 → frontend（React SPA）
2. 前端 → Nginx `/api/*` → backend-api（Fastify :4000）
3. backend-api → InfluxDB 1.8（EC2 B 私有 IP :8086）
4. backend-api → SQL Server Express（EC2 B 私有 IP :1433）
5. backend-api → mock-data JSON（本地靜態 JSON，DataSourceRouter 路由）

---

## 三、前端架構規劃

### 路由結構

| 路徑 | 頁面 | 說明 |
|------|------|------|
| `/` | 重導向至 `/devices` | |
| `/login` | 登入頁 | JWT 驗證 |
| `/devices` | 設備總覽 | FR-001～FR-005 |
| `/risk` | 風險排序 | FR-006～FR-009 |
| `/devices/:deviceId` | 單機履歷 | FR-010～FR-015 |
| `/alerts` | 告警中心 | FR-016～FR-020 |
| `/reports` | 月報雛形 | FR-021～FR-025 |
| `/executive` | 老闆決策頁 | FR-026～FR-029 |

### 狀態管理

```
Zustand stores：
├── authStore         # JWT token、目前用戶
├── deviceStore       # 設備列表、篩選條件
├── alertStore        # 告警列表、篩選條件
└── systemStore       # 最後更新時間
```

### 輪詢策略

- 自訂 `usePolling(apiCall, 30000)` hook
- 輪詢範圍：設備總覽、告警中心（需即時性頁面）
- 月報、單機履歷歷史：不輪詢，按需載入
- 頁面隱藏時（`visibilitychange`）暫停輪詢，恢復後立即刷新

### 設計 Token（深色主題）

```typescript
// theme/tokens.ts
export const colors = {
  bg: { primary: '#0a1a0f', secondary: '#0d1f14', card: '#112416' },
  accent: { primary: '#7fff00', secondary: '#adff2f', muted: '#4a7a20' },
  status: {
    normal: '#22c55e',       // 綠色＝正常
    alert: '#ef4444',        // 紅色＝異常
    offline: '#6b7280',      // 灰色＝離線
    maintenance: '#f97316',  // 橘色＝待維修
  },
  text: { primary: '#e2e8f0', secondary: '#94a3b8' },
  border: '#1e3a2a',
}
```

### 缺值處理規則

| 情況 | 顯示 |
|------|------|
| `null` / `undefined` 即時數值 | `--` |
| 設備不支援 COP（`supportsCoP: false`）| `不適用` |
| 離線設備即時欄位 | `--`（附最後更新時間） |
| 安裝不足 30 天的歷史圖表 | 圖表顯示有資料的區間，空白區間不填充 |

---

## 四、後端 API 架構規劃

### Fastify 分層架構

```
routes/          → HTTP 路由定義（Schema 驗證、JWT guard）
  └─ services/   → 業務邏輯（無 HTTP 概念）
       └─ data-source/ → DataSourceRouter
            ├─ influx/      → InfluxDB 1.8 InfluxQL 查詢
            ├─ sqlserver/   → SQL Server（Drizzle ORM）
            └─ mock/        → 靜態 JSON 讀取（啟動時快取）
```

### 統一回應格式

```typescript
// 成功（單筆）
{ "data": T, "meta": { "updatedAt": "ISO8601" } }

// 成功（列表）
{ "data": T[], "meta": { "total": number, "page": number, "limit": number, "updatedAt": "ISO8601" } }

// 錯誤
{ "error": "ERROR_CODE", "message": "繁體中文錯誤說明", "statusCode": number }
```

### 錯誤處理策略

- Fastify 全局 `setErrorHandler` 捕捉所有未處理例外
- InfluxDB 查詢逾時：5 秒；SQL Server 查詢逾時：10 秒
- 資料來源不可用時：返回快取資料或空陣列（不返回 500）
- 登入失敗：統一回傳 401，不區分「帳號不存在」與「密碼錯誤」（防枚舉攻擊）

### 快取策略（node-cache）

| 快取鍵 | TTL | 說明 |
|--------|-----|------|
| 設備狀態列表 | 25 秒 | 配合 30 秒輪詢 |
| 風險排序 | 25 秒 | |
| 月報資料 | 5 分鐘 | |
| Mock JSON 讀取 | 永久（程序週期）| 啟動時一次載入 |
| InfluxDB 30 日歷史 | 5 分鐘 | 避免重複大查詢 |

### 分頁策略

- 設備總覽：回傳全部 80 台（小資料集，無需分頁）
- 告警列表：`?page=1&limit=50`（預設 50 筆）
- 維修工單：`?page=1&limit=20`

---

## 五、InfluxDB 1.8 資料模型

### Measurement 1: `power_meter`（用電計量）

```
Tags:
  meter_id      STRING  電錶識別碼（對應 SQL Server meters.meter_code）
  site_id       STRING  場域識別碼
  customer_id   STRING  客戶識別碼
  meter_type    STRING  device_meter | site_meter

Fields:
  voltage_a     FLOAT   A 相電壓（V）
  voltage_b     FLOAT   B 相電壓（V）
  voltage_c     FLOAT   C 相電壓（V）
  current_a     FLOAT   A 相電流（A）
  current_b     FLOAT   B 相電流（A）
  current_c     FLOAT   C 相電流（A）
  power_kw      FLOAT   即時功率（kW）
  energy_kwh    FLOAT   累積用電量（kWh）
  power_factor  FLOAT   功率因數（0.0~1.0）
  frequency     FLOAT   頻率（Hz）
```

### Measurement 2: `heatpump_status`（熱泵設備狀態）

```
Tags:
  device_id     STRING  設備識別碼（對應 SQL Server devices.device_code）
  site_id       STRING  場域識別碼
  customer_id   STRING  客戶識別碼
  model         STRING  設備型號

Fields:
  operating_mode STRING  運轉模式（running | standby | fault | offline）
  inlet_temp    FLOAT   進水溫度（°C），可缺
  outlet_temp   FLOAT   出水溫度（°C），可缺
  pressure      FLOAT   系統壓力（bar），可缺
  cop           FLOAT   能效比，可缺
  startup_count INTEGER 當日開機次數
  run_hours     FLOAT   當日累計運轉時數
  alarm_code    STRING  告警代碼（空字串表示正常），可缺
  alarm_desc    STRING  告警描述，可缺
```

**缺欄位容錯**：設備不支援的感測器不寫入 InfluxDB（不寫 null）。後端查詢時遺失欄位填 `null`，前端顯示 `--` 或 `不適用`。

### Measurement 3: `energy_daily_summary`（每日用電彙總）【必要】

```
Tags:
  device_id, meter_id, site_id, customer_id

Fields:
  kwh_total     FLOAT   當日累計用電量（kWh）
  kwh_peak      FLOAT   峰值功率（kW）
  avg_power_kw  FLOAT   平均功率（kW）
  anomaly_flag  BOOLEAN 是否異常
```

每日 00:05 由後端 cron job（node-cron）預先彙整，避免每次查詢 30 日歷史做大量聚合。

### Measurement 4: `heatpump_daily_summary`（每日運轉彙總）【必要】

```
Tags: device_id

Fields:
  total_run_hours  FLOAT   當日總運轉時數
  startup_count    INTEGER 當日開機次數
  avg_cop          FLOAT   當日平均 COP，可缺
  offline_minutes  INTEGER 當日離線分鐘數
```

### Measurement 5: `operation_log`（操作事件日誌）【建議，延後至 MVP】

```
Tags: device_id, event_type（startup | shutdown | fault | recovery）

Fields:
  description STRING, operator STRING, alarm_code STRING
```

### 必要 vs 建議 vs 延後

| Measurement | 狀態 |
|-------------|------|
| `power_meter` | **Demo 必要** |
| `heatpump_status` | **Demo 必要** |
| `energy_daily_summary` | **Demo 必要**（30 日圖表效能依賴）|
| `heatpump_daily_summary` | **Demo 必要**（COP 趨勢效能依賴）|
| `operation_log` | **MVP 建議**（Demo 階段用 SQL Server alerts 替代）|

---

## 六、SQL Server Express 資料表設計

### `clients`（客戶主檔）

```sql
CREATE TABLE clients (
  client_id    INT IDENTITY PRIMARY KEY,
  client_code  NVARCHAR(20) UNIQUE NOT NULL,
  client_name  NVARCHAR(100) NOT NULL,
  contact_name NVARCHAR(50),
  contact_phone NVARCHAR(20),
  contact_email NVARCHAR(100),
  risk_tier    NVARCHAR(10) DEFAULT 'low',  -- low | medium | high
  is_active    BIT DEFAULT 1,
  created_at   DATETIME2 DEFAULT GETDATE(),
  updated_at   DATETIME2 DEFAULT GETDATE()
);
```

### `sites`（場域主檔）

```sql
CREATE TABLE sites (
  site_id         INT IDENTITY PRIMARY KEY,
  site_code       NVARCHAR(20) UNIQUE NOT NULL,
  site_name       NVARCHAR(100) NOT NULL,
  client_id       INT NOT NULL REFERENCES clients(client_id),
  address         NVARCHAR(200),
  influx_site_tag NVARCHAR(50),  -- 對應 InfluxDB site_id tag
  is_active       BIT DEFAULT 1,
  created_at      DATETIME2 DEFAULT GETDATE()
);
```

### `devices`（設備主檔）

```sql
CREATE TABLE devices (
  device_id           INT IDENTITY PRIMARY KEY,
  device_code         NVARCHAR(20) UNIQUE NOT NULL,
  device_name         NVARCHAR(100),
  model               NVARCHAR(50),
  install_date        DATE,
  client_id           INT NOT NULL REFERENCES clients(client_id),
  site_id             INT NOT NULL REFERENCES sites(site_id),
  location_desc       NVARCHAR(100),
  current_status      NVARCHAR(20) DEFAULT 'normal',
                      -- normal | alert | offline | maintenance
  data_source_type    NVARCHAR(10) NOT NULL DEFAULT 'mock',  -- real | mock
  influx_device_tag   NVARCHAR(50),    -- 對應 InfluxDB device_id tag
  mock_data_file      NVARCHAR(200),   -- mock JSON 相對路徑
  risk_score          DECIMAL(5,2) DEFAULT 0,
  risk_score_updated_at DATETIME2,
  last_heartbeat_at   DATETIME2,
  is_active           BIT DEFAULT 1,
  supports_cop        BIT DEFAULT 1,
  supports_pressure   BIT DEFAULT 1,
  created_at          DATETIME2 DEFAULT GETDATE(),
  updated_at          DATETIME2 DEFAULT GETDATE()
);
```

### `meters`（電錶主檔）

```sql
CREATE TABLE meters (
  meter_id         INT IDENTITY PRIMARY KEY,
  meter_code       NVARCHAR(20) UNIQUE NOT NULL,
  meter_name       NVARCHAR(100),
  meter_type       NVARCHAR(20) NOT NULL,  -- device_meter | site_meter
  site_id          INT REFERENCES sites(site_id),
  influx_meter_tag NVARCHAR(50),
  data_source_type NVARCHAR(10) DEFAULT 'real',
  is_active        BIT DEFAULT 1,
  created_at       DATETIME2 DEFAULT GETDATE()
);
```

### `device_meter_mappings`（設備電錶 Mapping）

```sql
CREATE TABLE device_meter_mappings (
  mapping_id  INT IDENTITY PRIMARY KEY,
  device_id   INT NOT NULL REFERENCES devices(device_id),
  meter_id    INT NOT NULL REFERENCES meters(meter_id),
  is_primary  BIT DEFAULT 1,
  share_ratio DECIMAL(5,4) DEFAULT 1.0,
              -- 多台熱泵共用一顆電錶時的用電比例分攤
  valid_from  DATE,
  valid_to    DATE,  -- null 表示仍有效
  created_at  DATETIME2 DEFAULT GETDATE(),
  UNIQUE (device_id, meter_id, valid_from)
);
```

### `alerts`（告警資料）

```sql
CREATE TABLE alerts (
  alert_id        INT IDENTITY PRIMARY KEY,
  device_id       INT NOT NULL REFERENCES devices(device_id),
  alert_type      NVARCHAR(50) NOT NULL,
                  -- offline | high_power | cop_anomaly | temp_anomaly | custom
  severity        NVARCHAR(10) NOT NULL,   -- high | medium | low
  occurred_at     DATETIME2 NOT NULL,
  status          NVARCHAR(20) DEFAULT 'open',
                  -- open | in_progress | resolved
  assigned_to     INT REFERENCES technicians(technician_id),
  assigned_at     DATETIME2,
  resolved_at     DATETIME2,
  description     NVARCHAR(500),
  resolution_note NVARCHAR(500),
  source          NVARCHAR(20) DEFAULT 'manual',  -- manual | auto（預留 MVP）
  created_at      DATETIME2 DEFAULT GETDATE()
);
CREATE INDEX IX_alerts_device_status ON alerts(device_id, status);
CREATE INDEX IX_alerts_occurred_at ON alerts(occurred_at DESC);
```

### `work_orders`（維修工單）

```sql
CREATE TABLE work_orders (
  work_order_id INT IDENTITY PRIMARY KEY,
  wo_code       NVARCHAR(20) UNIQUE NOT NULL,
  device_id     INT NOT NULL REFERENCES devices(device_id),
  alert_id      INT REFERENCES alerts(alert_id),
  assigned_to   INT REFERENCES technicians(technician_id),
  status        NVARCHAR(20) DEFAULT 'open',   -- open | in_progress | completed
  priority      NVARCHAR(10) DEFAULT 'normal', -- urgent | high | normal | low
  issue_desc    NVARCHAR(1000),
  resolution_desc NVARCHAR(1000),
  dispatched_at DATETIME2,
  completed_at  DATETIME2,
  created_at    DATETIME2 DEFAULT GETDATE(),
  updated_at    DATETIME2 DEFAULT GETDATE()
);
```

### `technicians`（維運人員）

```sql
CREATE TABLE technicians (
  technician_id INT IDENTITY PRIMARY KEY,
  tech_code     NVARCHAR(20) UNIQUE NOT NULL,
  full_name     NVARCHAR(50) NOT NULL,
  email         NVARCHAR(100),
  phone         NVARCHAR(20),
  status        NVARCHAR(20) DEFAULT 'active',  -- active | inactive | on_leave
  created_at    DATETIME2 DEFAULT GETDATE()
);
```

### `users`（登入帳號）

```sql
CREATE TABLE users (
  user_id        INT IDENTITY PRIMARY KEY,
  username       NVARCHAR(50) UNIQUE NOT NULL,
  password_hash  NVARCHAR(255) NOT NULL,  -- bcrypt，cost factor ≥ 12
  display_name   NVARCHAR(100),
  email          NVARCHAR(100),
  role           NVARCHAR(20) DEFAULT 'engineer',
                 -- engineer | manager | owner | admin（v1 不啟用）
  technician_id  INT REFERENCES technicians(technician_id),
  is_active      BIT DEFAULT 1,
  last_login_at  DATETIME2,
  created_at     DATETIME2 DEFAULT GETDATE()
);
```

### `system_settings`（系統設定）

```sql
CREATE TABLE system_settings (
  setting_key   NVARCHAR(100) PRIMARY KEY,
  setting_value NVARCHAR(1000),
  description   NVARCHAR(200),
  updated_at    DATETIME2 DEFAULT GETDATE()
);
INSERT INTO system_settings VALUES
  ('polling_interval_sec', '30', '前端輪詢間隔（秒）'),
  ('alert_page_size', '50', '告警列表每頁筆數'),
  ('risk_score_refresh_min', '5', '風險分數刷新間隔（分鐘）'),
  ('default_query_days', '30', '預設查詢區間（天）');
```

### `risk_score_weights`（風險分數權重）

```sql
CREATE TABLE risk_score_weights (
  rule_id     INT IDENTITY PRIMARY KEY,
  rule_name   NVARCHAR(100) NOT NULL,
  description NVARCHAR(200),
  weight      DECIMAL(5,2) NOT NULL,  -- 各項加總應 = 100
  enabled     BIT DEFAULT 1,
  updated_at  DATETIME2 DEFAULT GETDATE()
);
INSERT INTO risk_score_weights (rule_name, description, weight) VALUES
  ('alert_severity',     '告警嚴重性', 30.00),
  ('recent_anomaly_7d',  '近 7 日異常次數', 20.00),
  ('offline_hours',      '今日離線時數', 20.00),
  ('open_work_orders',   '未完成工單數', 15.00),
  ('energy_anomaly',     '能耗異常程度', 10.00),
  ('overdue_maintenance','距上次維修天數', 5.00);
```

---

## 七、設備與電錶 Mapping 設計

### 場景一：一台熱泵對應一顆設備電錶
```
devices: DEV-001
meters:  MTR-001 (device_meter)
mapping: device_id=DEV-001, meter_id=MTR-001, share_ratio=1.0
```

### 場景二：多台熱泵共用一顆設備電錶
```
devices: DEV-002, DEV-003, DEV-004
meters:  MTR-005 (device_meter)
mapping:
  device_id=DEV-002, meter_id=MTR-005, share_ratio=0.3333
  device_id=DEV-003, meter_id=MTR-005, share_ratio=0.3333
  device_id=DEV-004, meter_id=MTR-005, share_ratio=0.3334
```

### 場景三：場域總電錶
```
meters: MTR-100 (site_meter, site_id=SITE-001)
# 場域總電錶直接透過 site_id 查詢，不對應個別設備
```

**查詢用電時**：後端透過 `device_meter_mappings` 找出 `influx_meter_tag`，以 InfluxQL 查詢後乘以 `share_ratio`，得出該設備的用電量。

---

## 八、API Endpoint 規劃

### 8.1 Auth

| Method | Path | 說明 |
|--------|------|------|
| POST | `/api/auth/login` | 登入（設 httpOnly cookie）|
| POST | `/api/auth/logout` | 清除 cookie |
| GET | `/api/auth/me` | 取得目前使用者資訊 |

**POST /api/auth/login**
```json
// Request: { "username": "engineer01", "password": "plaintext" }
// Response 200:
{ "data": { "userId": 1, "username": "engineer01", "displayName": "張工程師", "role": "engineer" } }
// Response 401: { "error": "INVALID_CREDENTIALS", "message": "帳號或密碼錯誤", "statusCode": 401 }
```

### 8.2 Devices

| Method | Path | 說明 |
|--------|------|------|
| GET | `/api/devices` | 設備列表（篩選、搜尋、分頁）|
| GET | `/api/devices/:deviceId` | 設備詳情 |
| GET | `/api/devices/:deviceId/power` | 用電紀錄（30 日）|
| GET | `/api/devices/:deviceId/operation` | 運轉紀錄（30 日）|
| GET | `/api/devices/:deviceId/alerts` | 設備告警歷史 |
| GET | `/api/devices/:deviceId/work-orders` | 維修工單 |

**GET /api/devices** Query params: `status`, `search`, `page`, `limit`

```json
// Response 200:
{
  "data": [{
    "deviceId": "DEV-001", "deviceCode": "DEV-001", "deviceName": "1F 熱泵機組",
    "model": "HP-5000", "clientName": "台北某某公司", "siteName": "台北廠",
    "locationDesc": "1 樓機房", "status": "normal", "riskScore": 15.5,
    "lastHeartbeatAt": "2026-05-17T10:30:00Z", "dataSourceType": "real"
  }],
  "meta": { "total": 80, "page": 1, "limit": 80, "updatedAt": "ISO8601" }
}
```

**GET /api/devices/:deviceId/power** Query params: `from`, `to`（預設 30 日）

```json
{
  "data": {
    "deviceId": "DEV-001",
    "dailySummary": [{ "date": "2026-04-17", "kwhTotal": 45.2, "anomalyFlag": false }],
    "realtimePower": { "powerKw": 5.2, "energyKwh": 1234.5, "powerFactor": 0.95 }
  }
}
// realtimePower: null 表示離線或無電錶資料
```

**GET /api/devices/:deviceId/operation** Query params: `from`, `to`

```json
{
  "data": {
    "deviceId": "DEV-001",
    "dailySummary": [{ "date": "2026-04-17", "runHours": 18.5, "startupCount": 3, "avgCop": 3.8 }],
    "supportsCoP": true, "supportsPressure": false
  }
}
// avgCop: null → 前端顯示「不適用」
```

### 8.3 Risk

| Method | Path | 說明 |
|--------|------|------|
| GET | `/api/risk/top-devices` | Top 10 高風險設備 |
| GET | `/api/risk/top-clients` | Top 5 高風險客戶 |
| GET | `/api/risk/rules` | 取得風險分數權重設定 |
| PUT | `/api/risk/rules` | 更新風險分數權重（管理員）|

**GET /api/risk/top-devices**
```json
{
  "data": [{
    "rank": 1, "deviceId": "DEV-055", "deviceCode": "DEV-055",
    "clientName": "高雄某客戶", "riskScore": 87.3,
    "riskReasons": ["近 7 日連續異常 5 次", "未完成工單 2 張", "今日離線 4 小時"],
    "suggestedAction": "緊急",
    "rankChange": "up", "rankDelta": 2
  }]
}
```

### 8.4 Alerts

| Method | Path | 說明 |
|--------|------|------|
| GET | `/api/alerts` | 告警列表（篩選、分頁）|
| PUT | `/api/alerts/:alertId/assign` | 指派負責人 |
| PUT | `/api/alerts/:alertId/resolve` | 更新為已解除 |

**GET /api/alerts** Query params: `status`, `alert_type`, `page`, `limit`

```json
{
  "data": [{
    "alertId": 101, "deviceId": "DEV-003", "deviceCode": "DEV-003",
    "clientName": "台中某客戶", "alertType": "offline", "alertTypeLabel": "設備離線",
    "severity": "high", "occurredAt": "2026-05-17T08:00:00Z",
    "status": "open", "statusLabel": "未處理",
    "assignedTo": null, "assignedToName": null, "assignedAt": null
  }],
  "meta": { "total": 23, "page": 1, "limit": 50 }
}
```

**PUT /api/alerts/:alertId/assign**
```json
// Request: { "technicianId": 3 }
// Response 200: { "data": { "alertId": 101, "status": "in_progress", "assignedToName": "李技師", "assignedAt": "ISO8601" } }
```

**PUT /api/alerts/:alertId/resolve**
```json
// Request: { "resolutionNote": "更換壓縮機後恢復正常" }
// Response 200: { "data": { "alertId": 101, "status": "resolved", "resolvedAt": "ISO8601" } }
```

### 8.5 Reports

| Method | Path | 說明 |
|--------|------|------|
| GET | `/api/reports/monthly?month=YYYY-MM` | 月報資料（前端產生 PDF）|

```json
{
  "data": {
    "month": "2026-04",
    "deviceHealthSummary": { "avgScore": 72.5, "distribution": { "90-100": 15, "70-89": 40, "50-69": 20, "0-49": 5 } },
    "anomalyStats": {
      "totalCount": 48,
      "byType": [{ "type": "offline", "label": "設備離線", "count": 20 }],
      "topDevices": [{ "deviceCode": "DEV-055", "clientName": "高雄客戶", "anomalyCount": 8 }]
    },
    "alertStats": { "totalAlerts": 48, "resolvedRate": 0.875, "avgResolveHours": 4.2, "overdueCount": 6 }
  }
}
```

### 8.6 Executive

| Method | Path | 說明 |
|--------|------|------|
| GET | `/api/executive/summary` | 老闆決策頁核心 KPI |
| GET | `/api/executive/capacity?addDevices=N` | 擴張承載能力試算 |

**GET /api/executive/capacity?addDevices=10**
```json
{
  "data": {
    "currentDevices": 80, "currentTechnicians": 5, "avgDevicesPerTech": 16,
    "currentUtilization": 0.72, "projectedUtilization": 0.85,
    "maxSafeAddDevices": 15,
    "recommendation": "目前產能可安全承接最多 15 台新設備"
  }
}
```

### 8.7 System

| Method | Path | 說明 |
|--------|------|------|
| GET | `/api/system/last-updated` | 最後資料更新時間 |
| GET | `/api/system/health` | 系統健康狀態（InfluxDB + SQL Server 連線）|

---

## 九、登入與安全性規劃

### 認證流程

```
POST /api/auth/login
  → 驗證 username/password（bcrypt 比對，cost factor ≥ 12）
  → 產生 JWT（payload: userId, role, iat, exp=8h）
  → 設定 httpOnly、SameSite=Lax cookie（名稱: hp_token）
  → 前端不直接存取 token 值

後續請求
  → @fastify/jwt 從 cookie 讀取並驗證
  → 驗證失敗返回 401
```

### 安全性措施

| 類別 | 措施 |
|------|------|
| 密碼儲存 | bcrypt（cost factor ≥ 12）|
| SQL Injection | Drizzle ORM 參數化查詢，禁止字串拼接 |
| XSS | React 預設 escape；httpOnly cookie 防 token 竊取 |
| CSRF | SameSite=Lax cookie |
| CORS | 僅允許前端 EC2 的 IP/域名（`FRONTEND_URL` 環境變數）|
| 環境變數 | 敏感設定存 `.env`，不進 Git（`.env.example` 提供範本）|
| 防火牆 | EC2 Security Group：InfluxDB/SQL Server Port 僅開放後端 EC2 IP |
| Rate Limiting | `@fastify/rate-limit`：登入 API 10 次/分鐘 |

---

## 十、Mock / Real 資料來源整合策略

### DataSourceRouter

```typescript
interface DeviceDataSource {
  getPowerDailySummary(deviceId: string, from: Date, to: Date): Promise<PowerDailySummary[]>;
  getOperationDailySummary(deviceId: string, from: Date, to: Date): Promise<OperationDailySummary[]>;
  getRealtimeStatus(deviceId: string): Promise<DeviceRealtimeStatus>;
}

// DataSourceRouter 根據 devices.data_source_type 決定使用 InfluxDataSource 或 MockDataSource
// API response 格式完全一致，前端無需知道資料來源
```

### 轉換為 Real 設備的流程

1. 在 `devices` 表更新 `data_source_type = 'real'`，填入 `influx_device_tag`
2. 重啟後端即生效，**不需修改任何前端程式碼**

### Mock 資料結構

```jsonc
// mock-data/devices/device-008.json
{
  "deviceCode": "DEV-008",
  "realtimeStatus": { "status": "normal", "powerKw": 4.8, "runHours": 6.5 },
  "powerDailySummary": [{ "date": "2026-04-17", "kwhTotal": 38.2, "anomalyFlag": false }],
  "operationDailySummary": [{ "date": "2026-04-17", "runHours": 14.5, "startupCount": 2, "avgCop": 3.6 }]
}
```

---

## 十一、風險分數計算設計

### v1 簡化公式（Demo）

```
風險分數 = CLAMP(總原始分, 0, 100)

各項計算（總計 100 分）：
1. 告警嚴重性（30 分上限）
   = MIN(高級告警數 × 10 + 中級告警數 × 5 + 低級告警數 × 2, 30)

2. 近 7 日異常次數（20 分上限）
   = MIN(近7日告警數 × 2, 20)

3. 今日離線時數（20 分上限）
   = MIN((offline_minutes / 60) × 5, 20)

4. 未完成工單數（15 分上限）
   = MIN(open_wo_count × 7.5, 15)

5. 能耗異常程度（10 分）
   = IF(avg_kwh_7d > historical_avg × 1.2) THEN 10 ELSE 0

6. 距上次維修天數（5 分）
   = IF(days_since_last_wo > 180) THEN 5 ELSE 0
```

**實作方式**：後端 node-cron 每 5 分鐘執行計算，結果寫入 `devices.risk_score`。計算前儲存舊排名，比較差值產生 `rankChange`。

**調整機制**：權重存於 `risk_score_weights` 表，`PUT /api/risk/rules` 更新後下次計算週期生效，**不需改程式碼**。

### MVP 擴充路線

- 引入 COP 異常評分（若感測器支援）
- 引入能耗預測偏差（統計基準）
- 業務方提供公式後，更新 `risk_score_weights` 表即可

---

## 十二、告警中心 v1 與 MVP 演進設計

### v1（Demo）：顯示型告警中心

```
SQL Server alerts 表 → /api/alerts → 告警中心前端
功能：顯示、篩選、指派、更新為已解除
```

### MVP：判斷型告警中心（預留擴充點）

```typescript
// AlertEvaluationService（v1 為空實作，介面已定義）
interface AlertRule {
  ruleId: string;
  condition: (reading: DeviceReading) => boolean;
  severity: 'high' | 'medium' | 'low';
  alertType: string;
}

class AlertEvaluationService {
  async evaluate(deviceId: string): Promise<Alert[]> {
    // v1: 返回空陣列
    // MVP: 查詢 InfluxDB 最新讀值，套用 rules，自動寫入 alerts 表
    return [];
  }
}
```

MVP 自動告警場景：設備離線超 N 分鐘、功率超歷史均值 X%、COP 低於門檻、溫度異常、24 小時無心跳。

---

## 十三、Docker Compose 部署規劃

### Demo 部署（docker-compose.yml）

```yaml
version: '3.8'
services:
  frontend:
    build: ./frontend
    expose: ["3000"]
    depends_on: [backend-api]

  backend-api:
    build: ./backend
    expose: ["4000"]
    env_file: ./docker/.env
    volumes:
      - ./mock-data:/app/mock-data:ro
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports: ["80:80", "443:443"]
    volumes:
      - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./docker/nginx/certs:/etc/nginx/certs:ro
    depends_on: [frontend, backend-api]
    restart: unless-stopped
```

### Nginx 設定重點

```nginx
location /api/ {
  proxy_pass http://backend-api:4000/api/;
  proxy_read_timeout 60s;
}
location / {
  proxy_pass http://frontend:3000/;
}
```

### 跨 EC2 連線設定

```
EC2 主機 A（Dashboard）→ EC2 主機 B（資料庫）
  InfluxDB: INFLUX_HOST = EC2-B 私有 IP, PORT = 8086
  SQL Server: SQLSERVER_HOST = EC2-B 私有 IP, PORT = 1433

EC2 B Security Group Inbound:
  TCP 8086 from EC2-A 安全群組 ID
  TCP 1433 from EC2-A 安全群組 ID
EC2 A Security Group Inbound:
  TCP 443, 80 from 0.0.0.0/0
```

---

## 十四、Demo 階段開發順序

*目標：7 個工作日完成 Demo*

| 天 | 里程碑 | 主要任務 |
|----|--------|---------|
| Day 1 | 骨架完成 | 前後端專案初始化、Dockerfile、Nginx、SQL Server DDL 執行、73 筆 Mock JSON 建立 |
| Day 2 | 設備總覽 | GET /api/devices + DataSourceRouter（Mock）、前端設備列表頁（列表、篩選、搜尋）|
| Day 3 | 告警中心 | GET /api/alerts + assign + resolve、前端告警中心頁、狀態更新互動 |
| Day 4 | 單機履歷 | power / operation / alerts / work-orders API（Mock）、前端四頁籤 + ECharts 圖表 |
| Day 5 | 風險排序 + 月報 | 風險分數計算（SQL Server only）、風險排序頁、月報頁 + jsPDF 匯出 |
| Day 6 | 老闆決策頁 + 真實資料 | 老闆決策頁、接通 7 台設備 InfluxDB 查詢 |
| Day 7 | 整合測試 + 部署 | Docker Compose 上 EC2 A、端對端測試、效能驗證、Bug 修復 |

---

## 十五、Demo 隔天進入 MVP 的升級路線

| 優先序 | MVP 升級項目 | 說明 |
|-------|------------|------|
| MVP-1 | 接通更多真實設備 | 更新 `data_source_type = 'real'`，填入 InfluxDB tag，重啟後端 |
| MVP-2 | 告警自動產生 | 實作 `AlertEvaluationService`，接 InfluxDB 讀值判斷告警 |
| MVP-3 | Redis 快取 | 替換 node-cache，docker-compose 新增 redis service |
| MVP-4 | Daily summary cron job | 後端每日 00:05 預先彙整 InfluxDB 資料 |
| MVP-5 | 角色權限 | 啟用 `users.role`，前端根據角色顯示不同功能 |
| MVP-6 | HTTPS 自動憑證 | 加入 certbot/Let's Encrypt 自動續期 |

**API 合約承諾**：所有 Demo API response 格式在 MVP 保持向後相容，前端無需修改。

---

## 十六、測試策略

### 前端測試（Vitest + React Testing Library）

| 層級 | 範圍 |
|------|------|
| Unit | 元件渲染、篩選邏輯、缺值處理（`null → --`）、PDF 匯出函數 |
| Integration | 頁面流程（設備列表→單機履歷、告警指派流程）—— 使用 MSW |

**關鍵測試案例**：
- 離線設備顯示灰色 `--`
- 風險分數降序排列、排名變動標示
- 未指派告警置頂、高嚴重性告警高亮
- COP 不支援時顯示「不適用」
- jsPDF 觸發下載

### 後端測試（Jest）

| 層級 | 範圍 |
|------|------|
| Unit | 風險分數公式、DataSourceRouter 路由邏輯、InfluxQL 查詢產生器 |
| Integration | 各 API endpoint（Fastify inject()）、SQL Server 查詢（test DB）|

**關鍵測試案例**：
- 相同 device，切換 `data_source_type`，response 格式一致
- 告警指派後 status 正確更新為 `in_progress`
- 風險分數 CLAMP 在 0–100 之間

### 效能測試

| 場景 | 目標 | 工具 |
|------|------|------|
| 80 台設備全告警頁面載入 | ≤ 3 秒 | k6 |
| 30 日趨勢 InfluxDB 查詢 | ≤ 500 ms | autocannon |
| 月報資料 API | ≤ 5 秒 | autocannon |
| 30 秒輪詢（GET /api/devices）| ≤ 200 ms p95 | k6 |

---

## 十七、技術風險與緩解措施

| 風險 | 可能性 | 影響 | 緩解措施 |
|------|--------|------|---------|
| SQL Server Express 無排程功能 | 高 | 中 | 用 node-cron 替代 SQL Agent |
| InfluxDB 1.8 僅支援 InfluxQL | 高 | 低 | 已選用 `influx` npm 套件（1.x 相容）|
| Mock JSON 73 筆啟動載入時間 | 中 | 低 | 啟動一次載入 + 記憶體快取；格式精簡 |
| 跨 EC2 連線延遲 | 中 | 高 | AWS VPC 私有 IP（低延遲）+ 後端快取 |
| jsPDF 月報 PDF 品質 | 中 | 中 | Demo 接受瀏覽器列印品質；MVP 可改 Puppeteer |
| 30 秒輪詢 SQL Server 過載 | 中 | 中 | 後端快取 TTL 25 秒，大多請求走快取 |
| TypeScript strict + InfluxDB 1.x 型別 | 中 | 低 | 自行定義型別，不依賴官方 2.x client |

---

## 十八、不納入本階段的項目

| 項目 | 理由 | 預計版本 |
|------|------|---------|
| 角色權限控管 | v1 規格明確標示不啟用 | MVP |
| 告警自動判斷實作 | Demo 僅需顯示型告警 | MVP |
| 行動裝置 RWD | 規格限定桌面 1280px+ | v2 |
| Email / LINE 告警通知 | Demo 範圍外 | v2 |
| Redis 快取 | node-cache 足夠 Demo | MVP |
| Let's Encrypt 自動憑證 | Demo 可用自簽憑證 | MVP |
| Puppeteer 後端 PDF | 前端 PDF 已符合規格 | MVP（可選）|
| WebSocket 即時推送 | 30 秒輪詢已符合規格 | v2 |
| `operation_log` InfluxDB measurement | 異常紀錄先用 SQL Server alerts | MVP |
| 資料收集機制（IoT Gateway）| 規格明確排除 | 獨立專案 |

