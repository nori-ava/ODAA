# ZDM Physical Migration Runbook

## Scope
This runbook covers an Oracle 19c to Oracle Database@Azure migration using Oracle Zero Downtime Migration (ZDM) in online physical mode.

## Assumptions
- Source database: PRODDB / PRODPDB1 (Oracle 19.22.0.0, CDB/PDB)
- Source host: srcdb01.example.local
- Target host: targetdb01
- ZDM host: zdm01.example.local
- Maximum downtime target: 30 minutes
- Oracle version is compatible with 19c target

## Step 1: Review assessment findings
- Confirm all blockers from the assessment are addressed.
- Required items before migration:
  - target Oracle home patch compatibility
  - source/target compatibility validation
  - SSH connectivity from ZDM host
  - SYS and TDE wallet credentials confirmed
  - firewall rules approved
  - network throughput measured
  - rollback procedure confirmed
  - application stop/start procedure confirmed

## Step 2: Run pre-migration checks
From the source database host, run:

```bash
./migration/pre_migration_checks.sh
```

Expected result:
- ARCHIVELOG = ENABLED
- FORCE LOGGING = YES
- RMAN backup available
- PDBs open in READ WRITE
- no critical invalid objects
- SSH connectivity to ZDM host is successful

## Step 3: Prepare the ZDM response file
Populate `migration/zdm_physical_migration.rsp` with environment-specific values and credentials in the secure ZDM environment.

## Step 4: Run ZDM evaluation
From the ZDM host:

```bash
export RESP_FILE=/path/to/zdm_physical_migration.rsp
export ZDM_HOME=/u01/app/oracle/zdm
./migration/zdm_evaluation.sh
```

Only proceed when evaluation returns success and all blockers are resolved.

## Step 5: Execute the migration
```bash
export RESP_FILE=/path/to/zdm_physical_migration.rsp
export ZDM_HOME=/u01/app/oracle/zdm
./migration/zdm_migration.sh
```

During migration:
- monitor the ZDM job
- watch for redo apply lag and network issues
- keep rollback plan ready in case the target DB fails validation

## Step 6: Post-migration validation
After migration completes, run:

```bash
./validation/post_migration_validation.sh
```

Validate:
- database open mode
- PDB open status
- schema count
- object count
- invalid objects count
- row count for critical tables
- tablespace status
- application connectivity
- performance check

## Step 7: Final cutover and rollback
- switch the application connection string to the target database
- confirm application functionality and transaction flow
- if cutover fails, use your rollback procedure and restore the original configuration

## Notes
- Do not store passwords or keys in the repository.
- Use environment variables or secret management for production operations.
- Use the exact ZDM version and target Oracle home supported by the target platform.
