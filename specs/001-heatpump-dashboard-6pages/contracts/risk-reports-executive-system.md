# API 合約：風險排序、月報、老闆決策頁、系統

**版本**: v1 | **更新**: 2026-05-17  
**認證**: 所有 endpoint 需有效 JWT cookie（`hp_token`）

---

## 風險排序 API（Risk）

### GET /api/risk/top-devices

**說明**：取得 Top 10 高風險設備排行。

#### Response 200 OK

```json
{
  "data": [
    {
      "rank": 1,
      "deviceId": "DEV-055",
      "deviceCode": "DEV-055",
      "deviceName": "2F 熱泵機組",
      "clientName": "高雄某客戶",
      "siteName": "高雄廠",
      "riskScore": 87.3,
      "riskReasons": [
        "近 7 日連續異常 5 次",
        "未完成工單 2 張",
        "今日離線 4 小時"
      ],
      "suggestedAction": "緊急",
      "rankChange": "up",
      "rankDelta": 2
    }
  ],
  "meta": { "updatedAt": "2026-05-17T10:30:05Z" }
}
```

**`suggestedAction` 判斷規則**：
- `riskScore ≥ 70` → `緊急`
- `riskScore ≥ 40` → `本週`
- `riskScore < 40` → `本月`

**`rankChange` 說明**：
- `up`：排名上升（風險增加）
- `down`：排名下降（風險降低）
- `same`：排名不變

---

### GET /api/risk/top-clients

**說明**：取得 Top 5 高風險客戶（用於老闆決策頁）。

#### Response 200 OK

```json
{
  "data": [
    {
      "rank": 1,
      "clientId": "CLI-012",
      "clientName": "高雄某客戶",
      "deviceCount": 8,
      "alertCount": 5,
      "avgRiskScore": 72.5,
      "riskTier": "high",
      "suggestedAction": "主動聯繫"
    }
  ],
  "meta": { "updatedAt": "2026-05-17T10:30:05Z" }
}
```

---

### GET /api/risk/rules

**說明**：取得目前風險分數權重設定。

#### Response 200 OK

```json
{
  "data": [
    {
      "ruleId": 1,
      "ruleName": "alert_severity",
      "description": "告警嚴重性",
      "weight": 30.00,
      "enabled": true
    }
  ],
  "meta": { "updatedAt": "2026-05-17T10:30:05Z" }
}
```

---

### PUT /api/risk/rules

**說明**：更新風險分數權重設定（限管理員，v1 不啟用角色控管但保留 endpoint）。

#### Request

```json
{
  "rules": [
    { "ruleId": 1, "weight": 35.00, "enabled": true },
    { "ruleId": 2, "weight": 15.00, "enabled": true }
  ]
}
```

**驗證規則**：所有 `enabled: true` 的規則，`weight` 加總必須 = 100。

#### Response 200 OK

```json
{
  "data": { "message": "權重設定已更新，下次計算週期生效" }
}
```

#### Response 422 Unprocessable Entity

```json
{
  "error": "INVALID_WEIGHT_SUM",
  "message": "啟用的權重加總必須等於 100，目前為 95",
  "statusCode": 422
}
```

---

## 月報 API（Reports）

### GET /api/reports/monthly

**說明**：取得指定月份的設備月度統計報告（前端使用此資料產生 PDF）。逾時未處理告警門檻由 `system_settings.ALERT_OVERDUE_HOURS` 決定，預設 24 小時。

#### Query Parameters

| 參數 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `month` | string（YYYY-MM）| ✅ | 目標月份（如 `2026-04`）|

#### Response 200 OK

```json
{
  "data": {
    "month": "2026-04",
    "generatedAt": "2026-05-17T10:30:05Z",
    "deviceHealthSummary": {
      "avgScore": 72.5,
      "distribution": {
        "90-100": 15,
        "70-89": 40,
        "50-69": 20,
        "0-49": 5
      },
      "totalDevices": 80
    },
    "anomalyStats": {
      "totalCount": 48,
      "byType": [
        { "type": "offline", "label": "設備離線", "count": 20 },
        { "type": "high_power", "label": "用電異常", "count": 15 },
        { "type": "cop_anomaly", "label": "效能異常", "count": 8 },
        { "type": "temp_anomaly", "label": "溫度異常", "count": 5 }
      ],
      "topAnomalyDevices": [
        {
          "deviceCode": "DEV-055",
          "deviceName": "2F 熱泵機組",
          "clientName": "高雄某客戶",
          "anomalyCount": 8
        }
      ]
    },
    "alertStats": {
      "totalAlerts": 48,
      "resolvedCount": 42,
      "resolvedRate": 0.875,
      "avgResolveHours": 4.2,
      "overdueCount": 6,
      "overdueThresholdHours": 24
    }
  },
  "meta": { "updatedAt": "2026-05-17T10:30:05Z" }
}
```

**`alertStats.overdueCount` 計算規則**：
- 統計狀態為 `open` 或 `in_progress` 的告警。
- 若 `generatedAt - occurredAt` 超過 `system_settings.ALERT_OVERDUE_HOURS` 小時，即計入逾時未處理。
- `ALERT_OVERDUE_HOURS` 缺漏或無法解析時，使用預設 24 小時。

#### Response 422 Unprocessable Entity

```json
{
  "error": "INVALID_MONTH",
  "message": "月份格式錯誤，請使用 YYYY-MM 格式",
  "statusCode": 422
}
```

---

## 老闆決策頁 API（Executive）

### GET /api/executive/summary

**說明**：取得老闆決策頁核心 KPI 與維運負載。

#### Response 200 OK

```json
{
  "data": {
    "kpi": {
      "totalDevices": 80,
      "totalTechnicians": 5,
      "avgDevicesPerTech": 16.0
    },
    "technicianWorkload": [
      {
        "technicianId": 1,
        "fullName": "張技師",
        "activeWorkOrders": 3,
        "completedThisMonth": 12,
        "utilizationRate": 0.75
      }
    ],
    "topRiskClients": [
      {
        "rank": 1,
        "clientName": "高雄某客戶",
        "deviceCount": 8,
        "anomalyCountThisMonth": 15,
        "riskTier": "high",
        "suggestedAction": "主動聯繫"
      }
    ]
  },
  "meta": { "updatedAt": "2026-05-17T10:30:05Z" }
}
```

---

### GET /api/executive/capacity

**說明**：試算擴張承載能力。

#### Query Parameters

| 參數 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `addDevices` | number | ❌ | 假設新增設備數（預設 0）|

#### Response 200 OK

```json
{
  "data": {
    "currentDevices": 80,
    "currentTechnicians": 5,
    "avgDevicesPerTech": 16,
    "currentUtilization": 0.72,
    "maxCapacityPerTech": 20,
    "totalMaxCapacity": 100,
    "projectedDevices": 90,
    "projectedUtilization": 0.90,
    "maxSafeAddDevices": 15,
    "recommendation": "目前維運產能可安全承接最多 15 台新設備（達 95% 產能上限）",
    "capacityCurve": [
      { "addDevices": 0, "utilization": 0.72 },
      { "addDevices": 5, "utilization": 0.77 },
      { "addDevices": 10, "utilization": 0.82 },
      { "addDevices": 15, "utilization": 0.87 },
      { "addDevices": 20, "utilization": 0.92 }
    ]
  },
  "meta": { "updatedAt": "2026-05-17T10:30:05Z" }
}
```

**`maxSafeAddDevices` 計算邏輯**：
```
maxCapacityPerTech = 20（可由 system_settings 設定）
totalMaxCapacity = maxCapacityPerTech × totalTechnicians
maxSafeAddDevices = totalMaxCapacity × 0.95 - currentDevices
```

---

## 系統 API（System）

### GET /api/system/last-updated

**說明**：取得各資料源的最後更新時間（用於頁面頂部顯示）。

#### Response 200 OK

```json
{
  "data": {
    "deviceStatus": "2026-05-17T10:30:00Z",
    "alerts": "2026-05-17T10:29:55Z",
    "riskScores": "2026-05-17T10:25:00Z"
  }
}
```

---

### GET /api/system/health

**說明**：系統健康檢查（用於 Docker health check 及監控）。

#### Response 200 OK（正常）

```json
{
  "data": {
    "status": "healthy",
    "influxdb": "connected",
    "sqlserver": "connected",
    "uptime": 86400
  }
}
```

#### Response 503 Service Unavailable（異常）

```json
{
  "data": {
    "status": "degraded",
    "influxdb": "disconnected",
    "sqlserver": "connected",
    "uptime": 86400
  }
}
```

---

## 通用錯誤代碼對照表

| HTTP Status | `error` | `message` |
|-------------|---------|-----------|
| 400 | `BAD_REQUEST` | 請求參數格式錯誤 |
| 401 | `UNAUTHORIZED` | 請先登入 |
| 403 | `FORBIDDEN` | 您沒有權限執行此操作 |
| 404 | `DEVICE_NOT_FOUND` | 找不到指定設備 |
| 404 | `ALERT_NOT_FOUND` | 找不到指定告警 |
| 409 | `ALERT_ALREADY_RESOLVED` | 此告警已解除 |
| 422 | `INVALID_CREDENTIALS` | 帳號或密碼錯誤 |
| 422 | `TECHNICIAN_NOT_FOUND` | 找不到指定技師 |
| 422 | `INVALID_WEIGHT_SUM` | 風險分數權重加總必須等於 100 |
| 422 | `INVALID_MONTH` | 月份格式錯誤 |
| 429 | `RATE_LIMIT_EXCEEDED` | 請求次數過多，請稍後再試 |
| 500 | `INTERNAL_ERROR` | 系統內部錯誤，請聯絡管理員 |
