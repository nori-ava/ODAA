#!/usr/bin/env bash
set -uo pipefail

# Formal pre-check for Oracle Database@Azure ZDM Physical Online Migration.
# Assessment prerequisites are reflected from assessment_result.md and target_environment.md.
# Secrets must be provided outside this script.

export ORACLE_SID="${ORACLE_SID:-PRODDB}"
export ORACLE_HOME="${ORACLE_HOME:-/u01/app/oracle/product/19.0.0/dbhome_1}"
export PATH="${ORACLE_HOME}/bin:${PATH}"

export SOURCE_DB_HOST="${SOURCE_DB_HOST:-srcdb01.example.local}"
export SOURCE_DB_PORT="${SOURCE_DB_PORT:-1521}"
export SOURCE_DB_SERVICE="${SOURCE_DB_SERVICE:-PRODDB}"
export EXPECTED_DB_NAME="${EXPECTED_DB_NAME:-PRODDB}"
export EXPECTED_DB_UNIQUE_NAME="${EXPECTED_DB_UNIQUE_NAME:-PRODDB}"
export EXPECTED_DB_MAJOR_VERSION="${EXPECTED_DB_MAJOR_VERSION:-19}"
export EXPECTED_COMPATIBLE_MAJOR="${EXPECTED_COMPATIBLE_MAJOR:-19}"
export EXPECTED_CHARACTER_SET="${EXPECTED_CHARACTER_SET:-AL32UTF8}"
export EXPECTED_NCHAR_CHARACTER_SET="${EXPECTED_NCHAR_CHARACTER_SET:-AL16UTF16}"

export TARGET_DB_HOST="${TARGET_DB_HOST:-targetdb01}"
export TARGET_DB_PORT="${TARGET_DB_PORT:-1521}"
export TARGET_DB_UNIQUE_NAME="${TARGET_DB_UNIQUE_NAME:-PRODDBAZ}"
export TARGET_DB_MAJOR_VERSION="${TARGET_DB_MAJOR_VERSION:-19}"
export TARGET_ORACLE_HOME="${TARGET_ORACLE_HOME:-/u02/app/oracle/product/19.0.0.0/dbhome_1}"
export TARGET_RU_LEVEL="${TARGET_RU_LEVEL:-}"
export TARGET_TIMEZONE_FILE_VERSION="${TARGET_TIMEZONE_FILE_VERSION:-}"

export ZDM_SSH_HOST="${ZDM_SSH_HOST:-zdm01.example.local}"
export ZDM_SSH_USER="${ZDM_SSH_USER:-opc}"
export ZDM_SSH_KEY="${ZDM_SSH_KEY:-/home/zdmuser/.ssh/id_rsa}"
export SOURCE_SSH_USER="${SOURCE_SSH_USER:-oracle}"
export SOURCE_SSH_KEY_ON_ZDM="${SOURCE_SSH_KEY_ON_ZDM:-/home/zdmuser/.ssh/id_rsa}"
export TARGET_SSH_USER="${TARGET_SSH_USER:-opc}"
export TARGET_SSH_KEY_ON_ZDM="${TARGET_SSH_KEY_ON_ZDM:-/home/zdmuser/.ssh/id_rsa}"

export NETWORK_BANDWIDTH_TARGET_HOST="${NETWORK_BANDWIDTH_TARGET_HOST:-}"
export NETWORK_BANDWIDTH_TARGET_PORT="${NETWORK_BANDWIDTH_TARGET_PORT:-5201}"
export NETWORK_BANDWIDTH_DURATION_SEC="${NETWORK_BANDWIDTH_DURATION_SEC:-10}"
export MIN_NETWORK_MBPS="${MIN_NETWORK_MBPS:-200}"

export APP_CONNECTION_SWITCH_APPROVED="${APP_CONNECTION_SWITCH_APPROVED:-NO}"
export DNS_TTL_CHANGE_APPROVED="${DNS_TTL_CHANGE_APPROVED:-NO}"
export DNS_TTL_SECONDS="${DNS_TTL_SECONDS:-3600}"
export MAX_DNS_TTL_SECONDS="${MAX_DNS_TTL_SECONDS:-300}"
export ROLLBACK_PROCEDURE_APPROVED="${ROLLBACK_PROCEDURE_APPROVED:-NO}"
export APP_STOP_START_APPROVED="${APP_STOP_START_APPROVED:-NO}"
export SYS_TDE_CREDENTIALS_APPROVED="${SYS_TDE_CREDENTIALS_APPROVED:-NO}"

PASS_COUNT=0
WARNINGS=0
FAILURES=0
MANUAL_CHECKS=0

PASS_ITEMS=()
WARNING_ITEMS=()
FAIL_ITEMS=()
MANUAL_ITEMS=()

log() {
  printf '%s\n' "$*"
}

normalize_bool() {
  case "${1^^}" in
    Y|YES|TRUE|1|APPROVED)
      printf 'YES\n'
      ;;
    *)
      printf 'NO\n'
      ;;
  esac
}

record_result() {
  local level="$1"
  local label="$2"
  local detail="$3"
  local item="${label} | ${detail}"

  printf '[%-12s] %s - %s\n' "${level}" "${label}" "${detail}"

  case "${level}" in
    PASS)
      PASS_COUNT=$((PASS_COUNT + 1))
      PASS_ITEMS+=("${item}")
      ;;
    WARNING)
      WARNINGS=$((WARNINGS + 1))
      WARNING_ITEMS+=("${item}")
      ;;
    FAIL)
      FAILURES=$((FAILURES + 1))
      FAIL_ITEMS+=("${item}")
      ;;
    "MANUAL CHECK")
      MANUAL_CHECKS=$((MANUAL_CHECKS + 1))
      MANUAL_ITEMS+=("${item}")
      ;;
  esac
}

print_category() {
  local title="$1"
  shift
  local item

  log ""
  log "### ${title}"
  if [[ $# -eq 0 ]]; then
    log "(none)"
    return
  fi

  for item in "$@"; do
    log "- ${item}"
  done
}

sql_query() {
  local sql_text="$1"

  sqlplus -S "/ as sysdba" <<SQL
WHENEVER OSERROR EXIT 1
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET ECHO OFF
SET TERMOUT OFF
SET TRIMSPOOL ON
SET LINESIZE 32767
SET TAB OFF
${sql_text}
EXIT
SQL
}

sql_value() {
  local sql_text="$1"
  local raw_output

  raw_output="$(sql_query "${sql_text}")" || return 1
  printf '%s\n' "${raw_output}" | awk 'NF { gsub(/\r/, ""); print; exit }'
}

test_tcp_connect() {
  local host="$1"
  local port="$2"
  local timeout_seconds="${3:-5}"

  if command -v nc >/dev/null 2>&1; then
    nc -z -w "${timeout_seconds}" "${host}" "${port}" >/dev/null 2>&1
    return $?
  fi

  if command -v timeout >/dev/null 2>&1; then
    timeout "${timeout_seconds}" bash -c ">/dev/tcp/${host}/${port}" >/dev/null 2>&1
    return $?
  fi

  bash -c ">/dev/tcp/${host}/${port}" >/dev/null 2>&1
}

check_manual_approval() {
  local label="$1"
  local approved_value="$2"
  local approved_detail="$3"
  local pending_detail="$4"

  if [[ "$(normalize_bool "${approved_value}")" == "YES" ]]; then
    record_result "PASS" "${label}" "${approved_detail}"
  else
    record_result "MANUAL CHECK" "${label}" "${pending_detail}"
  fi
}

check_zdm_nested_ssh() {
  local label="$1"
  local remote_user="$2"
  local remote_host="$3"
  local remote_key="$4"
  local remote_command

  remote_command="ssh -i '${remote_key}' -o BatchMode=yes -o StrictHostKeyChecking=no '${remote_user}@${remote_host}' 'hostname >/dev/null 2>&1'"

  if ssh -i "${ZDM_SSH_KEY}" -o BatchMode=yes -o StrictHostKeyChecking=no "${ZDM_SSH_USER}@${ZDM_SSH_HOST}" "${remote_command}" >/dev/null 2>&1; then
    record_result "PASS" "${label}" "ZDM host ${ZDM_SSH_HOST} can SSH to ${remote_user}@${remote_host}"
  else
    record_result "FAIL" "${label}" "ZDM host ${ZDM_SSH_HOST} cannot SSH to ${remote_user}@${remote_host}"
  fi
}

compare_mbps() {
  local measured="$1"
  local minimum="$2"

  awk -v measured="${measured}" -v minimum="${minimum}" 'BEGIN { exit(measured + 0 >= minimum + 0 ? 0 : 1) }'
}

convert_to_mbps() {
  local value="$1"
  local unit="$2"

  awk -v value="${value}" -v unit="${unit}" '
    BEGIN {
      if (unit == "Gbits/sec") {
        printf "%.2f\n", value * 1000
      } else if (unit == "Mbits/sec") {
        printf "%.2f\n", value
      } else if (unit == "Kbits/sec") {
        printf "%.2f\n", value / 1000
      } else if (unit == "bits/sec") {
        printf "%.2f\n", value / 1000000
      } else {
        printf "-1\n"
      }
    }
  '
}

log "=== Oracle Database@Azure ZDM Physical Online Migration Pre-Check ==="
log "Source DB Host=${SOURCE_DB_HOST} Service=${SOURCE_DB_SERVICE} ORACLE_SID=${ORACLE_SID}"
log "Target DB Host=${TARGET_DB_HOST} DB_UNIQUE_NAME=${TARGET_DB_UNIQUE_NAME} OracleHome=${TARGET_ORACLE_HOME}"
log "ZDM Host=${ZDM_SSH_HOST}"

if ! command -v sqlplus >/dev/null 2>&1; then
  log "ERROR: sqlplus is not available in PATH."
  exit 1
fi

log ""
log "[1/6] Source database metadata and configuration"

source_version="$(sql_value "SELECT version FROM v\$instance;")"
if [[ $? -ne 0 || -z "${source_version}" ]]; then
  record_result "FAIL" "Oracle Database major version" "Unable to query source database version"
else
  source_major="${source_version%%.*}"
  if [[ "${source_major}" == "${EXPECTED_DB_MAJOR_VERSION}" ]]; then
    record_result "PASS" "Oracle Database major version" "Source version=${source_version}"
  else
    record_result "FAIL" "Oracle Database major version" "Source version=${source_version}, expected major version=${EXPECTED_DB_MAJOR_VERSION}"
  fi
fi

source_ru="$(sql_value "SELECT patch_id || ' | ' || description || ' | ' || TO_CHAR(action_time, 'YYYY-MM-DD HH24:MI:SS') FROM (SELECT patch_id, description, action_time FROM dba_registry_sqlpatch WHERE status = 'SUCCESS' AND description LIKE '%Release Update%' ORDER BY action_time DESC) WHERE ROWNUM = 1;")"
if [[ $? -ne 0 ]]; then
  record_result "FAIL" "Oracle RU level" "Unable to query dba_registry_sqlpatch"
elif [[ -z "${source_ru}" ]]; then
  record_result "FAIL" "Oracle RU level" "No successful Release Update entry found in dba_registry_sqlpatch"
else
  record_result "PASS" "Oracle RU level" "${source_ru}"
fi

if [[ "${TARGET_DB_MAJOR_VERSION}" == "${EXPECTED_DB_MAJOR_VERSION}" ]]; then
  record_result "PASS" "Target Oracle major version (declared)" "Target major version=${TARGET_DB_MAJOR_VERSION}"
else
  record_result "FAIL" "Target Oracle major version (declared)" "Target major version=${TARGET_DB_MAJOR_VERSION}, expected=${EXPECTED_DB_MAJOR_VERSION}"
fi

if [[ -n "${TARGET_RU_LEVEL}" ]]; then
  record_result "PASS" "Target Oracle RU level (declared)" "TARGET_RU_LEVEL=${TARGET_RU_LEVEL}"
else
  record_result "WARNING" "Target Oracle RU level (declared)" "TARGET_RU_LEVEL is not set; assessment requires target Oracle home patch validation"
fi

db_name="$(sql_value "SELECT name FROM v\$database;")"
if [[ $? -ne 0 || -z "${db_name}" ]]; then
  record_result "FAIL" "DB_NAME" "Unable to query DB_NAME from v\$database"
elif [[ "${db_name}" == "${EXPECTED_DB_NAME}" ]]; then
  record_result "PASS" "DB_NAME" "DB_NAME=${db_name}"
else
  record_result "FAIL" "DB_NAME" "DB_NAME=${db_name}, expected=${EXPECTED_DB_NAME}"
fi

db_unique_name="$(sql_value "SELECT db_unique_name FROM v\$database;")"
if [[ $? -ne 0 || -z "${db_unique_name}" ]]; then
  record_result "FAIL" "DB_UNIQUE_NAME" "Unable to query DB_UNIQUE_NAME from v\$database"
elif [[ "${db_unique_name}" == "${EXPECTED_DB_UNIQUE_NAME}" ]]; then
  record_result "PASS" "DB_UNIQUE_NAME" "DB_UNIQUE_NAME=${db_unique_name}"
else
  record_result "FAIL" "DB_UNIQUE_NAME" "DB_UNIQUE_NAME=${db_unique_name}, expected=${EXPECTED_DB_UNIQUE_NAME}"
fi

spfile_path="$(sql_value "SELECT value FROM v\$parameter WHERE name = 'spfile';")"
if [[ $? -ne 0 ]]; then
  record_result "FAIL" "SPFILE usage" "Unable to query SPFILE configuration"
elif [[ -n "${spfile_path}" ]]; then
  record_result "PASS" "SPFILE usage" "SPFILE=${spfile_path}"
else
  record_result "FAIL" "SPFILE usage" "Database is not using SPFILE"
fi

compatible_value="$(sql_value "SELECT value FROM v\$parameter WHERE name = 'compatible';")"
if [[ $? -ne 0 || -z "${compatible_value}" ]]; then
  record_result "FAIL" "COMPATIBLE parameter" "Unable to query COMPATIBLE parameter"
else
  compatible_major="${compatible_value%%.*}"
  if [[ "${compatible_major}" == "${EXPECTED_COMPATIBLE_MAJOR}" ]]; then
    record_result "PASS" "COMPATIBLE parameter" "COMPATIBLE=${compatible_value}"
  else
    record_result "FAIL" "COMPATIBLE parameter" "COMPATIBLE=${compatible_value}, expected major=${EXPECTED_COMPATIBLE_MAJOR}"
  fi
fi

character_set="$(sql_value "SELECT value FROM nls_database_parameters WHERE parameter = 'NLS_CHARACTERSET';")"
if [[ $? -ne 0 || -z "${character_set}" ]]; then
  record_result "FAIL" "Character Set" "Unable to query NLS_CHARACTERSET"
elif [[ "${character_set}" == "${EXPECTED_CHARACTER_SET}" ]]; then
  record_result "PASS" "Character Set" "NLS_CHARACTERSET=${character_set}"
else
  record_result "FAIL" "Character Set" "NLS_CHARACTERSET=${character_set}, expected=${EXPECTED_CHARACTER_SET}"
fi

nchar_character_set="$(sql_value "SELECT value FROM nls_database_parameters WHERE parameter = 'NLS_NCHAR_CHARACTERSET';")"
if [[ $? -ne 0 || -z "${nchar_character_set}" ]]; then
  record_result "FAIL" "NCHAR Character Set" "Unable to query NLS_NCHAR_CHARACTERSET"
elif [[ "${nchar_character_set}" == "${EXPECTED_NCHAR_CHARACTER_SET}" ]]; then
  record_result "PASS" "NCHAR Character Set" "NLS_NCHAR_CHARACTERSET=${nchar_character_set}"
else
  record_result "FAIL" "NCHAR Character Set" "NLS_NCHAR_CHARACTERSET=${nchar_character_set}, expected=${EXPECTED_NCHAR_CHARACTER_SET}"
fi

archivelog_mode="$(sql_value "SELECT log_mode FROM v\$database;")"
if [[ $? -ne 0 || -z "${archivelog_mode}" ]]; then
  record_result "FAIL" "ARCHIVELOG" "Unable to query LOG_MODE"
elif [[ "${archivelog_mode}" == "ARCHIVELOG" ]]; then
  record_result "PASS" "ARCHIVELOG" "LOG_MODE=${archivelog_mode}"
else
  record_result "FAIL" "ARCHIVELOG" "LOG_MODE=${archivelog_mode}"
fi

force_logging="$(sql_value "SELECT force_logging FROM v\$database;")"
if [[ $? -ne 0 || -z "${force_logging}" ]]; then
  record_result "FAIL" "FORCE LOGGING" "Unable to query FORCE_LOGGING"
elif [[ "${force_logging}" == "YES" ]]; then
  record_result "PASS" "FORCE LOGGING" "FORCE_LOGGING=${force_logging}"
else
  record_result "FAIL" "FORCE LOGGING" "FORCE_LOGGING=${force_logging}"
fi

wallet_root="$(sql_value "SELECT value FROM v\$parameter WHERE name = 'wallet_root';")"
if [[ $? -ne 0 ]]; then
  record_result "FAIL" "TDE wallet path" "Unable to query WALLET_ROOT"
elif [[ -n "${wallet_root}" ]]; then
  record_result "PASS" "TDE wallet path" "WALLET_ROOT=${wallet_root}"
else
  record_result "FAIL" "TDE wallet path" "WALLET_ROOT is not configured"
fi

wallet_status="$(sql_value "SELECT CASE WHEN COUNT(*) = 0 THEN 'MISSING' WHEN SUM(CASE WHEN status = 'OPEN' THEN 1 ELSE 0 END) = COUNT(*) THEN 'OPEN' ELSE 'NOT_OPEN' END || ' | ' || NVL(MAX(wrl_parameter), 'NOT_SET') FROM v\$encryption_wallet;")"
if [[ $? -ne 0 || -z "${wallet_status}" ]]; then
  record_result "FAIL" "TDE wallet OPEN status" "Unable to query v\$encryption_wallet"
elif [[ "${wallet_status}" == OPEN* ]]; then
  record_result "PASS" "TDE wallet OPEN status" "${wallet_status}"
else
  record_result "FAIL" "TDE wallet OPEN status" "${wallet_status}"
fi

timezone_file_version="$(sql_value "SELECT version FROM v\$timezone_file;")"
if [[ $? -ne 0 || -z "${timezone_file_version}" ]]; then
  record_result "FAIL" "Time Zone File Version" "Unable to query v\$timezone_file"
else
  record_result "PASS" "Time Zone File Version" "Source TZ file version=${timezone_file_version}"
fi

if [[ -n "${TARGET_TIMEZONE_FILE_VERSION}" ]]; then
  if [[ "${TARGET_TIMEZONE_FILE_VERSION}" == "${timezone_file_version}" ]]; then
    record_result "PASS" "Target Time Zone File Version (declared)" "Target TZ file version=${TARGET_TIMEZONE_FILE_VERSION}"
  else
    record_result "FAIL" "Target Time Zone File Version (declared)" "Source TZ file version=${timezone_file_version}, target TZ file version=${TARGET_TIMEZONE_FILE_VERSION}"
  fi
else
  record_result "WARNING" "Target Time Zone File Version (declared)" "TARGET_TIMEZONE_FILE_VERSION is not set; validate source/target compatibility before migration"
fi

log ""
log "[2/6] Listener connectivity"

if test_tcp_connect "${SOURCE_DB_HOST}" "${SOURCE_DB_PORT}" 5; then
  record_result "PASS" "Source listener connectivity" "${SOURCE_DB_HOST}:${SOURCE_DB_PORT} reachable"
else
  record_result "FAIL" "Source listener connectivity" "${SOURCE_DB_HOST}:${SOURCE_DB_PORT} not reachable"
fi

if test_tcp_connect "${TARGET_DB_HOST}" "${TARGET_DB_PORT}" 5; then
  record_result "PASS" "Target listener connectivity" "${TARGET_DB_HOST}:${TARGET_DB_PORT} reachable"
else
  record_result "FAIL" "Target listener connectivity" "${TARGET_DB_HOST}:${TARGET_DB_PORT} not reachable"
fi

log ""
log "[3/6] SSH connectivity"

if ssh -i "${ZDM_SSH_KEY}" -o BatchMode=yes -o StrictHostKeyChecking=no "${ZDM_SSH_USER}@${ZDM_SSH_HOST}" 'hostname >/dev/null 2>&1' >/dev/null 2>&1; then
  record_result "PASS" "Source host -> ZDM host SSH" "SSH connectivity to ${ZDM_SSH_USER}@${ZDM_SSH_HOST} succeeded"
else
  record_result "FAIL" "Source host -> ZDM host SSH" "SSH connectivity to ${ZDM_SSH_USER}@${ZDM_SSH_HOST} failed"
fi

check_zdm_nested_ssh "ZDM host -> Source host SSH" "${SOURCE_SSH_USER}" "${SOURCE_DB_HOST}" "${SOURCE_SSH_KEY_ON_ZDM}"
check_zdm_nested_ssh "ZDM host -> Target host SSH" "${TARGET_SSH_USER}" "${TARGET_DB_HOST}" "${TARGET_SSH_KEY_ON_ZDM}"

log ""
log "[4/6] Network bandwidth"

if [[ -z "${NETWORK_BANDWIDTH_TARGET_HOST}" ]]; then
  record_result "WARNING" "Network bandwidth check" "NETWORK_BANDWIDTH_TARGET_HOST is not set; assessment requires throughput measurement"
elif ! command -v iperf3 >/dev/null 2>&1; then
  record_result "WARNING" "Network bandwidth check" "iperf3 is not installed; unable to measure throughput to ${NETWORK_BANDWIDTH_TARGET_HOST}:${NETWORK_BANDWIDTH_TARGET_PORT}"
else
  bandwidth_line="$(iperf3 -c "${NETWORK_BANDWIDTH_TARGET_HOST}" -p "${NETWORK_BANDWIDTH_TARGET_PORT}" -t "${NETWORK_BANDWIDTH_DURATION_SEC}" 2>/dev/null | awk '/receiver$/ { print $(NF-2) " " $(NF-1); exit }')"
  if [[ -z "${bandwidth_line}" ]]; then
    record_result "FAIL" "Network bandwidth check" "iperf3 completed without a receiver throughput result"
  else
    bandwidth_value="${bandwidth_line%% *}"
    bandwidth_unit="${bandwidth_line##* }"
    bandwidth_mbps="$(convert_to_mbps "${bandwidth_value}" "${bandwidth_unit}")"

    if [[ "${bandwidth_mbps}" == "-1" ]]; then
      record_result "FAIL" "Network bandwidth check" "Unsupported throughput unit returned by iperf3: ${bandwidth_line}"
    elif compare_mbps "${bandwidth_mbps}" "${MIN_NETWORK_MBPS}"; then
      record_result "PASS" "Network bandwidth check" "Measured throughput=${bandwidth_mbps} Mbps, minimum required=${MIN_NETWORK_MBPS} Mbps"
    else
      record_result "FAIL" "Network bandwidth check" "Measured throughput=${bandwidth_mbps} Mbps, minimum required=${MIN_NETWORK_MBPS} Mbps"
    fi
  fi
fi

log ""
log "[5/6] Manual migration gate checks"

check_manual_approval \
  "Application connection switch procedure" \
  "${APP_CONNECTION_SWITCH_APPROVED}" \
  "Application connection string change procedure is approved" \
  "Approval required for application connection string switch / cutover procedure"

if [[ "$(normalize_bool "${DNS_TTL_CHANGE_APPROVED}")" == "YES" ]]; then
  if awk -v current_ttl="${DNS_TTL_SECONDS}" -v max_ttl="${MAX_DNS_TTL_SECONDS}" 'BEGIN { exit(current_ttl + 0 <= max_ttl + 0 ? 0 : 1) }'; then
    record_result "PASS" "DNS TTL change" "DNS TTL=${DNS_TTL_SECONDS} seconds (max allowed=${MAX_DNS_TTL_SECONDS})"
  else
    record_result "FAIL" "DNS TTL change" "DNS TTL=${DNS_TTL_SECONDS} seconds exceeds max allowed=${MAX_DNS_TTL_SECONDS}"
  fi
else
  record_result "MANUAL CHECK" "DNS TTL change" "Approval required for DNS TTL change before cutover (current TTL=${DNS_TTL_SECONDS})"
fi

check_manual_approval \
  "Rollback procedure" \
  "${ROLLBACK_PROCEDURE_APPROVED}" \
  "Rollback procedure is approved" \
  "Approval required for rollback procedure"

check_manual_approval \
  "Application stop / start procedure" \
  "${APP_STOP_START_APPROVED}" \
  "Application stop/start procedure is approved" \
  "Approval required for application stop/start procedure"

check_manual_approval \
  "SYS / TDE credential confirmation" \
  "${SYS_TDE_CREDENTIALS_APPROVED}" \
  "SYS and TDE wallet credentials are confirmed" \
  "Approval required for SYS and TDE wallet credential confirmation"

log ""
log "[6/6] Final classification"

print_category "PASS" "${PASS_ITEMS[@]}"
print_category "WARNING" "${WARNING_ITEMS[@]}"
print_category "FAIL" "${FAIL_ITEMS[@]}"
print_category "MANUAL CHECK" "${MANUAL_ITEMS[@]}"

log ""
log "Summary: PASS=${PASS_COUNT} WARNING=${WARNINGS} FAIL=${FAILURES} MANUAL_CHECK=${MANUAL_CHECKS}"

if [[ ${FAILURES} -gt 0 ]]; then
  log "Migration Gate Result: FAIL"
  exit 1
fi

if [[ ${MANUAL_CHECKS} -gt 0 ]]; then
  log "Migration Gate Result: MANUAL CHECK"
  exit 2
fi

if [[ ${WARNINGS} -gt 0 ]]; then
  log "Migration Gate Result: WARNING"
  exit 3
fi

log "Migration Gate Result: PASS"
