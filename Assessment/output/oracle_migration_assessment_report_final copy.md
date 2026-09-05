# Oracle Database 移行アセスメント報告書

## Oracle Migration Assessment Report

---

## 1. Assessment結果サマリー

### 1.1 本Assessmentの目的

本Assessmentでは、対象となるOracle Database環境について、現行環境、移行先環境との互換性、移行方式、移行に伴うリスクおよび事前対応事項を確認し、今後の移行方針を整理します。Oracle標準のAssessment Toolによる結果に加え、ヒアリング結果、Database構成、Application依存関係および運用要件を確認しています。

### 1.2 総合評価

| 評価項目 | 評価 | 評価概要 |
| ------ | ------ | ------ |
| 移行実現性 | Amber | Source/TargetはいずれもOracle Database 19c Enterprise Editionです。明示的なMigration Blockerは確認されていませんが、Target HA、Rollback、Rehearsalおよび切替条件は要確認です。 |
| 互換性 | Amber | CPATおよびDMSでReview RequiredまたはReview Suggestedの事項が確認されています。重大な非互換はInput上確認されていません。 |
| 移行準備状況 | Amber | 権限、Timezone、Target構成、Security review、Migration rehearsal等に未確認または未完了の事項があります。 |
| 移行複雑度 | Medium～High / 追加評価が必要 | 1.2 TBのDatabase、Application・外部依存関係、2時間のDowntime制約およびRollback要件を踏まえた判断です。実測結果は未確認です。 |
| 業務影響 | High | Production Databaseが対象で、Downtimeは最大2時間、Data lossは許容されません。Application、Batch、DB Linkおよび外部Interfaceの確認が必要です。 |
| 総合判定 | 条件付き移行可能 | 優先度の高い事前対応事項、Target構成確認、PoC/RehearsalおよびGo/No-Go判定を完了することを条件とします。 |

### 1.3 Assessment結果の要点

* SourceおよびTargetはいずれもOracle Database 19c Enterprise Editionです。
* CPATおよびDMSにはReview RequiredまたはReview Suggestedの事項があります。
* 明示的なMigration Blocker、Critical FindingまたはData loss発生の記載はInput上確認されていません。
* Users Privilege、Non-Exported Object GrantsおよびTimezone Versionは移行前の確認または対応が必要です。
* Scheduler Job、Resource Manager PlanおよびDuplicate IndexesはReview Suggestedとして確認が必要です。
* CPATのSchema数52件とDatabase Inventoryの28件の差異は、Compatibility IssueではなくAssessment確認事項として扱います。
* Physical Online Migrationは有力候補ですが、Target構成、Network、HA、Rollback、Cutover時間およびMigration Rehearsalの結果を踏まえて確定します。現時点では推奨確定しません。

### 1.4 推奨方針

特定の方式を現時点で推奨確定することはできません。Source/Targetの互換性、Data Size、Downtime、Application影響、Data loss要件、Rollbackおよび運用複雑度を検証し、**Physical Online Migrationを有力候補として追加評価**することを推奨します。

本番移行前には、Target HA/DR、権限、Timezone、Scheduler、Network、Security、Schema数差異、RollbackおよびRehearsalの確認を完了してください。

---

# 2. Assessmentの対象・前提条件

## 2.1 Assessment対象

| 項目 | 内容 |
| --- | --- |
| 対象システム | Sales Management System |
| 対象Database | PRODDB（DB Unique Name: PRODDB） |
| 対象環境 | Production |
| Source Platform | Oracle Database 19c Enterprise Edition / Oracle Linux 8 / CDB Single Instance |
| Target Platform | Oracle Database@Azure（Japan East） |
| Assessment実施日 | 未確認 |
| Assessment対象Version | Source: Oracle Database 19c RU 19.23、Target: Oracle Database 19c（Target RUは未確認） |

## 2.2 Assessment範囲

### 対象範囲

* Oracle Database構成情報の確認
* Database Version / Edition / Patch Levelの確認
* Database Size / Schema / Objectの確認
* Character Set / NLS設定の確認
* 使用FeatureおよびOptionの確認
* 移行先環境とのCompatibility評価
* Oracle標準Assessment Toolによる分析
* 移行方式の比較・評価
* Network、Security、運用前提条件の確認
* Migration Risk / Constraintの整理
* 移行前に必要なRemediationの整理
* High-Level Migration Planの策定

### 対象外

以下は本Assessmentの対象外とし、必要に応じて後続工程で詳細化します。

* Application改修設計
* 本番Migration作業
* Detailed Migration Runbook
* 分単位のCutover Plan
* Performance Tuning
* Detailed HA / DR Design
* Application Functional Test
* 詳細Rollback Procedure

---

# 3. Assessment実施方法

## 3.1 Assessmentで利用する情報

* 顧客ヒアリングシート
* Database Inventory
* Oracle Database設定情報
* SQL / Data Dictionaryの確認結果
* CPAT Assessment結果
* Oracle Database Migration Service Assessment結果
* Target Environment情報
* Application / Interface / Batch依存関係
* Security / Network要件
* 運用要件
* 顧客固有の移行制約・標準ルール

## 3.2 使用するAssessment Tool

| Tool | 主な利用目的 |
| --- | --- |
| Oracle Cloud Premigration Advisor Tool（CPAT） | Oracle Databaseの移行互換性・事前課題の確認 |
| Oracle Database Migration Service Assessment | DMSを利用した移行時の互換性・移行固有条件の確認 |
| SQL / Data Dictionary Query | Database構成・Object・Feature等の確認 |
| Additional Validation Script | 標準Toolで確認できない顧客固有条件の確認 |

## 3.3 Assessmentの進め方

1. 現行環境および移行要件の確認
2. Database Inventoryの整理
3. Oracle標準ToolによるCompatibility Assessment
4. 移行先環境とのFit / Gap確認
5. 移行方式の比較・評価
6. Risk / Constraintの整理
7. Remediation事項の整理
8. 推奨移行方針の策定
9. High-Level Migration Planの策定

---

# 4. 現行環境の整理

## 4.1 Database構成

| 項目 | 現行環境 |
| --- | --- |
| Database Name | PRODDB |
| DB Unique Name | PRODDB |
| Oracle Database Version | Oracle Database 19c |
| Edition | Enterprise Edition |
| Release Update / Patch | 19.23 |
| OS / Version | Oracle Linux 8 |
| Database Size | 1.2 TB |
| Character Set | AL32UTF8 |
| NCHAR Character Set | AL16UTF16 |
| CDB / Non-CDB | CDB |
| PDB数 | 3 |
| Single Instance / RAC | Single Instance |
| ARCHIVELOG | Enabled |
| FORCE LOGGING | Enabled |
| TDE | Enabled |
| Data Guard | No |
| GoldenGate | No |
| ASM | Yes |

## 4.2 Database利用状況

| 項目 | 内容 |
| --- | --- |
| Schema数 | 28（CPAT結果は52件。差異はAssessment確認事項） |
| Table数 | 4,820 |
| Index数 | 6,300 |
| 最大Table Size | 未確認 |
| Daily Data Growth | 5 GB |
| Peak Transaction | 未確認 |
| Batch Window | 01:00-04:00 |
| Backup方式 | RMAN |
| Maintenance Window | Sunday 01:00-05:00 |

## 4.3 Application・外部依存関係

| 項目 | 内容 | Migrationへの影響 |
| --- | --- | --- |
| Application | Sales Management Application | Database接続先切替および移行後確認が必要 |
| Middleware | WebLogic Server | 接続先、接続情報および再接続動作は要確認 |
| Batch / Scheduler | Scheduled Batch 35件、Enabled Scheduler Jobs 21件 | 停止・再開、重複実行防止および結果確認が必要 |
| DB Link | 4件 | 接続先、認証および切替要否は要確認 |
| External Interface | 6件 | 停止時間、接続先切替およびデータ整合性は要確認 |
| File Transfer | SFTP | 接続先、認証および切替影響は要確認 |
| Monitoring | Existing enterprise monitoring platform | Target監視登録および監視項目は要確認 |
| Backup | RMAN | TargetのOracle managed backupとの復旧手順・Policy整合性は要確認 |
| DR | Data Guardなし | Target DRはTo be designed。RPO/RTOおよび構成は要確認 |
| External Authentication | 未確認 | 使用有無および移行後の認証動作は要確認 |

---

# 5. 移行先環境および前提条件

## 5.1 Target Environment概要

| 項目 | 内容 |
| --- | --- |
| Target Platform | Oracle Database@Azure |
| Oracle Database Version | Oracle Database 19c |
| Edition | Enterprise Edition |
| Region | Japan East |
| HA構成 | High Availability Required。具体的な構成は要確認 |
| Backup方式 | Oracle managed backup |
| DR構成 | To be designed |
| Network Connectivity | Azure VNet connectivity。帯域、遅延および接続設計は要確認 |
| Security Requirement | Security review完了が必要。詳細要件は未確認 |
| Monitoring | 未確認 |
| Operation Model | 未確認 |

## 5.2 Source / Target差分評価

| 評価項目 | Source | Target | 影響 | 対応要否 |
| --- | --- | --- | --- | --- |
| Oracle Version | 19c | 19c | Version差異は確認されない。Target RUは未確認 | 要確認 |
| Edition | Enterprise Edition | Enterprise Edition | Edition差異は確認されない | Target構成は要確認 |
| Character Set | AL32UTF8 / AL16UTF16 | 未確認 | 互換性は判断不可 | 要確認 |
| Database Feature | CDB、3 PDB、ASM、TDE、ARCHIVELOG、FORCE LOGGING | 詳細未確認 | Feature/Optionの適用可否は追加評価が必要 | 要確認 |
| OS / Platform | Oracle Linux 8 | Oracle Database@Azure | Platform差異による構成・運用差異は追加評価が必要 | 要確認 |
| Storage | ASM、容量・性能詳細未確認 | 容量・性能詳細未確認 | 1.2 TBおよび増加量を満たす設計確認が必要 | 要確認 |
| Network | Source側詳細未確認 | Azure VNet connectivity | 初期転送、差分同期、DB Link等の通信確認が必要 | 要確認 |
| Security | TDE Enabled | TDE Enabled | TDE有効性は一致。Key管理・Security reviewは要確認 | 要確認 |
| Backup | RMAN | Oracle managed backup | Backup方式および復旧運用が変更される | 要確認 |
| HA / DR | Single Instance、Data Guardなし | HA Required、DR To be designed | Target要件を満たす方式・RPO/RTOは追加評価が必要 | 必須 |
| Monitoring | Enterprise monitoring platform | 未確認 | Target監視および運用連携は要確認 | 要確認 |

---

# 6. 互換性評価結果

## 6.1 Compatibility評価概要

| 判定 | 件数 | 説明 |
| --- | ---: | --- |
| Critical | Input上の記載なし | 重大な影響を与える事項は確認されていません |
| Review Required | CPAT 3項目、DMS 1項目（重複を含む） | 移行前に対応または詳細確認が必要な事項 |
| Review Suggested | CPAT 1項目、DMS 3項目（重複を含む） | 対応を推奨する事項 |
| Informational | 未確認 | 情報確認を目的とする事項 |
| Passed | 未確認 | 問題が確認されなかった事項 |

※ CPATとDMSで重複するNon-Exported Object GrantsおよびEnabled Scheduler Jobsは、主要Findingでは統合して整理しています。上記件数はToolの表示単位であり、実体数を示すものではありません。

## 6.2 主要Finding

| ID | Finding | Severity | Migrationへの影響 | 推奨対応 |
| --- | --- | --- | --- | --- |
| COMP-001 | Users Privilege（16件） | Amber（Review Required） | 権限不足等によりApplication・運用アクセスに影響する可能性があります | User、Role、System/Object Privilegeを棚卸しし、移行後権限を確認します |
| COMP-002 | Non-Exported Object Grants（6件） | Amber（Review Required） | Object Grantが完全に移行されず、アクセス障害につながる可能性があります | 対象Grantを確認し、必要なGrantの再作成手順を定義します |
| COMP-003 | Timezone Version（1件） | Amber（Review Required） | 日時データまたはTimezone依存処理に差異が生じる可能性があります | Source/TargetのTimezone VersionとApplication影響を確認します |
| COMP-004 | Enabled Scheduler Jobs（21件） | Amber（Review Suggested） | 移行中または移行直後に誤実行・重複実行する可能性があります | 停止・再開、実行抑止時間および結果確認を定義します |
| COMP-005 | Resource Manager Plan | Amber（Review Suggested） | Target設定との差異により、処理性能またはBatch時間に影響する可能性があります | Source/Target設定を比較し、適用可否を検証します |
| COMP-006 | Duplicate Indexes | Amber（Review Suggested） | 直接のMigration Blockerではありませんが、不要Indexの確認が必要です | Migration前後で必要性を確認します |

## 6.3 CPAT評価結果

| Check項目 | Result | 影響 | 推奨対応 |
| --- | --- | --- | --- |
| Users Privilege | Review Required（16件） | ユーザー権限の確認が必要です | 権限一覧を確認し、移行後権限を確定します |
| Non-Exported Object Grants | Review Required（6件） | Object Grantが完全に移行されない可能性があります | DMS結果と統合して対象Grantを確認します |
| Timezone Version | Review Required（1件） | Timezone依存処理・データへの影響確認が必要です | Source/TargetのTimezone Versionを確認します |
| Enabled Scheduler Jobs | Review Suggested（21件） | Jobの誤実行・重複実行の可能性があります | DMS結果と統合して停止・再開手順を定義します |
| CPAT対象Schema数 | 52 | Inventoryの28件との差異はCompatibility Issueと断定できません | 対象範囲、取得時点およびSchema一覧をAssessment確認事項として確認します |

## 6.4 DMS Assessment評価結果

| Check項目 | Result | 影響 | 推奨対応 |
| --- | --- | --- | --- |
| Non-Exported Object Grants | Review Required | Privilegeが完全に移行されない可能性があります | CPAT結果と統合してGrantを棚卸しします |
| Duplicate Indexes | Review Suggested | 直接のMigration Blockerはありません | 必要性を確認し、対応時期を判断します |
| Enabled Scheduler Jobs | Review Suggested | 移行時にJobが予期せず実行される可能性があります | CPAT結果と統合して停止・再開手順を定義します |
| Resource Manager Plan | Review Suggested | Target設定の検証が必要です | Source/Target設定を比較・検証します |
| Overall Status | Review Required | 移行前の確認事項が残っています | 指摘事項への対応および追加評価を完了します |

## 6.5 Compatibilityに関する所見

* Users Privilege、Object GrantおよびTimezone Versionは本番移行前に確認または対応が必要です。
* Scheduler Jobは移行方式のBlockerではありませんが、停止・再開手順が必要です。
* Resource ManagerおよびDuplicate Indexesはレビュー事項です。
* CPATとDMSで重複するFindingは、同一または関連する確認事項として統合管理します。
* CPAT Schema 52件とInventory Schema 28件の差異は、Compatibility IssueではなくAssessment確認事項です。
* VersionおよびEditionは一致していますが、Character Set、Timezone、Feature、Target RU等は未確認です。
* 重大な非互換や明示的なMigration BlockerはInput上確認されていません。
* Application改修の要否、Data consistencyおよび実際のDowntimeへの影響は追加評価が必要です。

---

# 7. 移行方式の評価

## 7.1 評価方針

技術適合性、Downtime、Data Size、Application影響、移行複雑度、Data loss要件、Rollbackおよび運用複雑度を踏まえて比較します。Inputだけでは各方式の適用条件を確認できないため、特定方式を推奨確定しません。

## 7.2 移行方式比較

| 移行方式 | 適合性 | 想定Downtime | 複雑度 | 主なリスク | 評価 |
| --- | --- | --- | --- | --- | --- |
| Physical Online | 有力候補。ただし適用可否は未確認 | 2時間以内か追加評価が必要 | Medium～High / 追加評価が必要 | Network帯域、差分追随、HA、Rollback、切替時間 | PoC/Rehearsalで検証 |
| Physical Offline | 候補になり得るが適合性未確定 | 1.2 TBを含め2時間以内か追加評価が必要 | Medium / 追加評価が必要 | 停止時間超過、Rollback、Application依存関係 | 実測後に判断 |
| Logical Online | 代替候補 | 要追加評価 | High / 追加評価が必要 | Object、権限、Timezone、DB Link、整合性および切替複雑度 | Physical方式と比較検証 |
| Logical Offline | 適合性未確認 | Downtime要件との適合性は要確認 | Medium～High / 追加評価が必要 | 停止時間超過、Data consistency、Application停止影響 | 要件確認後に判断 |

## 7.3 現時点での有力な移行方式候補

**推奨方式：Physical Online Migrationを現時点での有力候補として追加評価**

### 推奨理由

* Source/TargetはいずれもOracle Database 19c Enterprise Editionです。
* SourceはARCHIVELOGおよびFORCE LOGGINGがEnabledです。
* Database Sizeは1.2 TB、Downtime上限は2時間、Data lossは許容されません。
* Application変更を最小化できる可能性があります。
* Oracle native migration toolsを優先する要件と整合する可能性があります。
* ただし、Target構成、Network、HA、Rollback、Cutover時間およびMigration Rehearsalの結果は未確認です。
* 適用可否はこれらの確認結果を踏まえて確定し、現時点では推奨確定しません。

### 代替方式

**代替方式：Physical Offline MigrationまたはLogical Online Migration（追加評価が必要）**

Physical Offline Migrationは、実測した停止時間が2時間以内で、RollbackおよびApplication切替要件を満たす場合に候補となります。Logical Online Migrationは、Physical方式が適用できない場合に、権限、Object、Timezone、DB LinkおよびData consistencyを含めて比較検証します。

---

# 8. 移行準備状況の評価

## 8.1 Readiness評価

| 評価領域 | Status | コメント |
| --- | --- | --- |
| Database Compatibility | Amber | Version/Editionは一致していますが、権限、Timezone、Object Grant等のReview Required事項があります |
| Target Environment | Amber | Oracle Database@Azure、19c、Enterprise Editionですが、HA/DR、Storage、Target RU等は要確認です |
| Network | Amber | Azure VNet connectivityは記載されていますが、帯域、遅延、転送時間および接続先は未確認です |
| Security | Amber | TDEはSource/TargetともEnabledです。Security review、Key管理および詳細要件は未確認です |
| Migration Tool | Amber | Native migration tools優先の要件はありますが、具体的なToolと適用可否は追加評価が必要です |
| Application Dependency | Amber | WebLogic、Batch 35件、DB Link 4件、External Interface 6件、SFTPおよびDNSの切替確認が必要です |
| Operation | Amber | Scheduler、Monitoring、Backup、運用手順および役割分担は未確認です |
| Backup / Recovery | Amber | SourceはRMAN、TargetはOracle managed backupです。復旧手順、Policy維持およびRollbackは要確認です |
| Cutover Preparation | Amber | Weekend cutover、Downtime 2時間、DNS switching、RehearsalおよびRollbackが必須ですが、手順・実測は未完了です |

## 8.2 総合Readiness

**総合判定：Amber**

### 判定理由

明示的なMigration Blocker、Critical Findingまたは重大な非互換はInput上確認されていません。一方、CPAT/DMSのReview Required事項、Target HA/DR、Network、Security、Application依存関係、RollbackおよびMigration rehearsalが未完了または未確認です。

Assessment Rulesに従い、BlockerがなくReview Requiredまたは追加確認事項があるため、総合ReadinessはAmberと判定します。優先度の高い事前対応事項と追加評価を完了することがProduction Migrationの前提条件です。

---

# 9. 主要リスク・制約事項

Assessmentで確認したRiskおよびConstraintについて、影響度と発生可能性を分けて整理します。Severityは、Inputだけで発生可能性を評価できない場合、「要評価」としています。

| ID | Risk / Constraint | 影響 | 発生可能性 | Severity | Mitigation |
| --- | --- | --- | --- | --- | --- |
| R-001 | Downtime上限2時間 | Cutoverが業務要件を超過する可能性があります | 要評価（実測未確認） | 要評価 | Rehearsalで初期転送、差分同期、停止・切替時間を測定します |
| R-002 | Data loss不可 | 同期・切替・Rollback不備が重大な業務影響につながる可能性があります | 要評価 | 要評価 | Data consistency、同期方式およびRollback手順を検証します |
| R-003 | Target HA/DR構成未確定 | Targetの可用性・復旧要件を満たせない可能性があります | 要評価 | 要評価 | HA方式、DR方式、RPO/RTOを設計・合意します |
| R-004 | Physical Online適用条件未確認 | 有力候補方式を採用できない可能性があります | 要評価 | 要評価 | Oracle Database@Azureの適用条件を確認し、代替方式も比較します |
| R-005 | 権限・Object Grantの確認不足 | Applicationまたは運用アクセスが失敗する可能性があります | 要評価 | 要評価 | User Privilege 16件とObject Grant 6件を棚卸し・検証します |
| R-006 | Timezone Version未確認 | 日時データや日時依存処理に差異が生じる可能性があります | 要評価 | 要評価 | Source/TargetのVersionとApplication影響を確認します |
| R-007 | Scheduler/Batchの誤実行 | 重複実行、データ不整合または処理失敗の可能性があります | 要評価 | 要評価 | Scheduler Job 21件とBatch 35件を整理し、停止・再開手順を検証します |
| R-008 | Application・外部依存関係 | DNS、WebLogic、DB Link、外部InterfaceまたはSFTPの切替失敗につながる可能性があります | 要評価 | 要評価 | 接続先、認証、切替手順および移行後確認を検証します |
| R-009 | CPAT/Inventory Schema数差異 | Assessment対象範囲の確認に追加作業が必要です | 要評価 | 要評価 | 52件と28件の一覧、取得時点および対象範囲を突合します |
| R-010 | Backup方式の変更 | 移行後の復旧性や既存Backup policyとの違いが生じる可能性があります | 要評価 | 要評価 | Oracle managed backupの復旧手順と既存Policy維持可否を検証します |

本表の「要評価」は、Riskが存在しないという意味ではなく、Inputだけでは発生可能性およびSeverityを確定できないことを示します。特に本番MigrationやCutover判断に影響する事項は、後続工程で継続管理します。

---

# 10. 移行前の対応事項

## 10.1 Remediation一覧

| ID | 対応事項 | Priority | Owner | 対応時期 | Status |
| --- | --- | --- | --- | --- | --- |
| A-001 | Target HA/DR構成、RPO/RTOおよび運用方式を確認・確定 | High | 要確認 | 本番設計前 | 未確認 |
| A-002 | Physical Onlineを含むMigration方式の適用可否を確認 | High | 要確認 | PoC前 | 未確認 |
| A-003 | Network帯域、接続性、転送時間およびAzure VNet経路を確認 | High | 要確認 | PoC前 | 未確認 |
| A-004 | User Privilege 16件およびNon-Exported Object Grants 6件を棚卸し | High | 要確認 | 本番移行前 | Review Required |
| A-005 | Source/TargetのTimezone VersionとApplication影響を確認 | High | 要確認 | 本番移行前 | Review Required |
| A-006 | Scheduler Job 21件とBatch 35件の停止・再開手順を定義 | High | 要確認 | Rehearsal前 | Review Required |
| A-007 | Data lossなしの同期、Data validationおよびRollback procedureを検証 | High | 要確認 | Rehearsal前 | 未確認 |
| A-008 | Migration rehearsalを実施し、2時間以内のCutover可否を測定 | High | 要確認 | 本番移行前 | 必須・未実施 |
| A-009 | CPAT Schema 52件とInventory Schema 28件の差異を確認 | Assessment継続事項 | 要確認 | Assessment継続中 | 要確認 |
| A-010 | DNS、WebLogic、DB Link 4件、External Interface 6件、SFTPの切替を確認 | High | 要確認 | Rehearsal前 | 未確認 |
| A-011 | Security review、TDE Key管理およびTarget Security要件を確認 | High | 要確認 | 本番移行前 | 未完了／未確認 |
| A-012 | Target Backup、復旧、Monitoringおよび既存Backup policy維持可否を確認 | Medium | 要確認 | Rehearsal前 | 未確認 |
| A-013 | Resource Manager PlanをTargetで検証 | Medium | 要確認 | Rehearsal前 | Review Suggested |
| A-014 | Duplicate Indexesの必要性を確認 | Low | 要確認 | 移行前後 | Review Suggested |

## 10.2 Priorityの考え方

**High**
本番Migration実施前に対応が必要な事項です。未対応の場合、Migration失敗や重大な影響につながる可能性があります。

**Medium**
Migration前の対応を推奨する事項です。Migration自体は可能でも、運用・性能・安定性等に影響する可能性があります。

**Low**
Migration後でも対応可能な改善事項、またはMigration可否への直接的な影響が小さい事項です。

**Assessment継続事項**
Input間の差異など、Compatibility Issueと断定せず、対象範囲や事実関係を確認する事項です。

---

# 11. 移行優先順位・Wave案

複数Databaseを対象とする場合、移行複雑度、業務影響、移行準備状況および依存関係を比較して移行順序を設定します。

| Database | Complexity | Business Impact | Readiness | Dependency | 推奨Wave |
| --- | --- | --- | --- | --- | --- |
| PRODDB | Medium～High / 追加評価が必要 | High | Amber | WebLogic、Batch、DB Link、External Interface、SFTP、DNS | 要確認 |
|  | Low / Medium / High |  |  |  | 要確認 |
|  |  |  |  |  | 要確認 |

本Assessmentの対象はPRODDB 1Databaseのみであり、他Databaseとの比較情報はありません。したがって、PRODDBのWave 1 / 2 / 3は現時点で確定しません。複数Databaseの業務影響、移行複雑度、移行準備状況および依存関係を比較したうえで決定する必要があります。

PRODDBはProduction Databaseであり、WebLogic、Batch、DB Link、External Interface、SFTPおよびDNSへの依存関係があります。また、Downtimeは2時間以内、Data lossは許容されず、Migration rehearsalが必須です。このため、十分なPoC/Rehearsalが必要ですが、これだけを根拠にWaveを確定するものではありません。

### Wave 1

比較的Riskが低く、標準的なMigration Patternを適用できるDatabaseを対象とします。Pilot Migrationとして実施し、移行手順や運用手順の標準化に活用します。

### Wave 2

Wave 1で確立したMigration Patternを適用し、標準的な業務Databaseを段階的に移行します。

### Wave 3

大規模、Mission Critical、複雑な依存関係を持つDatabaseを対象とし、十分なPoC/Rehearsalを実施したうえで移行します。PRODDBをこのWaveに分類するかは、他Databaseとの比較後に要確認です。

---

# 12. 移行計画案

## 12.1 基本的な進め方

Assessment結果を踏まえ、以下のPhaseでMigrationを進めることを推奨します。期間はテンプレート上の目安であり、本対象での実測結果ではありません。

| Phase | 主な実施内容 | 想定期間 | 主な成果物 |
| --- | --- | --- | --- |
| 1. Remediation | Compatibility課題、環境前提条件への対応 | 1～2週間 | Remediation結果 |
| 2. Migration Design | 移行方式、構成、Network、Security、Cutover方針の確定 | 1～2週間 | Migration Design |
| 3. PoC / Technical Validation | 移行方式、接続性、Performance等の技術検証 | 1～2週間 | PoC Result |
| 4. Migration Rehearsal | 実データに近い条件で移行手順、所要時間、Rollbackを確認 | 1週間 | Rehearsal Result |
| 5. Production Migration | 本番MigrationおよびCutover | 1～2日 | Migrated Database |
| 6. Post Migration Validation | Data、Application、Operation等の移行後確認 | 1～3日 | Validation Report |

## 12.2 主要Milestone

| Milestone | 完了条件 |
| --- | --- |
| Assessment完了 | 指摘事項、Riskおよび移行方式候補の合意 |
| Remediation完了 | High Priority事項の対応完了 |
| PoC完了 | 技術的な移行実現性を確認 |
| Rehearsal完了 | 移行時間、RunbookおよびRollback手順を確認 |
| Go / No-Go判定 | 本番Migration実施条件を満たしていること |
| Production Migration完了 | Data MigrationおよびCutover完了 |
| Validation完了 | Application、DataおよびOperationの正常性確認 |

## 12.3 本番移行前の主要判定項目

* 優先度の高い事前対応事項が完了していること
* Migration ToolおよびNetwork Connectivityが確認されていること
* Target Environmentが利用可能な状態であること
* Migration Rehearsalが完了していること
* Migration Runbookが承認されていること
* Application停止およびCutover時間が合意されていること
* Backup / Recovery / Rollback手順が確認されていること
* Go / No-Go判定基準が合意されていること

---

# 13. 今後の推奨アクション

| Priority | 推奨アクション | 目的 |
| --- | --- | --- |
| 1 | Assessment指摘事項の確認・合意 | 課題認識の共有 |
| 2 | 優先度の高い事前対応事項の実施 | Migration実施条件の整備 |
| 3 | Migration Architectureの確定 | 移行方式・構成の具体化 |
| 4 | Migration PoCの実施 | 技術的実現性の確認 |
| 5 | Migration Runbook作成 | 作業手順・役割・判定基準の明確化 |
| 6 | Migration Rehearsal | 本番移行前の最終検証 |
| 7 | Production Migration | 本番環境の移行 |
| 8 | Post Migration Validation | 移行後の正常性確認 |

優先度の高い事前対応事項、Architecture確定、PoCおよびRehearsalの結果をもとに、Physical Online Migrationを採用できるか判断します。採用できない場合は、代替方式を再評価します。

---

# 14. 総括

本Assessmentでは、対象Oracle Database環境について、現行構成、移行先環境とのCompatibility、移行方式、Risk、Remediationおよび移行準備状況を確認しました。

Assessment結果から、対象Databaseは、特定された事前対応事項への対応および必要な追加評価を実施することで、Oracle Database@Azureへの移行が可能と評価します。

SourceとTargetはいずれもOracle Database 19c Enterprise Editionであり、明示的なMigration Blockerや重大な非互換はInput上確認されていません。一方、CPAT/DMSのReview Required事項、Target HA/DR、Network、Security、Application依存関係、DowntimeおよびRollback条件は未確認または未完了です。そのため、移行準備状況はAmber、総合判定は条件付き移行可能とします。

Physical Online Migrationは現時点での有力候補ですが、推奨確定ではありません。Target構成、Network、HA、Rollback、Cutover時間およびMigration Rehearsalの結果を踏まえて、後続工程で方式を確定することを推奨します。

---

# Appendix A. Assessment Evidence

* 顧客ヒアリングシート（input/hearing_sheet.md）
* Database Inventory（input/db_inventory.md）
* CPAT Assessment Result（input/cpat_result.json）
* DMS Assessment Result（input/dms_assessment.md）
* SQL / Data Dictionary Query Result：Input上未提供
* Configuration Information：Input上未提供
* Target Environment Information（input/target_environment.md）
* Network / Security Information：概要のみ。詳細は要確認
* Application Dependency Information（input/hearing_sheet.md）

---

# Appendix B. Assessment Finding詳細

| ID | Tool | Check | Result | Evidence | Impact | Recommendation |
| --- | --- | --- | --- | --- | --- | --- |
| COMP-001 | CPAT | Users Privilege | Review Required（16件） | cpat_result.json | ユーザー権限の確認が必要 | 権限一覧を棚卸しし、移行後権限を確定 |
| COMP-002 | CPAT / DMS | Non-Exported Object Grants | Review Required（CPAT 6件、DMSで重複報告） | cpat_result.json / dms_assessment.md | Object Grantが完全に移行されない可能性 | 対象Grantを突合し、必要なGrantを再作成 |
| COMP-003 | CPAT | Timezone Version | Review Required（1件） | cpat_result.json | 日時データ・処理結果への影響可能性 | Source/TargetのTimezone Versionと影響を確認 |
| COMP-004 | CPAT / DMS | Enabled Scheduler Jobs | Review Suggested（CPAT 21件、DMSで重複報告） | cpat_result.json / dms_assessment.md | 移行中・移行直後の誤実行・重複実行 | 停止・再開および結果確認手順を定義 |
| COMP-005 | DMS | Resource Manager Plan | Review Suggested | dms_assessment.md | Target設定差異による性能・Batch影響の可能性 | Source/Target設定を比較・検証 |
| COMP-006 | DMS | Duplicate Indexes | Review Suggested | dms_assessment.md | 直接のMigration Blockerではないが、不要Indexの確認が必要 | 必要性を確認し、対応時期を判断 |
| AC-001 | CPAT / Database Inventory | Schema数 | CPAT 52、Inventory 28 | cpat_result.json / db_inventory.md | 対象範囲の確認に追加作業が必要 | Compatibility Issueと断定せず、一覧・取得時点・対象範囲を突合 |

---

# Appendix C. 前提条件・制約事項

本Assessmentは、Assessment実施時点で提供された情報および確認可能な環境をもとに実施しています。

* Target Environmentの仕様はAssessment実施時点の情報を使用しています。
* Source Database構成に変更があった場合、Assessment結果が変わる可能性があります。
* Target DatabaseのRelease Update、Character Set、Storage、Network帯域、HA/DR詳細、MonitoringおよびOperation Modelは未確認です。
* CPAT Schema数52件とDatabase Inventory Schema数28件の差異は、Assessment確認事項として扱っています。Compatibility IssueまたはHigh Priority Remediationとは断定していません。
* 明示的なMigration BlockerはInput上確認されていませんが、未確認事項の解消前に本番移行可否を確定することはできません。
* Physical Online Migrationは現時点での有力候補であり、Target構成、Network、HA、Rollback、Cutover時間およびMigration Rehearsalの追加評価が必要です。
* 複数Databaseの比較情報がないため、PRODDBの推奨Waveは要確認です。
* 本番Migration前には、必要に応じて再Assessmentを実施することを推奨します。
* Detailed Migration Plan、Migration Runbook、Cutover Procedure等は後続のMigration Design / Delivery工程で具体化します。
