  | ID | Category | Severity | Location(s) | Summary | Recommendation |
  |----|----------|----------|-------------|---------|----------------|
  | I1 | Inconsistency | HIGH | specs/001-heatpump-dashboard-6pages/spec.md:234, specs/001-
  heatpump-dashboard-6pages/plan.md:501 | 風險分數公式不一致：spec 直接乘權重，plan 使用
  weight / 100。若照 spec 實作，0-100 正規化分數會放大 100 倍。 | 修正 spec 公式為 Σ(score_i ×
  weight_i / 100)，並保留 T059 對 [0,100] 的測試。 |
  | U1 | Underspecification | HIGH | specs/001-heatpump-dashboard-6pages/plan.md:512,
  specs/001-heatpump-dashboard-6pages/tasks.md:153 | energy_anomaly_score 被 riskScoreService
  讀取，但沒有明確任務負責從 Influx/mock daily summary 同步或計算此快照欄位。 | 新增任務或擴充
  T060：明確產生/更新 device_risk_snapshots.energy_anomaly_score。 |
  | I2 | Inconsistency | HIGH | specs/001-heatpump-dashboard-6pages/spec.md:84, specs/001-
  heatpump-dashboard-6pages/spec.md:131, specs/001-heatpump-dashboard-6pages/tasks.md:121 | 告
  警排序有兩個「置頂」規則：高嚴重性置頂、未指派置頂。T046 選擇「未指派 → severity」，但 spec
  有相反暗示。 | 在 spec 明定排序優先序，例如「未指派優先，其次 severity，再依 occurredAt」。 |
  | C1 | Coverage | MEDIUM | specs/001-heatpump-dashboard-6pages/plan.md:679, specs/001-
  heatpump-dashboard-6pages/tasks.md:268 | plan 要求 30 日趨勢圖 API ≤500ms，但 T109 benchmark
  未列 /api/devices/:deviceId/power 與 /operation。 | 將 device history trend endpoints 加入
  T109 或新增 perf task。 |
  | A1 | Ambiguity | MEDIUM | specs/001-heatpump-dashboard-6pages/spec.md:177, specs/001-
  heatpump-dashboard-6pages/tasks.md:219 | FR-025 要求 PDF「輸出結果一致」，但任務只涵蓋匯出與
  效能，沒有定義一致性的驗收方式。 | 補一個 PDF snapshot/hash/關鍵文字檢查，或將「一致」改成明
  確可測標準。 |
  | I3 | Inconsistency | LOW | specs/001-heatpump-dashboard-6pages/spec.md:198, specs/001-
  heatpump-dashboard-6pages/plan.md:310 | plan/tasks 引入 sites、meters、device_meter_mappings
  等核心資料表，但 spec 關鍵實體未列出。 | 若這些是本功能必要資料概念，補入 spec 關鍵實體；若只
  是技術實作，plan 註明 implementation-only。 |


  task I1: 驗證公式使用 `Σ(score_i × weight_i / 100)`，輸出必須限制在 [0,100]。