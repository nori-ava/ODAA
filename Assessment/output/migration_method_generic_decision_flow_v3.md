# Oracle Database移行方式 選定 汎用判断フロー v3（Mermaid）

v2へのレビュー指摘（①〜⑤および技術条件の書き方2点）を反映した改訂版です。

## v2からの主な変更点

| # | v2の問題 | v3での修正 |
| --- | --- | --- |
| ① | Physical Online不成立で系統全体（Offlineも含む）を除外していた | 「系統共通の基盤適合性（Platform/Endian/Version等）」と「方式固有条件（Online用のData Guard対応等）」を分離。方式固有条件の不成立は**その方式のみ**を除外し、他方式は独立評価を継続 |
| ② | 不適合経路から直接候補集約に進み、他方式の評価完了前に「候補なし」と判断され得た | 全4方式（Physical Online/Offline, Logical Online/Offline）の評価完了を待つ「**評価結果の集約**」ノードを追加。Online/Offline間の横断矢印を廃止し、完全に独立評価に統一 |
| ③ | Onlineは同期性能のみ判定し、切替時停止時間の判定が図になかった | Physical Online・Logical Onlineの両方に「**更新停止・最終同期・検証・接続切替・業務再開が許容停止時間内か**」の判定を追加 |
| ④ | 共通ゲート通過後、必ず暫定推奨に進み、全候補が必須要件未達の場合の出口がなかった | 共通比較ゲートの後に「**必須要件（Data loss等）を満たす候補が残るか**」の判定を追加し、Noなら要件／方式の再検討へ |
| ⑤ | PoC失敗後、「候補が尽きればQ0へ」と本文にあるが図はCommonGateにしか戻っていなかった | 「**検証結果を反映し、再評価可能な候補があるか**」を追加し、Yesは共通比較ゲートへ、Noは要件再定義へ接続 |
| 技術条件-1 | ARCHIVELOG等を一括必須としてOnline/Offline区別なく判定していた | 系統共通の基盤条件（Platform/Endian/Version/Edition/RU等）と、Online固有条件（Data Guard対応等）を明確に分離 |
| 技術条件-2 | Logical Onlineで「全Object/データ型対応」を要求し厳しすぎた | 「同期対象の更新データが同期可能か、非対応分は停止中の個別移行等で補完できるか（補完時間も停止時間判定に含める）」に変更 |
| 状態管理 | 適合/不適合の2値判定のみだった | 全ての技術・時間判定ノードを**適合／不適合／未確認**の3状態に変更。未確認は除外せず「条件付き候補・PoC確認事項」として保持 |

```mermaid
flowchart TD
    Start([移行方式選定プロセス開始<br/>※4方式は基本分類。ZDM Hybrid等<br/>単純分類できない方式もあり得る]) --> Q0

    Q0[要件収集<br/>・許容停止時間（数値）<br/>・Data loss要件（全候補共通の必須要件）<br/>・Source/Target構成・Version・Edition・RU<br/>・移行対象範囲（Schema/Object種別）<br/>・費用制約<br/>・切戻し要件（Cutover前/後を区別）]

    Q0 --> TechPhysicalBase
    Q0 --> TechLogicalBase

    %% ===== Physical系：基盤適合性 =====
    TechPhysicalBase{Physical系 基盤適合性<br/>（Online/Offline共通の前提）<br/>・Platform/Storage互換<br/>・Version/Edition/RU条件<br/>（利用ツール固有の制約を確認）<br/>・RMAN/転送方式の基本要件}

    TechPhysicalBase -->|不適合| PhysicalAllExcluded[Physical Online/Offline<br/>両方とも候補から除外<br/>※基盤条件のため方式変更では解消しない]
    TechPhysicalBase -->|未確認| PhysicalBaseConditional[Physical系 条件付き候補<br/>PoC確認事項:基盤条件の実機検証]
    TechPhysicalBase -->|適合| PhysicalOfflineCheck
    PhysicalBaseConditional --> PhysicalOfflineCheck
    TechPhysicalBase -->|適合| PhysicalOnlineCheck
    PhysicalBaseConditional --> PhysicalOnlineCheck

    PhysicalOfflineCheck{Physical Offline<br/>停止時間判定<br/>停止中に必要な全作業<br/>（復元+リカバリ+Redo適用+<br/>Object再作成+検証+接続切替）<br/>が許容停止時間内か<br/>※事前コピー分は停止時間から除外}
    PhysicalOfflineCheck -->|適合| CandPhysicalOffline[候補: Physical Offline]
    PhysicalOfflineCheck -->|未確認| CandPhysicalOfflineCond[条件付き候補: Physical Offline<br/>PoC確認事項:実停止時間の実測]
    PhysicalOfflineCheck -->|不適合| PhysicalOfflineExcluded[Physical Offlineのみ<br/>候補から除外<br/>※Physical Onlineは独立評価]

    PhysicalOnlineCheck{Physical Online<br/>方式固有条件<br/>・移行用Data Guard等を<br/>構成可能か<br/>・利用ツール（ZDM等）の<br/>Online対応条件を満たすか<br/>・Network帯域でRedo追従可能か<br/>+ 切替時停止時間判定<br/>（更新停止+最終同期+検証+<br/>接続切替+業務再開が<br/>許容停止時間内か）}
    PhysicalOnlineCheck -->|適合| CandPhysicalOnline[候補: Physical Online<br/>※短時間Downtime<br/>（ゼロ停止ではない）]
    PhysicalOnlineCheck -->|未確認| CandPhysicalOnlineCond[条件付き候補: Physical Online<br/>PoC確認事項:同期追従性能/切替時間の実測]
    PhysicalOnlineCheck -->|不適合| PhysicalOnlineExcluded[Physical Onlineのみ<br/>候補から除外<br/>※Physical Offlineは独立評価]

    %% ===== Logical系：基盤適合性 =====
    TechLogicalBase{Logical系 基盤適合性<br/>（Online/Offline共通の前提）<br/>・移行対象Object種別が<br/>ツールでサポートされるか<br/>・Schema/権限/DB Link等の<br/>変換可否}

    TechLogicalBase -->|不適合| LogicalAllExcluded[Logical Online/Offline<br/>両方とも候補から除外<br/>※対象範囲縮小/Target見直し/<br/>個別移行の要否を別途検討]
    TechLogicalBase -->|未確認| LogicalBaseConditional[Logical系 条件付き候補<br/>PoC確認事項:変換可否の実機検証]
    TechLogicalBase -->|適合| LogicalOfflineCheck
    LogicalBaseConditional --> LogicalOfflineCheck
    TechLogicalBase -->|適合| LogicalOnlineCheck
    LogicalBaseConditional --> LogicalOnlineCheck

    LogicalOfflineCheck{Logical Offline<br/>停止時間判定<br/>停止中に必要な全作業<br/>（Export/Import相当処理+<br/>Index/制約再作成+検証+<br/>接続切替）が許容停止時間内か}
    LogicalOfflineCheck -->|適合| CandLogicalOffline[候補: Logical Offline]
    LogicalOfflineCheck -->|未確認| CandLogicalOfflineCond[条件付き候補: Logical Offline<br/>PoC確認事項:実停止時間の実測]
    LogicalOfflineCheck -->|不適合| LogicalOfflineExcluded[Logical Offlineのみ<br/>候補から除外<br/>※Logical Onlineは独立評価]

    LogicalOnlineCheck{Logical Online<br/>同期網羅性・性能判定<br/>・更新データが同期可能か<br/>・非対応分は停止中の個別移行等で<br/>補完できるか（補完時間も<br/>停止時間判定に含める）<br/>・変更量に対する追従性能<br/>+ 切替時停止時間判定<br/>（更新停止+最終差分適用+<br/>整合性確認+接続切替+業務再開が<br/>許容停止時間内か）}
    LogicalOnlineCheck -->|適合| CandLogicalOnline[候補: Logical Online<br/>※短時間Downtime<br/>（ゼロ停止ではない）]
    LogicalOnlineCheck -->|未確認| CandLogicalOnlineCond[条件付き候補: Logical Online<br/>PoC確認事項:同期網羅性/切替時間の実測]
    LogicalOnlineCheck -->|不適合| LogicalOnlineExcluded[Logical Onlineのみ<br/>候補から除外<br/>※Logical Offlineは独立評価]

    %% ===== 全方式の評価完了を待って集約 =====
    PhysicalAllExcluded --> Aggregate
    CandPhysicalOffline --> Aggregate
    CandPhysicalOfflineCond --> Aggregate
    PhysicalOfflineExcluded --> Aggregate
    CandPhysicalOnline --> Aggregate
    CandPhysicalOnlineCond --> Aggregate
    PhysicalOnlineExcluded --> Aggregate
    LogicalAllExcluded --> Aggregate
    CandLogicalOffline --> Aggregate
    CandLogicalOfflineCond --> Aggregate
    LogicalOfflineExcluded --> Aggregate
    CandLogicalOnline --> Aggregate
    CandLogicalOnlineCond --> Aggregate
    LogicalOnlineExcluded --> Aggregate

    Aggregate[全方式（4通り）の評価完了<br/>候補一覧を集約<br/>（正規候補＋条件付き候補を含む）]

    Aggregate --> CheckAnyCandidate{候補（条件付き候補を含む）が<br/>1つ以上残っているか}

    CheckAnyCandidate -->|No: 候補なし| Reassess[要件・方式の再検討<br/>・許容停止時間の緩和<br/>・対象範囲の見直し<br/>・段階移行/Hybrid方式の検討<br/>・Target構成の見直し]
    Reassess --> Q0

    CheckAnyCandidate -->|Yes| CommonGate[共通比較ゲート<br/>残存候補（条件付き含む）すべてで評価<br/>・Application影響<br/>・移行対応作業量<br/>・運用負荷（監視/切戻し体制）<br/>・費用<br/>・切戻し可否<br/>　- Cutover前: Source側で復旧可能か<br/>　- Cutover後: Target更新データを<br/>　  Sourceへ戻す手段があるか<br/>・Data loss要件充足性（全候補共通の必須要件）]

    CommonGate --> RequireCheck{必須要件<br/>（Data loss要件等）を<br/>満たす候補が<br/>残っているか}

    RequireCheck -->|No| Reassess

    RequireCheck -->|Yes| Provisional[暫定推奨方式を選定<br/>Assessment Report記載事項:<br/>・選定根拠<br/>・前提条件<br/>・未確認/要検証事項（条件付き候補分を含む）<br/>を明記した上で「暫定」とする]

    Provisional --> Validate{PoC / Migration Rehearsalで<br/>実測検証<br/>・Offline: 実停止時間<br/>・Online: 同期遅延/切替時間<br/>・Rollback手順<br/>・Data整合性<br/>・未確認事項（条件付き候補分）の検証}

    Validate -->|検証OK| Confirm[実施方式として確定]

    Validate -->|検証NG| ReflectResult{検証結果を候補評価へ反映<br/>再評価可能な候補が<br/>残っているか}

    ReflectResult -->|Yes| CommonGate
    ReflectResult -->|No| Reassess

    Confirm --> End([移行方式 決定])

    style CandPhysicalOnline fill:#d4edda,stroke:#28a745,stroke-width:2px
    style CandPhysicalOffline fill:#d1ecf1,stroke:#17a2b8,stroke-width:2px
    style CandLogicalOnline fill:#fff3cd,stroke:#b8860b,stroke-width:2px
    style CandLogicalOffline fill:#f8d7da,stroke:#dc3545,stroke-width:2px
    style CandPhysicalOnlineCond fill:#e2e3e5,stroke:#28a745,stroke-width:1px,stroke-dasharray: 4 2
    style CandPhysicalOfflineCond fill:#e2e3e5,stroke:#17a2b8,stroke-width:1px,stroke-dasharray: 4 2
    style CandLogicalOnlineCond fill:#e2e3e5,stroke:#b8860b,stroke-width:1px,stroke-dasharray: 4 2
    style CandLogicalOfflineCond fill:#e2e3e5,stroke:#dc3545,stroke-width:1px,stroke-dasharray: 4 2
    style Provisional fill:#fff3cd,stroke:#b8860b,stroke-width:2px
    style Confirm fill:#d4edda,stroke:#28a745,stroke-width:2px
    style PhysicalAllExcluded fill:#f1f1f1,stroke:#888,stroke-width:1px
    style LogicalAllExcluded fill:#f1f1f1,stroke:#888,stroke-width:1px
    style PhysicalOfflineExcluded fill:#f1f1f1,stroke:#888,stroke-width:1px
    style PhysicalOnlineExcluded fill:#f1f1f1,stroke:#888,stroke-width:1px
    style LogicalOfflineExcluded fill:#f1f1f1,stroke:#888,stroke-width:1px
    style LogicalOnlineExcluded fill:#f1f1f1,stroke:#888,stroke-width:1px
```

## 3状態管理（適合／不適合／未確認）の運用ルール

| 状態 | 意味 | 図上の扱い |
| --- | --- | --- |
| 適合 | Input（ヒアリング・Assessment結果）で条件充足が確認できた | 正規候補として共通比較ゲートへ進む |
| 不適合 | Inputで条件不充足が明確に確認できた | 原則としてその方式（基盤条件の場合は系統全体）を候補から除外する |
| 未確認 | Inputだけでは判定できない（実測・詳細調査が必要） | **除外せず「条件付き候補」として残す**。PoC/Rehearsalでの確認事項として明記し、共通比較ゲート・暫定推奨に含める |

未確認判定が多い場合、暫定推奨は「条件付き候補を含む」ことを明記し、Assessment Reportでは
「本方式は◯◯の実測結果次第で適合性が変わる」といった留保付きの表現を用いる。

## 推奨する判断順序（骨格は v2 から変更なし）

1. **要件収集**：許容停止時間、Data loss要件、Source/Target構成、移行対象範囲、費用、切戻し要件（Cutover前後）
2. **技術適合性で候補抽出**：Physical／Logicalそれぞれの**基盤条件**と、Online/Offline個別の**方式固有条件**を分けて確認（適合／不適合／未確認の3状態）
3. **停止時間・同期性能で絞り込み**：Offlineは停止中作業の総所要時間、Onlineは同期網羅性・追従性能に加え切替時停止時間で判定
4. **全方式の評価完了を待って候補を集約**：一部方式の不適合だけで打ち切らない
5. **共通比較**：Application影響、対応作業量、運用負荷、費用、切戻し（Cutover前後）を残存候補（条件付き含む）すべてで比較し、Data loss等の必須要件充足性を確認
6. **暫定推奨 → PoC／Rehearsal → 実施方式確定**：検証NGの場合は再評価可能な候補があれば共通比較ゲートへ戻り、候補が尽きれば要件・方式の再検討（Q0）へ

## Assessment Report活用時の注意（v2から継続）

- 実測前の「暫定推奨方式」を提示する場合は、**選定根拠・前提条件・未確認/要検証事項**（条件付き候補を含む）を必ず併記し、
  確定推奨と区別できる表現（例：「有力候補」「条件付き候補」「追加評価が必要」）を用いる。
- Online方式は「ゼロDowntime」ではなく「短時間Downtime」であることを明記し、
  完全無停止（真のゼロDowntime）を求める場合はApplication側のアーキテクチャ（Blue/Green等）を
  含めた別途検討が必要である旨を注記する。
- 4方式の基本分類に加え、ZDMのHybrid方式（RMAN + Data Pump）など、
  単純に分類できない方式が存在し得ることを明記する。
- 系統共通の基盤条件（Platform/Endian/Version/Edition/RU等）と、
  Online固有の方式条件（Data Guard対応、同期性能等）は明確に区別して記載する。

## 参考（Oracle公式ドキュメント）

- 移行・切替手順（Downtimeの実態）: https://docs.oracle.com/en/database/oracle/zero-downtime-migration/21.4/zdmug/migrating-with-zero-downtime-migration.html
- Physical移行の前提条件（Edition/Version/RU等のツール固有制約）: https://docs.oracle.com/en/database/oracle/zero-downtime-migration/26.1/zdmug/preparing-for-database-migration.html
- 移行方式一覧（Hybrid方式を含む）: https://docs.oracle.com/en/database/oracle/zero-downtime-migration/26.1/zdmug/introduction-to-zero-downtime-migration.html
