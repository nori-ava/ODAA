#!/usr/bin/env bash
set -u

# Executes the ZDM physical migration for Oracle 19c online migration.
# Intended to run from the ZDM host after evaluation passes.

RESP_FILE="${RESP_FILE:-$(dirname "$0")/zdm_physical_migration.rsp}"
ZDM_HOME="${ZDM_HOME:-/u01/app/oracle/zdm}"
LOG_DIR="${LOG_DIR:-/tmp/zdm-migration}"
MIGRATION_LOG="${MIGRATION_LOG:-${LOG_DIR}/zdm_migration_$(date +%Y%m%d_%H%M%S).log}"

if [[ ! -f "${RESP_FILE}" ]]; then
  echo "Response file not found: ${RESP_FILE}"
  exit 1
fi

mkdir -p "${LOG_DIR}"

if [[ ! -x "${ZDM_HOME}/bin/zdmcli" ]]; then
  echo "ERROR: zdmcli not found at ${ZDM_HOME}/bin/zdmcli"
  exit 1
fi

echo "Starting ZDM online physical migration using ${RESP_FILE}"
"${ZDM_HOME}/bin/zdmcli" migrate database -rsp "${RESP_FILE}" 2>&1 | tee "${MIGRATION_LOG}"
status=${PIPESTATUS[0]}

if [[ ${status} -ne 0 ]]; then
  echo "ZDM migration failed. Review ${MIGRATION_LOG} and follow rollback guidance in the runbook."
  exit ${status}
fi

echo "Migration run completed successfully. Run post-migration validation before handing control back to the application team."
