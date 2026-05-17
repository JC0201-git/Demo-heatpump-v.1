請根據目前 spec.md 的功能規格，為「熱泵／熱水系統監控儀表板」產出一份完整的技術規劃（Plan）。

本系統是一套熱泵與熱水系統監控 Dashboard，目標先完成 Demo 版本，但 Demo 完成後隔天會直接進入 MVP，因此請避免只做一次性展示架構。請在技術規劃中兼顧「快速完成 Demo」與「可平順升級到 MVP」兩個目標。

重要語言規範：
- 所有規格文件、UI 文字、欄位顯示名稱、錯誤訊息、按鈕文字，皆必須使用繁體中文（zh-TW）。
- 技術命名如 API endpoint、資料表、欄位名稱、程式模組名稱可使用英文。

一、產品範圍

系統需包含 6 個主要頁面：

1. 設備總覽
   - 顯示最多 80 台熱泵／熱水系統設備
   - 每列顯示設備編號、客戶名稱、所在地點、狀態、最後更新時間
   - 支援依狀態篩選
   - 支援依客戶名稱或設備編號搜尋
   - 點擊設備列可進入單機履歷

2. 風險排序
   - 顯示 Top 10 高風險設備
   - 依風險分數 0–100 降序排列
   - 顯示排名、設備編號、客戶名稱、風險分數、風險主因、建議行動
   - 顯示排名變動方向
   - 風險分數公式需支援 SQL Server 設定表調整權重，並能配合業務方後續提供公式進行調整

3. 單機履歷
   - 顯示設備基本資訊：設備編號、型號、安裝日期、客戶、地點、狀態
   - 包含四個子頁籤：
     a. 用電紀錄
     b. 運轉紀錄
     c. 異常紀錄
     d. 維修紀錄
   - 用電紀錄需顯示最近 30 天每日用電量折線圖
   - 運轉紀錄需顯示運轉時數、每日開機次數、COP 值趨勢
   - 異常紀錄需顯示異常事件時間軸
   - 維修紀錄需顯示維修工單歷史

4. 告警中心
   - v1 為「顯示型告警中心」
   - 告警資料主要來自 SQL Server Express
   - 支援告警列表、狀態篩選、異常類型篩選
   - 支援指派負責人
   - 支援更新告警狀態為已解除
   - 未指派告警需置於列表最上方
   - 高嚴重性告警需視覺突出
   - 後續 MVP / v2 需預留演進為「判斷型告警中心」的架構，也就是未來可由後端根據 InfluxDB 數據自動產生告警

5. 月報雛形
   - 可選擇月份
   - 顯示設備健康分數摘要
   - 顯示異常統計
   - 顯示告警處理率與平均解除時間
   - 支援前端 PDF 匯出，採用前端 PDF 函式庫，不需後端 PDF 服務

6. 老闆決策頁
   - 顯示總管理設備數、維運人員數、每人平均負責設備數
   - 顯示維運負載
   - 顯示前 5 名高風險客戶
   - 顯示擴張承載能力
   - 需協助經營者判斷是否能承接新客戶

二、技術架構限制

請依以下技術條件規劃：

1. 前端
   - React + TypeScript
   - 圖表套件使用 ECharts
   - 介面採深色主題：深綠黑底色 + 黃綠色系強調色
   - 左側固定導覽列
   - 頁面頂部顯示最後資料更新時間
   - 桌面瀏覽器為主，最低支援 1280px 以上解析度
   - 本版本不需手機版
   - 前端不得直接連接 InfluxDB 或 SQL Server，必須透過後端 API Server

2. 後端
   - Node.js + TypeScript API Server
   - 可使用 Express 或 Fastify，請在 Plan 中評估並選擇一個適合本案的方案
   - 後端 API Server 部署於與 InfluxDB / SQL Server Express 相同的 AWS EC2 主機
   - 後端負責：
     a. 對前端提供統一 REST API
     b. 查詢 InfluxDB 1.8 的時序資料
     c. 查詢與更新 SQL Server Express 的管理資料
     d. 整合真實資料與 Mock 資料
     e. 提供風險分數計算
     f. 提供告警中心狀態更新
     g. 提供登入驗證
     h. 預留未來自動告警判斷邏輯

3. 資料庫
   - InfluxDB 版本為 1.8
   - SQL Server Express 與 InfluxDB 位於同一台 AWS EC2 Ubuntu 主機
   - Dashboard 前端位於另一台 AWS EC2 Ubuntu 主機
   - Dashboard 與後端 / 資料庫位於不同主機
   - 請在 Plan 中納入跨 EC2 連線、API 安全、CORS、防火牆與環境變數設定

4. 部署
   - 使用 Docker Compose
   - 請規劃至少以下服務：
     a. frontend
     b. backend-api
     c. reverse-proxy，如需要可用 Nginx
   - InfluxDB 與 SQL Server Express 目前已存在，可不一定納入同一份 Docker Compose，但需說明連線方式
   - 請規劃 Demo 部署方式與 MVP 升級方式

三、資料來源策略

目前系統一次最多管理 80 台設備：

- 7 台設備使用真實後端 API / InfluxDB 資料
- 73 台設備使用靜態 Mock JSON 模擬資料
- 80 台設備都必須建立於 SQL Server 的設備主檔中
- SQL Server devices 表需以 data_source_type 區分 real / mock
- Demo 階段仍維持 7 台真實資料 + 73 台 Mock JSON
- 但架構需支援未來逐步把 mock 設備轉換成 real 設備

四、InfluxDB 時序資料規劃

已知 InfluxDB 目前至少有以下 measurement：

1. power_meter
   - 用於智慧電錶資料
   - 欄位內容包含：
     a. 三相電壓
     b. 三相電流
     c. kW
     d. kWh
     e. 功率因數
     f. 頻率
   - 請設計適合 InfluxDB 1.8 的 tags / fields 規劃
   - 請考慮 meter_id、site_id、customer_id、meter_type 等 tags

2. heatpump_status
   - 用於熱泵設備參數與運轉狀態
   - 欄位內容包含：
     a. 運轉狀態
     b. 進水溫度
     c. 出水溫度
     d. 壓力
     e. COP
     f. 開機次數
     g. 運轉時數
     h. 告警代碼
   - 請同時設計「可缺欄位」的資料模型
   - 若某些設備不支援 COP、壓力或部分感測值，前端需顯示「不適用」或「--」，不能造成頁面錯誤

3. 其他 measurement
   - 尚未完整定義
   - 請在 Plan 中提出建議 measurement，例如 operation_log、energy_daily_summary、heatpump_daily_summary 等
   - 但請清楚區分哪些是必要、哪些是建議、哪些可延後到 MVP

五、SQL Server Express 資料模型

SQL Server Express 用於管理資料與告警資料，請至少規劃以下資料表：

1. clients
   - 客戶資料
   - 客戶名稱、聯絡資訊、風險評級等

2. sites
   - 場域資料
   - 一個客戶可有多個場域
   - 場域需支援終端客戶全場域用電資料

3. devices
   - 設備主檔
   - 80 台設備都需進入此表
   - 欄位包含設備編號、型號、安裝日期、客戶、場域、地點、目前狀態、data_source_type、是否啟用等

4. meters
   - 電錶主檔
   - 需區分設備用電電錶與場域總電錶
   - 欄位需包含 meter_id、meter_name、meter_type、site_id、資料來源等

5. device_meter_mappings
   - 熱泵設備與電錶 mapping 表
   - 支援多台熱泵共用一顆設備電錶
   - 支援場域總電錶與設備電錶共存
   - 因熱泵 device_id 與電錶 meter_id 不一定相同，必須透過 mapping 表管理

6. alerts
   - 告警資料
   - v1 由 SQL Server 既有告警資料驅動畫面
   - 欄位包含 alert_id、device_id、alert_type、severity、occurred_at、status、assigned_to、assigned_at、resolved_at、description

7. work_orders
   - 維修工單資料
   - 欄位包含工單編號、設備、派工時間、完工時間、維修人員、問題描述、處置方式

8. technicians
   - 維運人員資料
   - 欄位包含人員編號、姓名、目前工單數、本月完工數、狀態

9. users
   - 登入帳號資料
   - v1 需要多帳號登入
   - 帳號資料存於 SQL Server
   - 保留 role 欄位，但 v1 不啟用角色權限控管
   - 未來可支援 engineer、manager、owner、admin 等角色

10. system_settings
   - 系統設定
   - 例如輪詢秒數、告警門檻、預設查詢區間

11. risk_score_rules / risk_score_weights
   - 風險分數權重設定
   - 風險分數需可由 SQL Server 設定表調整
   - 需能配合業務方提供公式後調整
   - 請在 Plan 中提出 v1 簡化公式與未來可擴充方式

六、登入與權限

請規劃 v1 簡單登入：

- 多帳號登入
- 帳號資料存於 SQL Server
- 密碼需雜湊儲存
- 可使用 JWT 或 session，請在 Plan 中提出建議
- users 表需保留 role 欄位
- v1 不啟用角色權限控管
- 未來 MVP 可依角色顯示不同功能重點

七、API 規劃

請在 Plan 中提出 REST API 規劃，至少包含：

1. Auth
   - POST /api/auth/login
   - POST /api/auth/logout 或前端 token 清除策略
   - GET /api/auth/me

2. Devices
   - GET /api/devices
   - GET /api/devices/:deviceId
   - GET /api/devices/:deviceId/power
   - GET /api/devices/:deviceId/operation
   - GET /api/devices/:deviceId/alerts
   - GET /api/devices/:deviceId/work-orders

3. Risk
   - GET /api/risk/top-devices
   - GET /api/risk/top-clients
   - GET /api/risk/rules
   - PUT /api/risk/rules

4. Alerts
   - GET /api/alerts
   - PUT /api/alerts/:alertId/assign
   - PUT /api/alerts/:alertId/resolve

5. Reports
   - GET /api/reports/monthly?month=YYYY-MM
   - 前端根據回傳資料產生 PDF

6. Executive Dashboard
   - GET /api/executive/summary
   - GET /api/executive/capacity

7. System
   - GET /api/system/last-updated
   - GET /api/system/health

請為每個 API 類型提出 request / response 大致格式、錯誤處理策略、分頁策略、查詢時間區間策略。

八、資料刷新與效能

請依照以下要求規劃：

- 前端每 30 秒向 API 重新取得最新設備狀態與告警資料
- 頁面頂部需顯示最後資料更新時間
- 告警中心在 80 台設備同時有告警時，頁面載入時間不超過 3 秒
- 月報 PDF 產生時間不超過 30 秒
- 設備總覽頁需讓維運工程師 30 秒內識別所有異常設備
- 請提出快取、分頁、API 聚合、資料預先彙整的建議
- InfluxDB 查詢請避免每次前端更新都做大量歷史聚合
- 請評估是否需要 daily summary 資料表或 measurement

九、風險分數規劃

請提出 v1 可用的簡化風險分數公式，並設計為可調整權重。

公式需考慮：

- 告警嚴重性
- 近 7 日異常次數
- 離線時間
- 未完成工單數
- 能耗異常程度
- 長時間未維修
- COP 異常或效率下降，如資料存在

請注意：
- 風險分數範圍為 0–100
- 權重需存於 SQL Server 設定表
- 業務方後續提供公式後，系統需可調整
- Plan 中請清楚說明 Demo 版本公式與 MVP 版本公式的差異

十、告警演進規劃

v1：
- 告警資料由 SQL Server 提供
- 系統主要負責顯示、篩選、指派、解除

MVP / v2：
- 後端可根據 InfluxDB 時序資料判斷告警
- 例如設備離線、功率異常、COP 異常、溫度異常、長時間未更新
- 請在 Plan 中預留 rule engine 或 alert evaluation service 的設計
- 但 Demo 階段不可過度工程化

十一、Mock 與真實資料切換

請規劃資料來源抽象層：

- real 設備：從 InfluxDB / SQL Server 讀取資料
- mock 設備：從靜態 Mock JSON 讀取資料
- API response 格式需一致
- 前端不應知道資料來自 real 或 mock
- devices 表需記錄 data_source_type
- 未來將 mock 設備改為 real 時，不應大幅修改前端

十二、測試策略

請提出測試計畫：

1. 前端測試
   - 頁面渲染
   - 篩選與搜尋
   - 圖表資料呈現
   - 缺欄位資料顯示「--」或「不適用」

2. 後端測試
   - API 單元測試
   - SQL Server 查詢測試
   - InfluxDB 查詢測試
   - Mock / real 資料來源切換測試

3. 整合測試
   - 設備總覽
   - 風險排序
   - 單機履歷
   - 告警指派與解除
   - 月報資料生成
   - 老闆決策頁

4. 效能測試
   - 80 台設備同時有告警
   - 最近 30 天趨勢查詢
   - 月報 PDF 產生
   - 30 秒輪詢

十三、請輸出的 Plan 文件內容

請產出一份清楚、可執行的技術規劃，至少包含以下章節：

1. 技術摘要
2. 系統架構圖文字描述
3. 前端架構規劃
4. 後端 API 架構規劃
5. InfluxDB 1.8 資料模型建議
6. SQL Server Express 資料表設計
7. 熱泵設備與電錶 mapping 設計
8. API endpoint 規劃
9. 登入與安全性規劃
10. Mock / Real 資料來源整合策略
11. 風險分數計算設計
12. 告警中心 v1 與 MVP 演進設計
13. Docker Compose 部署規劃
14. Demo 階段開發順序
15. Demo 隔天進入 MVP 的升級路線
16. 測試策略
17. 技術風險與緩解措施
18. 不納入本階段的項目

十四、規劃原則

請遵守以下原則：

- 不要直接開始寫程式碼
- 先產出技術規劃
- 不要過度工程化，但必須保留 MVP 擴充路線
- 前端不可直接碰資料庫
- API response 需讓 mock 與 real 資料格式一致
- 所有 UI 文字使用繁體中文
- 資料欄位可能不完整，系統需具備容錯能力
- 7 台真實資料與 73 台 mock 資料需可共存
- Demo 版本完成後，必須能快速推進 MVP