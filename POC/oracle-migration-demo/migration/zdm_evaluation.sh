#!/usr/bin/env bash
set -u

# ZDM evaluation step for the Oracle 19c -> Azure physical migration.
# This is a safe, parameterized wrapper intended for use on the ZDM host.

RESP_FILE="${RESP_FILE:-$(dirname "$0")/zdm_physical_migration.rsp}"
ZDM_HOME="${ZDM_HOME:-/u01/app/oracle/zdm}"
LOG_DIR="${LOG_DIR:-/tmp/zdm-eval}"
EVAL_LOG="${EVAL_LOG:-${LOG_DIR}/zdm_evaluation_$(date +%Y%m%d_%H%M%S).log}"

if [[ ! -f "${RESP_FILE}" ]]; then
  echo "Response file not found: ${RESP_FILE}"
  exit 1
fi

mkdir -p "${LOG_DIR}"

if [[ ! -x "${ZDM_HOME}/bin/zdmcli" ]]; then
  echo "ERROR: zdmcli not found at ${ZDM_HOME}/bin/zdmcli"
  exit 1
fi

# ZDM version can vary by release. The -eval flag is a template for evaluation execution.
# Adjust the command to the exact runtime version used in your environment.

echo "Starting ZDM evaluation using ${RESP_FILE}"
"${ZDM_HOME}/bin/zdmcli" migrate database -rsp "${RESP_FILE}" -eval 2>&1 | tee "${EVAL_LOG}"

status=${PIPESTATUS[0]}
if [[ ${status} -ne 0 ]]; then
  echo "ZDM evaluation failed. Check ${EVAL_LOG} for details."
  exit ${status}
fi

# Conservative gate: evaluation must be clear before production migration.
echo "ZDM evaluation completed successfully. Proceed to migration only when all blocker checks are resolved."
