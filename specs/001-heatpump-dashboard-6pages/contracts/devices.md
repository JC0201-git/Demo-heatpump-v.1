# API 合約：設備（Devices）

**版本**: v1 | **更新**: 2026-05-17  
**認證**: 所有 endpoint 需有效 JWT cookie（`hp_token`）

---

## GET /api/devices

**說明**：取得設備列表，支援篩選與搜尋。

### Query Parameters

| 參數 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `status` | string | ❌ | 篩選設備狀態：`normal` \| `alert` \| `offline` \| `maintenance` |
| `search` | string | ❌ | 搜尋設備編號或客戶名稱（部分比對）|
| `page` | number | ❌ | 頁碼（預設 1）|
| `limit` | number | ❌ | 每頁筆數（預設 80，最大 100）|

### Response 200 OK

```json
{
  "data": [
    {
      "deviceId": "DEV-001",
      "deviceCode": "DEV-001",
      "deviceName": "1F 熱泵機組",
      "model": "HP-5000",
      "clientName": "台北某某公司",
      "siteName": "台北廠",
      "locationDesc": "1 樓機房",
      "status": "normal",
      "riskScore": 15.5,
      "lastHeartbeatAt": "2026-05-17T10:30:00Z",
      "dataSourceType": "real"
    }
  ],
  "meta": {
    "total": 80,
    "page": 1,
    "limit": 80,
    "updatedAt": "2026-05-17T10:30:05Z"
  }
}
```

**排序規則**：先依 `status`（alert > maintenance > offline > normal），再依 `riskScore` 降序。

---

## GET /api/devices/:deviceId

**說明**：取得單台設備詳細資訊。

### Path Parameters

| 參數 | 說明 |
|------|------|
| `deviceId` | 設備編號（如 `DEV-001`）|

### Response 200 OK

```json
{
  "data": {
    "deviceId": "DEV-001",
    "deviceCode": "DEV-001",
    "deviceName": "1F 熱泵機組",
    "model": "HP-5000",
    "installDate": "2022-03-15",
    "clientName": "台北某某公司",
    "siteName": "台北廠",
    "locationDesc": "1 樓機房",
    "status": "normal",
    "riskScore": 15.5,
    "lastHeartbeatAt": "2026-05-17T10:30:00Z",
    "supportsCoP": true,
    "supportsPressure": false,
    "dataSourceType": "real"
  },
  "meta": { "updatedAt": "2026-05-17T10:30:05Z" }
}
```

### Response 404 Not Found

```json
{
  "error": "DEVICE_NOT_FOUND",
  "message": "找不到指定設備",
  "statusCode": 404
}
```

---

## GET /api/devices/:deviceId/power

**說明**：取得設備用電紀錄（每日彙總 + 即時資料）。

### Query Parameters

| 參數 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `from` | string（ISO8601）| ❌ | 起始日期（預設 30 天前）|
| `to` | string（ISO8601）| ❌ | 結束日期（預設今日）|

### Response 200 OK

```json
{
  "data": {
    "deviceId": "DEV-001",
    "dailySummary": [
      {
        "date": "2026-04-17",
        "kwhTotal": 45.2,
        "kwhPeak": 8.3,
        "avgPowerKw": 3.8,
        "anomalyFlag": false
      }
    ],
    "realtimePower": {
      "powerKw": 5.2,
      "energyKwh": 1234.5,
      "powerFactor": 0.95,
      "frequency": 60.0
    }
  },
  "meta": { "updatedAt": "2026-05-17T10:30:05Z" }
}
```

**說明**：
- `dailySummary`：依 `date` 升序排列
- `realtimePower`：若設備離線或無電錶資料，為 `null`
- 安裝不足 30 天的設備：`dailySummary` 只含有資料的日期（不補空值）

---

## GET /api/devices/:deviceId/operation

**說明**：取得設備運轉紀錄（每日彙總）。

### Query Parameters

同 `/power`：`from`、`to`（預設 30 日）

### Response 200 OK

```json
{
  "data": {
    "deviceId": "DEV-001",
    "dailySummary": [
      {
        "date": "2026-04-17",
        "runHours": 18.5,
        "startupCount": 3,
        "avgCop": 3.8
      }
    ],
    "supportsCoP": true,
    "supportsPressure": false,
    "realtimeStatus": {
      "operatingMode": "running",
      "inletTemp": 15.2,
      "outletTemp": 55.8,
      "pressure": null,
      "cop": 3.7,
      "runHoursToday": 6.5,
      "startupCountToday": 2,
      "alarmCode": "",
      "alarmDesc": null
    }
  },
  "meta": { "updatedAt": "2026-05-17T10:30:05Z" }
}
```

**說明**：
- `avgCop`：`null` 代表設備不支援或當日無資料（前端依 `supportsCoP` 顯示「不適用」或 `--`）
- `pressure`：`null` 代表設備不支援（前端依 `supportsPressure` 顯示「不適用」或 `--`）

---

## GET /api/devices/:deviceId/alerts

**說明**：取得設備告警歷史。

### Query Parameters

| 參數 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `page` | number | ❌ | 頁碼（預設 1）|
| `limit` | number | ❌ | 每頁筆數（預設 20）|
| `status` | string | ❌ | 篩選告警狀態 |

### Response 200 OK

```json
{
  "data": [
    {
      "alertId": 101,
      "alertType": "offline",
      "alertTypeLabel": "設備離線",
      "severity": "high",
      "occurredAt": "2026-05-10T08:00:00Z",
      "resolvedAt": "2026-05-10T10:30:00Z",
      "status": "resolved",
      "statusLabel": "已解除",
      "description": "設備心跳超時 10 分鐘",
      "resolutionNote": "重啟控制器後恢復"
    }
  ],
  "meta": { "total": 5, "page": 1, "limit": 20 }
}
```

---

## GET /api/devices/:deviceId/work-orders

**說明**：取得設備維修工單歷史。

### Query Parameters

| 參數 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `page` | number | ❌ | 頁碼（預設 1）|
| `limit` | number | ❌ | 每頁筆數（預設 20）|

### Response 200 OK

```json
{
  "data": [
    {
      "workOrderId": 45,
      "woCode": "WO-20260501-003",
      "status": "completed",
      "statusLabel": "已完成",
      "priority": "high",
      "priorityLabel": "高優先",
      "assignedToName": "李技師",
      "dispatchedAt": "2026-05-01T09:00:00Z",
      "completedAt": "2026-05-01T14:30:00Z",
      "issueDesc": "壓縮機異常噪音",
      "resolutionDesc": "更換冷媒並重新平衡"
    }
  ],
  "meta": { "total": 3, "page": 1, "limit": 20 }
}
```
