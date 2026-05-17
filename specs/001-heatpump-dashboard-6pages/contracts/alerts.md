# API 合約：告警（Alerts）

**版本**: v1 | **更新**: 2026-05-17  
**認證**: 所有 endpoint 需有效 JWT cookie（`hp_token`）

---

## GET /api/alerts

**說明**：取得全系統告警列表，支援篩選與分頁。  
**排序規則**：先依 `assigned_to IS NULL DESC`（未指派置頂），再依 `severity`（high > medium > low），再依 `occurred_at DESC`。

### Query Parameters

| 參數 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `status` | string | ❌ | `open` \| `in_progress` \| `resolved`（不傳則返回 open + in_progress）|
| `alert_type` | string | ❌ | 告警類型篩選 |
| `severity` | string | ❌ | `high` \| `medium` \| `low` |
| `page` | number | ❌ | 頁碼（預設 1）|
| `limit` | number | ❌ | 每頁筆數（預設 50）|

### Response 200 OK

```json
{
  "data": [
    {
      "alertId": 101,
      "deviceId": "DEV-003",
      "deviceCode": "DEV-003",
      "deviceName": "3F 熱泵機組",
      "clientName": "台中某客戶",
      "siteName": "台中廠",
      "alertType": "offline",
      "alertTypeLabel": "設備離線",
      "severity": "high",
      "severityLabel": "高",
      "occurredAt": "2026-05-17T08:00:00Z",
      "status": "open",
      "statusLabel": "未處理",
      "assignedTo": null,
      "assignedToName": null,
      "assignedAt": null,
      "resolvedAt": null,
      "description": "設備心跳超時 10 分鐘，可能離線或網路中斷"
    },
    {
      "alertId": 98,
      "deviceId": "DEV-015",
      "deviceCode": "DEV-015",
      "deviceName": "B1 熱泵機組",
      "clientName": "高雄某客戶",
      "siteName": "高雄廠",
      "alertType": "high_power",
      "alertTypeLabel": "用電異常",
      "severity": "medium",
      "severityLabel": "中",
      "occurredAt": "2026-05-17T07:15:00Z",
      "status": "in_progress",
      "statusLabel": "處理中",
      "assignedTo": 3,
      "assignedToName": "李技師",
      "assignedAt": "2026-05-17T07:30:00Z",
      "resolvedAt": null,
      "description": "近 7 日平均用電超過歷史均值 35%"
    }
  ],
  "meta": {
    "total": 23,
    "page": 1,
    "limit": 50,
    "updatedAt": "2026-05-17T10:30:05Z"
  }
}
```

### 告警類型對照表

| `alertType` | `alertTypeLabel` |
|-------------|-----------------|
| `offline` | 設備離線 |
| `high_power` | 用電異常 |
| `cop_anomaly` | 效能異常 |
| `temp_anomaly` | 溫度異常 |
| `custom` | 自訂告警 |

---

## PUT /api/alerts/:alertId/assign

**說明**：指派告警給指定技師，狀態自動更新為 `in_progress`。

### Path Parameters

| 參數 | 說明 |
|------|------|
| `alertId` | 告警 ID（數字）|

### Request

```http
PUT /api/alerts/101/assign
Content-Type: application/json
Cookie: hp_token=<JWT>

{
  "technicianId": 3
}
```

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `technicianId` | number | ✅ | 技師 ID（需為有效且 active 的技師）|

### Response 200 OK

```json
{
  "data": {
    "alertId": 101,
    "status": "in_progress",
    "statusLabel": "處理中",
    "assignedTo": 3,
    "assignedToName": "李技師",
    "assignedAt": "2026-05-17T10:35:00Z"
  },
  "meta": { "updatedAt": "2026-05-17T10:35:00Z" }
}
```

### Response 404 Not Found

```json
{
  "error": "ALERT_NOT_FOUND",
  "message": "找不到指定告警",
  "statusCode": 404
}
```

### Response 422 Unprocessable Entity

```json
{
  "error": "TECHNICIAN_NOT_FOUND",
  "message": "找不到指定技師或技師目前不可指派",
  "statusCode": 422
}
```

---

## PUT /api/alerts/:alertId/resolve

**說明**：將告警狀態更新為已解除，記錄解除時間與處置說明。

### Request

```http
PUT /api/alerts/101/resolve
Content-Type: application/json
Cookie: hp_token=<JWT>

{
  "resolutionNote": "更換壓縮機後恢復正常運轉"
}
```

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `resolutionNote` | string | ❌ | 處置說明（最大 500 字元）|

### Response 200 OK

```json
{
  "data": {
    "alertId": 101,
    "status": "resolved",
    "statusLabel": "已解除",
    "resolvedAt": "2026-05-17T15:00:00Z",
    "resolutionNote": "更換壓縮機後恢復正常運轉"
  },
  "meta": { "updatedAt": "2026-05-17T15:00:00Z" }
}
```

### Response 409 Conflict

```json
{
  "error": "ALERT_ALREADY_RESOLVED",
  "message": "此告警已解除，無法再次更新",
  "statusCode": 409
}
```
