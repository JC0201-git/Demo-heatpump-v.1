# 資料模型：熱泵／熱水系統監控儀表板

**Branch**: `001-heatpump-dashboard-6pages` | **Date**: 2026-05-17  
**Phase**: 1 — 設計與合約  

---

## 一、核心業務實體

```
┌──────────┐   1    ┌──────────┐   1    ┌──────────┐
│  clients │ ──── * │  sites   │ ──── * │  devices │
└──────────┘        └──────────┘        └──────────┘
                         │                    │ *
                         │                 ┌──┴──────────────────┐
                         │ *               │  device_meter       │
                    ┌────┴───┐             │    _mappings        │
                    │ meters │             └──────┬──────────────┘
                    └────────┘                    │ *
                                           ┌──────┴──┐
                                           │ meters  │
                                           └─────────┘

┌──────────┐   *    ┌──────────┐
│  devices │ ──── * │  alerts  │ * ── 1 ┌────────────┐
└──────────┘        └──────────┘        │ technicians│
     │                                  └────────────┘
     │ *                                       │ 1
┌────┴──────┐                                  │ *
│work_orders│──────────────────────────────────┘
└───────────┘

┌──────────┐
│  users   │ 1 ─── 0/1 ┌────────────┐
└──────────┘            │ technicians│
                        └────────────┘
```

---

## 二、InfluxDB 1.8 Measurement 資料模型

### 2.1 `power_meter`（用電計量）

| 欄位 | 類型 | 說明 |
|------|------|------|
| `meter_id` | Tag（String）| 電錶識別碼，對應 MySQL `meters.meter_code` |
| `site_id` | Tag（String）| 場域識別碼 |
| `customer_id` | Tag（String）| 客戶識別碼 |
| `meter_type` | Tag（String）| `device_meter` \| `site_meter` |
| `voltage_a` | Field（Float）| A 相電壓（V）|
| `voltage_b` | Field（Float）| B 相電壓（V）|
| `voltage_c` | Field（Float）| C 相電壓（V）|
| `current_a` | Field（Float）| A 相電流（A）|
| `current_b` | Field（Float）| B 相電流（A）|
| `current_c` | Field（Float）| C 相電流（A）|
| `power_kw` | Field（Float）| 即時功率（kW）|
| `energy_kwh` | Field（Float）| 累積用電量（kWh）|
| `power_factor` | Field（Float）| 功率因數（0.0 ～ 1.0）|
| `frequency` | Field（Float）| 頻率（Hz）|

**寫入頻率**：每分鐘 1 筆（設備端定期上報）  
**保留策略**：建議設定 90 天自動過期（視 InfluxDB retention policy 設定）

### 2.2 `heatpump_status`（熱泵設備狀態）

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `device_id` | Tag（String）| 必填 | 設備識別碼，對應 MySQL `devices.device_code` |
| `site_id` | Tag（String）| 必填 | 場域識別碼 |
| `customer_id` | Tag（String）| 必填 | 客戶識別碼 |
| `model` | Tag（String）| 必填 | 設備型號 |
| `operating_mode` | Field（String）| 必填 | `running` \| `standby` \| `fault` \| `offline` |
| `inlet_temp` | Field（Float）| **可缺** | 進水溫度（°C）|
| `outlet_temp` | Field（Float）| **可缺** | 出水溫度（°C）|
| `pressure` | Field（Float）| **可缺** | 系統壓力（bar）|
| `cop` | Field（Float）| **可缺** | 能效比（COP）|
| `startup_count` | Field（Integer）| 必填 | 當日累計開機次數 |
| `run_hours` | Field（Float）| 必填 | 當日累計運轉時數 |
| `alarm_code` | Field（String）| **可缺** | 告警代碼（空字串 = 正常）|
| `alarm_desc` | Field（String）| **可缺** | 告警描述 |

**缺欄位容錯規則**：
- 不支援 COP 的設備：`cop` 欄位不寫入（不寫 null）
- 後端查詢結果缺 field → 回傳 `null`
- 前端收到 `null` + `supportsCoP: false` → 顯示「不適用」
- 前端收到 `null` + `supportsCoP: true` → 顯示 `--`（資料暫缺）

**寫入頻率**：每分鐘 1 筆

### 2.3 `energy_daily_summary`（每日用電彙總）【必要】

| 欄位 | 類型 | 說明 |
|------|------|------|
| `device_id` | Tag（String）| 設備識別碼 |
| `meter_id` | Tag（String）| 電錶識別碼 |
| `site_id` | Tag（String）| 場域識別碼 |
| `customer_id` | Tag（String）| 客戶識別碼 |
| `kwh_total` | Field（Float）| 當日累計用電量（kWh）|
| `kwh_peak` | Field（Float）| 當日峰值功率（kW）|
| `avg_power_kw` | Field（Float）| 當日平均功率（kW）|
| `anomaly_flag` | Field（Boolean）| 當日是否異常（超過歷史均值 20%）|

**寫入時機**：後端 node-cron 每日 00:05 彙整前一日資料  
**查詢方式**：`SELECT * FROM energy_daily_summary WHERE device_id = 'DEV-001' AND time >= now() - 30d`

### 2.4 `heatpump_daily_summary`（每日運轉彙總）【必要】

| 欄位 | 類型 | 說明 |
|------|------|------|
| `device_id` | Tag（String）| 設備識別碼 |
| `total_run_hours` | Field（Float）| 當日總運轉時數 |
| `startup_count` | Field（Integer）| 當日開機次數 |
| `avg_cop` | Field（Float）| 當日平均 COP（可缺）|
| `offline_minutes` | Field（Integer）| 當日離線分鐘數 |

**寫入時機**：後端 node-cron 每日 00:05 彙整前一日資料

### 2.5 `operation_log`（操作事件日誌）【MVP 建議】

| 欄位 | 類型 | 說明 |
|------|------|------|
| `device_id` | Tag（String）| 設備識別碼 |
| `event_type` | Tag（String）| `startup` \| `shutdown` \| `fault` \| `recovery` \| `maintenance` |
| `description` | Field（String）| 事件描述 |
| `operator` | Field（String）| 操作人員（若有）|
| `alarm_code` | Field（String）| 相關告警代碼（若有）|

**Demo 階段替代方案**：異常事件時間軸使用 MySQL `alerts` 表資料顯示

---

## 三、MySQL 完整 Schema

### 3.1 實體關係說明

- 一個 **客戶（client）** 可有多個 **場域（site）**
- 一個 **場域（site）** 可有多台 **設備（device）**
- 一台 **設備（device）** 可對應多顆 **電錶（meter）**（透過 `device_meter_mappings`）
- 一顆 **電錶（meter）** 可對應多台設備（共用電錶）
- 一台設備可有多筆 **告警（alert）**
- 一台設備有一筆 **風險快照（device_risk_snapshot）**，保存風險分數六維度的 MySQL 快照分數
- 一筆告警可觸發一張 **工單（work_order）**
- 一位 **技師（technician）** 可被指派多筆告警與工單
- 一個 **使用者（user）** 可綁定一位技師

> **資料庫**：MySQL 8.0；字元集 `utf8mb4`，排序規則 `utf8mb4_unicode_ci`

### 3.2 完整 DDL

```sql
-- ============================================================
-- 客戶主檔
-- ============================================================
CREATE TABLE clients (
  client_id     INT AUTO_INCREMENT PRIMARY KEY,
  client_code   VARCHAR(20) NOT NULL UNIQUE,  -- 如 CLI-001
  client_name   VARCHAR(100) NOT NULL,
  contact_name  VARCHAR(50),
  contact_phone VARCHAR(20),
  contact_email VARCHAR(100),
  risk_tier     VARCHAR(10) NOT NULL DEFAULT 'low'
                CHECK (risk_tier IN ('low', 'medium', 'high')),
  is_active     TINYINT(1) NOT NULL DEFAULT 1,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- 場域主檔
-- ============================================================
CREATE TABLE sites (
  site_id         INT AUTO_INCREMENT PRIMARY KEY,
  site_code       VARCHAR(20) NOT NULL UNIQUE,
  site_name       VARCHAR(100) NOT NULL,
  client_id       INT NOT NULL REFERENCES clients(client_id),
  address         VARCHAR(200),
  city            VARCHAR(50),
  influx_site_tag VARCHAR(50),  -- 對應 InfluxDB site_id tag
  is_active       TINYINT(1) NOT NULL DEFAULT 1,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 維運人員（須在 devices 前建立，因 alerts 引用）
-- ============================================================
CREATE TABLE technicians (
  technician_id INT AUTO_INCREMENT PRIMARY KEY,
  tech_code     VARCHAR(20) NOT NULL UNIQUE,
  full_name     VARCHAR(50) NOT NULL,
  email         VARCHAR(100),
  phone         VARCHAR(20),
  status        VARCHAR(20) NOT NULL DEFAULT 'active'
                CHECK (status IN ('active', 'inactive', 'on_leave')),
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 設備主檔（80 台）
-- ============================================================
CREATE TABLE devices (
  device_id            INT AUTO_INCREMENT PRIMARY KEY,
  device_code          VARCHAR(20) NOT NULL UNIQUE,  -- 如 DEV-001
  device_name          VARCHAR(100),
  model                VARCHAR(50),
  install_date         DATE,
  client_id            INT NOT NULL REFERENCES clients(client_id),
  site_id              INT NOT NULL REFERENCES sites(site_id),
  location_desc        VARCHAR(100),
  current_status       VARCHAR(20) NOT NULL DEFAULT 'normal'
                       CHECK (current_status IN ('normal', 'alert', 'offline', 'maintenance')),
  data_source_type     VARCHAR(10) NOT NULL DEFAULT 'mock'
                       CHECK (data_source_type IN ('real', 'mock')),
  influx_device_tag    VARCHAR(50),     -- 對應 InfluxDB device_id tag（real 設備必填）
  mock_data_file       VARCHAR(200),    -- mock 設備 JSON 相對路徑（mock 設備必填）
  risk_score           DECIMAL(5,2) NOT NULL DEFAULT 0,
  risk_score_updated_at DATETIME,
  last_heartbeat_at    DATETIME,
  is_active            TINYINT(1) NOT NULL DEFAULT 1,
  supports_cop         TINYINT(1) NOT NULL DEFAULT 1,
  supports_pressure    TINYINT(1) NOT NULL DEFAULT 1,
  created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE INDEX IX_devices_status ON devices(current_status);
CREATE INDEX IX_devices_risk_score ON devices(risk_score DESC);

-- ============================================================
-- 設備風險分數快照（riskScoreService 的直接資料來源）
-- ============================================================
CREATE TABLE device_risk_snapshots (
  device_id                   INT PRIMARY KEY REFERENCES devices(device_id),
  alert_severity_score        DECIMAL(5,2) NOT NULL DEFAULT 0
                              CHECK (alert_severity_score >= 0 AND alert_severity_score <= 100),
  recent_anomaly_7d_score     DECIMAL(5,2) NOT NULL DEFAULT 0
                              CHECK (recent_anomaly_7d_score >= 0 AND recent_anomaly_7d_score <= 100),
  offline_hours_score         DECIMAL(5,2) NOT NULL DEFAULT 0
                              CHECK (offline_hours_score >= 0 AND offline_hours_score <= 100),
  open_work_orders_score      DECIMAL(5,2) NOT NULL DEFAULT 0
                              CHECK (open_work_orders_score >= 0 AND open_work_orders_score <= 100),
  energy_anomaly_score        DECIMAL(5,2) NOT NULL DEFAULT 0
                              CHECK (energy_anomaly_score >= 0 AND energy_anomaly_score <= 100),
  overdue_maintenance_score   DECIMAL(5,2) NOT NULL DEFAULT 0
                              CHECK (overdue_maintenance_score >= 0 AND overdue_maintenance_score <= 100),
  snapshot_at                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE INDEX IX_device_risk_snapshots_updated ON device_risk_snapshots(snapshot_at DESC);

-- ============================================================
-- 電錶主檔
-- ============================================================
CREATE TABLE meters (
  meter_id         INT AUTO_INCREMENT PRIMARY KEY,
  meter_code       VARCHAR(20) NOT NULL UNIQUE,
  meter_name       VARCHAR(100),
  meter_type       VARCHAR(20) NOT NULL
                   CHECK (meter_type IN ('device_meter', 'site_meter')),
  site_id          INT REFERENCES sites(site_id),
  influx_meter_tag VARCHAR(50),  -- 對應 InfluxDB meter_id tag
  data_source_type VARCHAR(10) NOT NULL DEFAULT 'real'
                   CHECK (data_source_type IN ('real', 'mock')),
  is_active        TINYINT(1) NOT NULL DEFAULT 1,
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 設備電錶 Mapping
-- ============================================================
CREATE TABLE device_meter_mappings (
  mapping_id  INT AUTO_INCREMENT PRIMARY KEY,
  device_id   INT NOT NULL REFERENCES devices(device_id),
  meter_id    INT NOT NULL REFERENCES meters(meter_id),
  is_primary  TINYINT(1) NOT NULL DEFAULT 1,
  share_ratio DECIMAL(5,4) NOT NULL DEFAULT 1.0
              CHECK (share_ratio > 0 AND share_ratio <= 1),
  valid_from  DATE,
  valid_to    DATE,  -- NULL 表示目前有效
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT UQ_device_meter_valid UNIQUE (device_id, meter_id, valid_from)
);
CREATE INDEX IX_dmm_device ON device_meter_mappings(device_id);

-- ============================================================
-- 告警資料
-- ============================================================
CREATE TABLE alerts (
  alert_id        INT AUTO_INCREMENT PRIMARY KEY,
  device_id       INT NOT NULL REFERENCES devices(device_id),
  alert_type      VARCHAR(50) NOT NULL,
  severity        VARCHAR(10) NOT NULL
                  CHECK (severity IN ('high', 'medium', 'low')),
  occurred_at     DATETIME NOT NULL,
  status          VARCHAR(20) NOT NULL DEFAULT 'open'
                  CHECK (status IN ('open', 'in_progress', 'resolved')),
  assigned_to     INT REFERENCES technicians(technician_id),
  assigned_at     DATETIME,
  resolved_at     DATETIME,
  description     VARCHAR(500),
  resolution_note VARCHAR(500),
  source          VARCHAR(20) NOT NULL DEFAULT 'manual'
                  CHECK (source IN ('manual', 'auto')),  -- 預留 auto 供 MVP
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IX_alerts_status ON alerts(status, occurred_at DESC);
CREATE INDEX IX_alerts_device ON alerts(device_id, status);
CREATE INDEX IX_alerts_occurred ON alerts(occurred_at DESC);

-- ============================================================
-- 維修工單
-- ============================================================
CREATE TABLE work_orders (
  work_order_id   INT AUTO_INCREMENT PRIMARY KEY,
  wo_code         VARCHAR(20) NOT NULL UNIQUE,  -- 如 WO-20260517-001
  device_id       INT NOT NULL REFERENCES devices(device_id),
  alert_id        INT REFERENCES alerts(alert_id),
  assigned_to     INT REFERENCES technicians(technician_id),
  status          VARCHAR(20) NOT NULL DEFAULT 'open'
                  CHECK (status IN ('open', 'in_progress', 'completed', 'cancelled')),
  priority        VARCHAR(10) NOT NULL DEFAULT 'normal'
                  CHECK (priority IN ('urgent', 'high', 'normal', 'low')),
  issue_desc      TEXT,
  resolution_desc TEXT,
  dispatched_at   DATETIME,
  completed_at    DATETIME,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE INDEX IX_wo_device_status ON work_orders(device_id, status);
CREATE INDEX IX_wo_assignee ON work_orders(assigned_to, status);

-- ============================================================
-- 登入帳號
-- ============================================================
CREATE TABLE users (
  user_id        INT AUTO_INCREMENT PRIMARY KEY,
  username       VARCHAR(50) NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,  -- bcrypt，cost factor ≥ 12
  display_name   VARCHAR(100),
  email          VARCHAR(100),
  role           VARCHAR(20) NOT NULL DEFAULT 'engineer'
                 CHECK (role IN ('engineer', 'manager', 'owner', 'admin')),
  technician_id  INT REFERENCES technicians(technician_id),
  is_active      TINYINT(1) NOT NULL DEFAULT 1,
  last_login_at  DATETIME,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 系統設定
-- ============================================================
CREATE TABLE system_settings (
  setting_key   VARCHAR(100) PRIMARY KEY,
  setting_value VARCHAR(1000),
  description   VARCHAR(200),
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- 風險分數權重設定
-- ============================================================
CREATE TABLE risk_score_weights (
  rule_id     INT AUTO_INCREMENT PRIMARY KEY,
  rule_name   VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(200),
  weight      DECIMAL(5,2) NOT NULL CHECK (weight >= 0 AND weight <= 100),
  enabled     TINYINT(1) NOT NULL DEFAULT 1,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 3.3 初始資料

```sql
-- 系統設定初始值
INSERT INTO system_settings (setting_key, setting_value, description) VALUES
  ('polling_interval_sec', '30', '前端輪詢間隔（秒）'),
  ('alert_page_size', '50', '告警列表每頁筆數'),
  ('risk_score_refresh_min', '5', '風險分數刷新間隔（分鐘）'),
  ('default_query_days', '30', '預設查詢區間（天）'),
  ('ALERT_OVERDUE_HOURS', '24', '未處理告警逾時門檻（小時），供月報逾時未處理統計使用');

-- 風險分數權重初始值（加總 = 100）
INSERT INTO risk_score_weights (rule_name, description, weight) VALUES
  ('alert_severity',      '告警嚴重性（高: 10分, 中: 5分, 低: 2分）', 30.00),
  ('recent_anomaly_7d',   '近 7 日異常次數（每次 2 分，上限 20 分）', 20.00),
  ('offline_hours',       '今日離線時數（每小時 5 分，上限 20 分）', 20.00),
  ('open_work_orders',    '未完成工單數（每張 7.5 分，上限 15 分）', 15.00),
  ('energy_anomaly',      '能耗超過歷史均值 20% 則計 10 分', 10.00),
  ('overdue_maintenance', '距上次完工超過 180 天則計 5 分', 5.00);
```

---

## 四、TypeScript 型別定義（共用 DTO）

```typescript
// types/device.ts
export type DeviceStatus = 'normal' | 'alert' | 'offline' | 'maintenance';
export type DataSourceType = 'real' | 'mock';

export interface DeviceListItem {
  deviceId: string;       // device_code
  deviceCode: string;
  deviceName: string | null;
  model: string | null;
  clientName: string;
  siteName: string;
  locationDesc: string | null;
  status: DeviceStatus;
  riskScore: number;
  lastHeartbeatAt: string | null;  // ISO8601
  dataSourceType: DataSourceType;
}

export interface DeviceDetail extends DeviceListItem {
  installDate: string | null;  // ISO8601 date
  clientId: string;
  siteId: string;
  supportsCoP: boolean;
  supportsPressure: boolean;
}

export interface PowerDailySummary {
  date: string;          // YYYY-MM-DD
  kwhTotal: number | null;
  kwhPeak: number | null;
  avgPowerKw: number | null;
  anomalyFlag: boolean;
}

export interface OperationDailySummary {
  date: string;
  runHours: number | null;
  startupCount: number | null;
  avgCop: number | null;  // null = 設備不支援或當日無資料
}

// types/alert.ts
export type AlertStatus = 'open' | 'in_progress' | 'resolved';
export type AlertSeverity = 'high' | 'medium' | 'low';

export interface AlertItem {
  alertId: number;
  deviceId: string;
  deviceCode: string;
  clientName: string;
  alertType: string;
  alertTypeLabel: string;  // 繁體中文顯示名稱
  severity: AlertSeverity;
  occurredAt: string;    // ISO8601
  status: AlertStatus;
  statusLabel: string;   // 繁體中文：未處理｜處理中｜已解除
  assignedTo: number | null;
  assignedToName: string | null;
  assignedAt: string | null;
  resolvedAt: string | null;
}

// types/risk.ts
export type RankChange = 'up' | 'down' | 'same';

export interface RiskDeviceItem {
  rank: number;
  deviceId: string;
  deviceCode: string;
  clientName: string;
  riskScore: number;
  riskReasons: string[];  // 繁體中文說明
  suggestedAction: '緊急' | '本週' | '本月';
  rankChange: RankChange;
  rankDelta: number;
}

export interface DeviceRiskSnapshot {
  deviceId: number;
  alertSeverityScore: number;
  recentAnomaly7dScore: number;
  offlineHoursScore: number;
  openWorkOrdersScore: number;
  energyAnomalyScore: number;
  overdueMaintenanceScore: number;
  snapshotAt: string; // ISO8601
}

// types/report.ts
export interface MonthlyReport {
  month: string;          // YYYY-MM
  generatedAt: string;    // ISO8601
  alertStats: {
    totalAlerts: number;
    resolvedCount: number;
    resolvedRate: number;
    avgResolveHours: number | null;
    overdueCount: number;
    overdueThresholdHours: number; // system_settings.ALERT_OVERDUE_HOURS，預設 24
  };
}
```

---

## 五、狀態流轉圖

### 告警狀態流轉

```
open（未處理）
  └─[指派負責人]→ in_progress（處理中）
                       └─[更新為已解除]→ resolved（已解除）
```

### 工單狀態流轉

```
open（待派工）
  └─[派工]→ in_progress（處理中）
              └─[完工]→ completed（已完成）
              └─[取消]→ cancelled（已取消）
```

### 設備狀態更新觸發（v1 為手動更新；MVP 為自動）

```
heatpump_status.operating_mode = 'fault'  → devices.current_status = 'alert'
heatpump_status.operating_mode = 'offline' → devices.current_status = 'offline'
work_order.status = 'open'                → devices.current_status = 'maintenance'
全部工單 completed, 無 open alert         → devices.current_status = 'normal'
```

---

## 六、Mock 資料 JSON 格式

```typescript
// mock-data/devices/device-008.json
{
  "deviceCode": "DEV-008",
  "deviceName": "2F 熱泵機組",
  "model": "HP-3000",
  "clientName": "新北某客戶",
  "siteName": "新北廠",
  "locationDesc": "2 樓機房",
  "installDate": "2023-06-15",
  "supportsCoP": true,
  "supportsPressure": false,
  "realtimeStatus": {
    "status": "normal",
    "powerKw": 4.8,
    "energyKwh": 15230.5,
    "powerFactor": 0.94,
    "runHours": 6.5,
    "cop": 3.6,
    "inletTemp": 15.2,
    "outletTemp": 55.8,
    "pressure": null
  },
  "powerDailySummary": [
    { "date": "2026-04-17", "kwhTotal": 38.2, "kwhPeak": 7.1, "avgPowerKw": 3.8, "anomalyFlag": false }
    // ... 30 筆
  ],
  "operationDailySummary": [
    { "date": "2026-04-17", "runHours": 14.5, "startupCount": 2, "avgCop": 3.6 }
    // ... 30 筆
  ]
}
```
