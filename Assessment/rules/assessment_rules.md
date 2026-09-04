# Oracle Migration Assessment Rules

## Severity

### Red

以下の場合はRedとする。

- Migration Blockerが存在する
- Data lossの可能性がある
- Target環境との重大な非互換が存在する
- 本番移行に必須のRemediation方法が確立できず、移行可否に重大な不確実性がある

### Amber

以下の場合はAmberとする。

- Review Required項目が存在する
- Remediation後にMigration可能
- Network / Security / Application Dependency等の追加確認が必要

### Green

以下の場合はGreenとする。

- Migration Blockerなし
- 重大なCompatibility Issueなし
- Migration前提条件が確認済み

## Migration Method

Migration方式を以下の観点で評価する。

- Source / Target Compatibility
- Database Size
- Allowed Downtime
- Data Loss Requirement
- Application Impact
- Rollback Requirement
- Operational Complexity

Physical Migrationが技術的に適用可能で、
Application変更を最小化できる場合は優先候補として評価する。

## Finding

各Findingについて必ず以下を記載する。

1. Finding
2. Severity
3. Migrationへの影響
4. 推奨対応
5. 本番移行前の対応要否

## Report Generation

推測で情報を補完しない。

Inputに存在しない情報については、

「要確認」
「未確認」
「後続工程で確認」

のいずれかとして記載する。

## Assessment Judgment Guardrails

### 総合判定

明示的なMigration Blockerがなく、
Review Requiredまたは追加確認事項が存在する場合は、
原則としてAmberとする。

Redは以下の場合に限定する。

- Migrationを阻害する重大な非互換が確認された場合
- Target環境で移行要件を満たせないことが確認された場合
- Data loss等の重大Riskを回避する方法が確認できない場合
- 必須Remediationの実施方法が確立できず、移行可否を判断できない場合

### Migration Method

Input情報だけで移行方式の適用条件を確認できない場合、
特定のMigration方式を「推奨」または「確定」としない。

その場合は、
「有力候補」「追加評価が必要」
として記載する。

### Input Consistency

複数Input間に数値や構成情報の差異がある場合、
Compatibility Issueと断定せず、
「Assessment確認事項」として整理する。