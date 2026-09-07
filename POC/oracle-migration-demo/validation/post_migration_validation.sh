#!/usr/bin/env bash
set -uo pipefail

# Post-migration validation wrapper for Oracle Database@Azure target.
# This script executes the SQL validation script against the target database.

export ORACLE_HOME="${ORACLE_HOME:-/u02/app/oracle/product/19.0.0.0/dbhome_1}"
export PATH="${ORACLE_HOME}/bin:${PATH}"
export TARGET_DB_SERVICE="${TARGET_DB_SERVICE:-PRODDBAZ}"
export TARGET_DB_USER="${TARGET_DB_USER:-/ as sysdba}"
export SQL_FILE="${SQL_FILE:-$(dirname "$0")/post_migration_validation.sql}"
export OUTPUT_LOG="${OUTPUT_LOG:-$(dirname "$0")/post_migration_validation_$(date +%Y%m%d_%H%M%S).log}"

if [[ ! -f "${SQL_FILE}" ]]; then
  echo "Validation SQL file not found: ${SQL_FILE}"
  exit 1
fi

if ! command -v sqlplus >/dev/null 2>&1; then
  echo "ERROR: sqlplus is not available in PATH."
  exit 1
fi

# Use one of the following connection patterns for actual execution:
# 1) Local OS authentication: sqlplus -S "/ as sysdba" @${SQL_FILE}
# 2) Remote service connection: sqlplus -S "sys/<PASSWORD>@${TARGET_DB_SERVICE} as sysdba" @${SQL_FILE}

echo "Starting post-migration validation against ${TARGET_DB_SERVICE}"
sqlplus -S "${TARGET_DB_USER}" <<SQL 2>&1 | tee "${OUTPUT_LOG}"
@${SQL_FILE}
SQL

status=${PIPESTATUS[0]}
if [[ ${status} -ne 0 ]]; then
  echo "Post-migration validation failed. Review ${OUTPUT_LOG} for details."
  exit ${status}
fi

echo "Validation completed successfully. Confirm application connectivity and compare key row counts with source data."
