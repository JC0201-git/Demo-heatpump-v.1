# 快速入門指南：熱泵／熱水系統監控儀表板

**適用分支**: `001-heatpump-dashboard-6pages`  
**最後更新**: 2026-05-17

---

## 一、環境需求

| 工具 | 版本需求 |
|------|---------|
| Node.js | 20 LTS 以上 |
| Docker | 24.0 以上 |
| Docker Compose | v2.20 以上 |
| Git | 任意 |

---

## 二、本機開發環境初始化

### 2.1 複製儲存庫並安裝依賴

```bash
# 複製專案
git clone <repo-url>
cd Demo-heatpump-v.1

# 安裝前端依賴
cd frontend && npm install && cd ..

# 安裝後端依賴
cd backend && npm install && cd ..
```

### 2.2 設定環境變數

複製範本並修改對應值：

```bash
cp docker/env.example docker/.env
```

**必填環境變數說明**（`docker/.env`）：

```dotenv
# ===== 後端 API =====
NODE_ENV=development
PORT=3001

# JWT 設定（請產生夠長的隨機字串）
JWT_SECRET=請替換為至少64字元的隨機字串
JWT_EXPIRY=8h

# ===== MySQL 8.0 =====
MYSQL_HOST=<EC2-B 私有 IP>
MYSQL_PORT=3306
MYSQL_DATABASE=heatpump_db
MYSQL_USER=<帳號>
MYSQL_PASSWORD=<密碼>

# ===== InfluxDB 1.8 =====
INFLUXDB_HOST=http://<EC2-B 私有 IP>:8086
INFLUXDB_DATABASE=heatpump
INFLUXDB_USERNAME=<帳號>
INFLUXDB_PASSWORD=<密碼>

# ===== 資料快取 =====
DEVICE_CACHE_TTL=25          # 設備/風險快取秒數
REPORT_CACHE_TTL=300         # 月報/歷史資料快取秒數

# ===== 維運設定 =====
MAX_DEVICES_PER_TECH=20      # 每位技師最大可管設備數
```

> ⚠️ **請勿將含有真實密碼的 `.env` 提交至 Git。`docker/.env` 已加入 `.gitignore`。**

---

## 三、啟動本機開發服務

### 3.1 後端（獨立啟動）

```bash
cd backend
cp ../ docker/.env .env    # 或手動建立 backend/.env
npm run dev                 # 啟動 Fastify（熱重載，listen on :3001）
```

### 3.2 前端（獨立啟動）

```bash
cd frontend
npm run dev                 # 啟動 Vite（listen on :5173）
```

前端開發模式預設將 `/api` 代理至 `http://localhost:3001`（`vite.config.ts` 中已設定）。

### 3.3 確認服務啟動

```bash
# 後端健康檢查
curl http://localhost:3001/api/system/health

# 預期回應
{"data":{"status":"healthy","influxdb":"connected","mysql":"connected","uptime":...}}
```

---

## 四、使用 Docker Compose 啟動完整環境

> 適用於 Demo 展示或 EC2 A 部署，InfluxDB 與 SQL Server 仍為 EC2 B 上的現有服務。

```bash
cd docker

# 建置並啟動（第一次較久）
docker compose up --build -d

# 查看容器狀態
docker compose ps

# 查看後端日誌
docker compose logs -f backend-api

# 停止
docker compose down
```

**服務對應埠號**：

| 服務 | 容器埠 | 對外埠 |
|------|--------|--------|
| nginx | 80 | 80 |
| frontend (Vite build) | 3000 | — (nginx 反代) |
| backend-api | 3001 | — (nginx 反代) |

**Nginx 路由規則**：
- `/api/*` → `backend-api:3001`
- `/*` → `frontend:3000`（React SPA）

---

## 五、資料庫初始化

### 5.1 MySQL 建立 Schema

```bash
# 確認資料庫連線後執行
cd backend
npm run db:migrate        # Drizzle ORM 執行 migration
npm run db:seed           # 載入初始資料（clients, sites, devices, users）
```

**初始使用者帳號**（僅開發/Demo）：

| 帳號 | 密碼 | 角色 |
|------|------|------|
| `admin` | `Admin@Demo2026` | `admin` |
| `engineer01` | `Eng01@Demo2026` | `engineer` |

> ⚠️ **正式部署前請務必修改初始密碼。**

### 5.2 Mock 資料 JSON

73 筆 Mock 設備資料放置於 `mock-data/devices/`，命名格式為 `device-008.json`。  
後端啟動時會自動載入所有 Mock JSON 至記憶體（StartupLoader）。

---

## 六、開發流程說明

### 6.1 前端頁面對應路由

| 頁面 | 路由 |
|------|------|
| 設備總覽 | `/` |
| 風險排序 | `/risk` |
| 單機履歷（設備詳情）| `/devices/:deviceId` |
| 告警中心 | `/alerts` |
| 月報雛形 | `/reports` |
| 老闆決策頁 | `/executive` |
| 登入 | `/login` |

### 6.2 新增 Mock 設備資料

1. 在 `mock-data/devices/` 新增 `device-<N>.json`（參照 `data-model.md` 第六節格式）
2. 在 `backend/src/data/seed/devices.ts` 中新增對應的 `devices` 資料列（`mock_data_file` 欄位）
3. 重啟後端服務

### 6.3 前端環境變數

`frontend/.env.development`：

```dotenv
VITE_API_BASE_URL=http://localhost:3001
```

---

## 七、執行測試

```bash
# 前端單元測試（Vitest）
cd frontend && npm run test

# 前端覆蓋率報告
cd frontend && npm run test:coverage

# 後端單元測試（Jest + Fastify inject）
cd backend && npm run test

# 後端覆蓋率報告
cd backend && npm run test:coverage
```

**目標覆蓋率（Constitution 第二條）**：≥ 80%

---

## 八、常見問題排除

### Q: 後端啟動時出現 `SQL Server connection failed`

確認 `SQLSERVER_HOST` 設定為 EC2 B 的 VPC 私有 IP（不是公有 IP），且 EC2 B Security Group 允許 EC2 A 的 CIDR 存取 1433 埠。

### Q: InfluxDB 查詢返回空資料

1. 確認 `INFLUXDB_DATABASE` 的資料庫名稱正確
2. 確認 `INFLUXDB_HOST` 使用 HTTP（InfluxDB 1.8 預設不啟用 HTTPS）
3. 使用 `influx` CLI 確認 measurement 存在：
   ```bash
   influx -host <EC2-B IP> -port 8086 -database heatpump -execute "SHOW MEASUREMENTS"
   ```

### Q: 前端顯示「--」而非實際數值

設備 `supportsCoP: false` 或 `supportsPressure: false` 時，前端會顯示「不適用」。若 `supportsCoP: true` 但顯示 `--`，代表 InfluxDB 目前無該設備 COP 資料，屬預期行為。

### Q: 如何新增登入帳號

直接執行 SQL（或透過 Drizzle seed），密碼需使用 bcrypt（cost factor 12）雜湊後寫入：

```typescript
import bcrypt from 'bcrypt';
const hash = await bcrypt.hash('your_password', 12);
```

---

## 九、相關文件

| 文件 | 路徑 |
|------|------|
| 功能規格 | [spec.md](./spec.md) |
| 技術實施規劃 | [plan.md](./plan.md) |
| 研究報告 | [research.md](./research.md) |
| 資料模型 | [data-model.md](./data-model.md) |
| API 合約（認證）| [contracts/auth.md](./contracts/auth.md) |
| API 合約（設備）| [contracts/devices.md](./contracts/devices.md) |
| API 合約（告警）| [contracts/alerts.md](./contracts/alerts.md) |
| API 合約（其他）| [contracts/risk-reports-executive-system.md](./contracts/risk-reports-executive-system.md) |
