# Oracle Database移行方式 選定 汎用判断フロー（Mermaid）

特定案件のAssessment結果（実測値）を前提とせず、**要件Input収集前でも使える汎用の意思決定フレームワーク**です。
Physical Online / Physical Offline / Logical Online / Logical Offlineの4方式のうち、
どれを推奨方式とするかを、技術適合性・Downtime・Data Size・Application影響・移行複雑度・
Data loss要件・Rollback／運用複雑度の7観点で段階的に絞り込みます。

各Decisionノードの分岐条件は、実際の案件でヒアリング・Assessmentにより確定させることを前提とした
「確認すべき問い」として設計しています。

```mermaid
flowchart TD
    Start([移行方式選定プロセス開始]) --> Q0[要件・制約をヒアリング/Assessmentで収集<br/>Downtime許容時間 / Data Size / Data loss要件<br/>Source-Target互換性 / Application依存関係<br/>運用・Rollback要件]

    Q0 --> Q1{Q1. Downtimeは<br/>許容できるか<br/>（十分な停止時間がある）}

    %% Downtime許容 → Offline系
    Q1 -->|Yes: 十分なDowntime<br/>Windowが確保できる| Q2Offline{Q2. Source/Targetの<br/>Physical方式技術要件を<br/>満たすか<br/>（同一Endian/Version互換/<br/>ARCHIVELOG等）}

    Q2Offline -->|Yes| Q3OfflineSize{Q3. Data Sizeに対して<br/>許容Downtime内で<br/>Full転送が完了するか}
    Q3OfflineSize -->|Yes| CandPhysicalOffline[候補: Physical Offline Migration]
    Q3OfflineSize -->|No: 転送時間が<br/>Windowを超える| Q2LogicalOffline

    Q2Offline -->|No: Physical要件<br/>不適合<br/>（異Endian/非互換 等）| Q2LogicalOffline{Q4. Logical方式で<br/>Schema/Object/権限/<br/>DB Link等の変換が<br/>許容できるか}

    Q2LogicalOffline -->|Yes| CandLogicalOffline[候補: Logical Offline Migration]
    Q2LogicalOffline -->|No: 変換対象が<br/>広範/リスク大| ReviewOffline[Offline系は不適合<br/>Online系を再検討]
    ReviewOffline --> Q1Online

    %% Downtime不許容 → Online系
    Q1 -->|No: Downtimeを<br/>最小化する必要がある<br/>（ゼロ/短時間Downtime要件）| Q1Online{Q5. Data loss要件は<br/>ゼロ（許容不可）か}

    Q1Online --> Q6Tech{Q6. Source/Targetが<br/>Physical Online方式の<br/>技術前提を満たすか<br/>（Redo適用可否/HA構成/<br/>Network帯域確保）}

    Q6Tech -->|Yes| Q7Complexity{Q7. Application影響・<br/>移行複雑度・Rollback/<br/>運用複雑度は許容範囲か<br/>（切替手順・監視体制等）}

    Q7Complexity -->|Yes| CandPhysicalOnline[候補: Physical Online Migration]
    Q7Complexity -->|No: 複雑度/運用負荷が<br/>過大| Q8LogicalOnline

    Q6Tech -->|No: Physical Online<br/>技術前提を満たさない<br/>（異バージョン/Storage非互換等）| Q8LogicalOnline{Q8. Logical Online方式<br/>（GoldenGate等）で<br/>Data lossゼロの<br/>継続同期が実現できるか}

    Q8LogicalOnline -->|Yes| CandLogicalOnline[候補: Logical Online Migration]
    Q8LogicalOnline -->|No: 同期方式が<br/>要件を満たせない| Reassess[要件再定義が必要<br/>（Downtime緩和/段階移行/<br/>Hybrid方式等を再検討）]

    %% PoC/Rehearsal common gate
    CandPhysicalOffline --> Validate
    CandLogicalOffline --> Validate
    CandPhysicalOnline --> Validate
    CandLogicalOnline --> Validate

    Validate{PoC / Migration Rehearsalで<br/>候補方式を実測検証<br/>（転送時間・Cutover時間・<br/>Rollback手順・Data整合性）}

    Validate -->|検証OK| Confirm[推奨方式として確定]
    Validate -->|検証NG| Reselect[他候補を再評価<br/>または要件を見直し]

    Reselect --> Q0
    Reassess --> Q0

    Confirm --> End([移行方式 決定])

    style CandPhysicalOnline fill:#d4edda,stroke:#28a745,stroke-width:2px
    style CandPhysicalOffline fill:#d1ecf1,stroke:#17a2b8,stroke-width:2px
    style CandLogicalOnline fill:#fff3cd,stroke:#b8860b,stroke-width:2px
    style CandLogicalOffline fill:#f8d7da,stroke:#dc3545,stroke-width:2px
    style Confirm fill:#d4edda,stroke:#28a745,stroke-width:2px
```

## 各Decisionノードの意図

| ノード | 確認する内容 | 主に効く評価観点 |
| --- | --- | --- |
| Q1 | Downtime Windowの有無（業務停止を許容できるか） | Downtime |
| Q2 (Offline) | Physical方式の技術前提（Platform/Endian/Version/ARCHIVELOG等）を満たすか | 技術適合性 |
| Q3 (Offline) | Data SizeとDowntime Windowから見た転送実現性 | Data Size, Downtime |
| Q4 | Logical方式でのSchema/Object/権限変換が許容範囲か | 移行複雑度, Application影響 |
| Q5 | Data loss要件（ゼロロス必須か） | Data loss要件 |
| Q6 | Physical Online方式の技術前提（Redo適用、HA、Network帯域） | 技術適合性 |
| Q7 | Application影響・移行複雑度・Rollback／運用複雑度が許容範囲か | Application影響, 移行複雑度, Rollback/運用複雑度 |
| Q8 | Logical Online（GoldenGate等）でゼロロス継続同期が実現できるか | Data loss要件, 技術適合性 |
| Validate | PoC/Rehearsalによる実測検証（最終ゲート） | 全観点の実証 |

## 使い方

1. **Q0で要件・制約をInputとして収集**します（本フローはInput収集前の思考の出発点として使用し、実際の判断にはヒアリング・Assessment結果が必要です）。
2. Downtime許容度（Q1）を起点に、Offline系／Online系へ大きく分岐します。
3. 各系統の中で、技術適合性→Data Size／Data loss→複雑度・運用性の順に絞り込みます。
4. 最終的に1つ以上の候補方式が残った場合、**PoC / Migration Rehearsalでの実測検証**を経てから初めて「推奨方式」として確定します（実測前の段階では有力候補に留めます）。
5. 検証で要件を満たせない場合は、他候補の再評価または要件自体の見直し（Downtime緩和、段階移行、Hybrid方式等）にフィードバックします。

この汎用フローは、今回のPRODDB案件のような具体的な数値（1.2TB、2時間等）を含まない形にしており、他のOracle Database移行案件でも共通の判断ロジックとして再利用できます。
