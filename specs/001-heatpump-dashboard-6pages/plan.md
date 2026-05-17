# 實作計畫：熱泵／熱水系統監控儀表板（6 頁）

**Branch**: `001-heatpump-dashboard-6pages` | **Date**: 2026-05-17 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/001-heatpump-dashboard-6pages/spec.md`

## Summary

建置一套管理 80 台熱泵設備的監控儀表板，包含 6 個頁面：設備總覽、風險排序、單機履歷、告警中心、月報雛形、老闆決策頁。前端採 React + TypeScript + Vite，後端採 Fastify 4 + Drizzle ORM，關聯式資料庫使用 MySQL 8.0，時序資料使用 InfluxDB 1.8。7 台設備接真實 API；73 台使用靜態 Mock JSON。

## Technical Context

**Language/Version**: TypeScript 5.x（前端 React 18 / 後端 Node.js 20 LTS）  
**Primary Dependencies**: React 18, Vite 5, Fastify 4, Drizzle ORM（mysql2）, influx@5, Zustand, Recharts, jsPDF + html2canvas  
**Storage**: MySQL 8.0（關聯資料）+ InfluxDB 1.8（時序資料）  
**Testing**: Vitest（前端）+ Node.js test runner / supertest（後端 API）；覆蓋率目標 ≥ 80%  
**Target Platform**: Ubuntu Linux（EC2 A：前端 + 後端 API；EC2 B：MySQL + InfluxDB）  
**Project Type**: web-service（React SPA + Fastify REST API）  
**Performance Goals**: API p95 ≤ 500 ms；設備總覽頁載入 ≤ 3 s（80 台設備同時告警）；月報 PDF 產生 ≤ 30 s  
**Constraints**: 桌面瀏覽器（1280px 以上）；無手機版；v1 不含角色權限管控；資料輪詢 30 秒  
**Scale/Scope**: 80 台設備（7 real + 73 mock），6 頁面，1 個 REST API 服務，1 個 React SPA

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Code Quality**: ESLint + Prettier 設定於 monorepo 根目錄；cyclomatic complexity ≤ 10（eslint-plugin-complexity）；TypeScript strict mode 啟用
- [x] **II. Testing Standards**: 前端 Vitest，後端 Node test runner + supertest；覆蓋率 ≥ 80%；Red-Green-Refactor 流程；每個 user story 有至少一個整合測試
- [x] **III. UX Consistency**: 深色主題設計 token（深綠黑 + 黃綠強調色）；WCAG 2.1 AA 對比度要求；一致狀態語意色彩（綠/紅/灰/橘）
- [x] **IV. Performance Requirements**: p95 ≤ 500 ms（API）；告警頁 ≤ 3 s（80 台同時告警）；後端快取 TTL 25 s；InfluxDB daily summary 確保圖表查詢 ≤ 50 ms
- [x] **V. Documentation Language**: 本計畫及所有規格 / quickstart 文件以繁體中文（zh-TW）撰寫；UI 文字與錯誤訊息確認為 zh-TW

## Project Structure

### Documentation (this feature)

```text
specs/001-heatpump-dashboard-6pages/
├── plan.md              # 本文件（/speckit.plan 指令輸出）
├── research.md          # Phase 0 輸出
├── data-model.md        # Phase 1 輸出
├── quickstart.md        # Phase 1 輸出
├── contracts/           # Phase 1 輸出
└── tasks.md             # Phase 2 輸出（/speckit.tasks 指令產生）
```

### Source Code (repository root)

```text
backend/
├── src/
│   ├── db/              # Drizzle schema & migrations（MySQL）
│   ├── influx/          # InfluxDB 1.8 查詢（influx@5）
│   ├── routes/          # Fastify route handlers（devices, alerts, risk, reports, executive）
│   ├── services/        # 業務邏輯（risk score, monthly report, mock loader）
│   ├── auth/            # JWT + httpOnly cookie 認證
│   └── types/           # 共用 DTO TypeScript 型別
└── tests/
    ├── contract/        # API 合約測試
    ├── integration/     # 整合測試（Fastify inject）
    └── unit/            # 單元測試（services）

frontend/
├── src/
│   ├── components/      # 共用 UI 元件（StatusBadge, RiskCard, AlertRow…）
│   ├── pages/           # 6 頁面元件
│   ├── stores/          # Zustand 狀態（devices, alerts, polling）
│   ├── services/        # API 呼叫函式
│   └── types/           # 前端型別（與 backend/src/types 對齊）
└── tests/

mock-data/
└── devices/             # 73 個 Mock JSON（device-008.json … device-080.json）

docker/
├── docker-compose.yml
├── nginx.conf
└── env.example          # 環境變數範本（MYSQL_*, INFLUXDB_*, JWT_SECRET）
```

**Structure Decision**: 採用前後端分離架構（Option 2）。後端 Fastify API 部署於 EC2 A（容器化），MySQL 與 InfluxDB 部署於 EC2 B。Nginx 反向代理統一入口（Port 80），`/api/*` 路由至後端，`/*` 路由至前端 SPA。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| 混合資料來源（MySQL + InfluxDB）| 結構資料（設備主檔、告警、工單）需 ACID 事務；時序資料（用電、運轉）需高寫入吞吐量，兩者特性不同 | 單一資料庫無法同時滿足兩種需求 |

| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
