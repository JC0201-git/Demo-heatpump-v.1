# API 合約：認證（Auth）

**版本**: v1 | **更新**: 2026-05-17

---

## POST /api/auth/login

**說明**：使用帳號密碼登入，成功後設定 httpOnly JWT cookie。

### Request

```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "engineer01",
  "password": "your_password"
}
```

| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| `username` | string | ✅ | 帳號名稱（1 ～ 50 字元）|
| `password` | string | ✅ | 密碼明文（1 ～ 100 字元）|

### Response 200 OK

```json
{
  "data": {
    "userId": 1,
    "username": "engineer01",
    "displayName": "張工程師",
    "role": "engineer"
  },
  "meta": { "updatedAt": "2026-05-17T10:30:00Z" }
}
```

**Set-Cookie**: `hp_token=<JWT>; HttpOnly; SameSite=Lax; Path=/; Max-Age=28800`

### Response 401 Unauthorized

```json
{
  "error": "INVALID_CREDENTIALS",
  "message": "帳號或密碼錯誤",
  "statusCode": 401
}
```

### Response 429 Too Many Requests（Rate Limit）

```json
{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "登入嘗試次數過多，請稍後再試",
  "statusCode": 429
}
```

**安全注意**：無論帳號不存在或密碼錯誤，統一返回相同錯誤訊息，防止帳號枚舉攻擊。

---

## POST /api/auth/logout

**說明**：清除 JWT cookie，登出目前會話。

### Request

```http
POST /api/auth/logout
Cookie: hp_token=<JWT>
```

### Response 200 OK

```json
{ "data": { "message": "已成功登出" } }
```

**Set-Cookie**: `hp_token=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0`（清除 cookie）

---

## GET /api/auth/me

**說明**：取得目前登入使用者資訊。需有效 JWT。

### Request

```http
GET /api/auth/me
Cookie: hp_token=<JWT>
```

### Response 200 OK

```json
{
  "data": {
    "userId": 1,
    "username": "engineer01",
    "displayName": "張工程師",
    "role": "engineer",
    "technicianId": 3
  }
}
```

### Response 401 Unauthorized

```json
{
  "error": "UNAUTHORIZED",
  "message": "請先登入",
  "statusCode": 401
}
```
