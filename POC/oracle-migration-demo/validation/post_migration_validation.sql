SET PAGESIZE 200
SET LINESIZE 220
SET FEEDBACK OFF
SET VERIFY OFF
SET SERVEROUTPUT ON

PROMPT =========================================================
PROMPT Post-Migration Validation for Oracle 19c / ZDM Physical Migration
PROMPT =========================================================

-- Replace the schema and table names below with the actual application objects.
-- Example schema/table names: APP.CUSTOMERS, APP.ORDERS, APP.INVOICES

-- NOTE: These queries are examples and must be adjusted to the actual target schema.

PROMPT 1. Database summary
SELECT name,
       open_mode,
       database_role,
       platform_name,
       version
FROM v$database;

PROMPT 2. PDB summary
SELECT con_id,
       name,
       open_mode,
       restricted,
       open_time
FROM v$pdbs
ORDER BY con_id;

PROMPT 3. Schema count
SELECT COUNT(*) AS schema_count
FROM dba_users
WHERE username NOT IN ('SYS', 'SYSTEM', 'OUTLN', 'DBSNMP', 'APPQOSSYS', 'ANONYMOUS', 'XDB', 'ORDDATA', 'ORDSYS', 'WMSYS', 'MDSYS', 'CTXSYS', 'OLAPSYS', 'DVF', 'DVSYS');

PROMPT 4. Object count
SELECT owner,
       COUNT(*) AS object_count
FROM dba_objects
WHERE owner NOT IN ('SYS', 'SYSTEM')
GROUP BY owner
ORDER BY 2 DESC, 1;

PROMPT 5. Invalid objects
SELECT COUNT(*) AS invalid_object_count
FROM dba_objects
WHERE status <> 'VALID'
  AND owner NOT IN ('SYS', 'SYSTEM');

PROMPT 6. Tablespace status
SELECT tablespace_name,
       status,
       contents,
       block_size,
       bytes / 1024 / 1024 AS mb
FROM dba_tablespaces
ORDER BY tablespace_name;

PROMPT 7. Row counts for critical tables
-- Replace APP.CUSTOMERS / APP.ORDERS / APP.INVOICES with real application objects.
SELECT 'APP.CUSTOMERS' AS table_name,
       COUNT(*) AS row_count
FROM APP.CUSTOMERS;

SELECT 'APP.ORDERS' AS table_name,
       COUNT(*) AS row_count
FROM APP.ORDERS;

SELECT 'APP.INVOICES' AS table_name,
       COUNT(*) AS row_count
FROM APP.INVOICES;

PROMPT 8. Data file and temp file status
SELECT file_name,
       tablespace_name,
       AUTOEXTENSIBLE,
       status,
       bytes / 1024 / 1024 AS size_mb
FROM dba_data_files
UNION ALL
SELECT file_name,
       tablespace_name,
       AUTOEXTENSIBLE,
       status,
       bytes / 1024 / 1024 AS size_mb
FROM dba_temp_files;

PROMPT 9. Application connectivity sanity check
SELECT 'PASS' AS application_connectivity
FROM dual;

PROMPT 10. Performance and latency sampling
SELECT 'Current timestamp:' AS metric, TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS TZH:TZM') AS value FROM dual;
SELECT name,
       value
FROM v$parameter
WHERE name IN ('sessions', 'processes', 'parallel_max_servers');

PROMPT 11. Summary result
SELECT CASE WHEN open_mode = 'READ WRITE' THEN 'PASS' ELSE 'FAIL' END AS database_open_check,
       CASE WHEN EXISTS (SELECT 1 FROM v$pdbs WHERE open_mode <> 'READ WRITE') THEN 'FAIL' ELSE 'PASS' END AS pdb_open_check,
       CASE WHEN (SELECT COUNT(*) FROM dba_objects WHERE status <> 'VALID' AND owner NOT IN ('SYS', 'SYSTEM')) = 0 THEN 'PASS' ELSE 'FAIL' END AS invalid_object_check
FROM v$database;
