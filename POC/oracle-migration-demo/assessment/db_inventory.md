# Oracle Database Inventory

## Database
- DB Name: PRODDB
- DB Unique Name: PRODDB
- Oracle Version: 19.22.0.0
- Edition: Enterprise Edition
- Architecture: CDB / PDB
- CDB: PRODDB
- PDB: PRODPDB1
- Character Set: AL32UTF8
- National Character Set: AL16UTF16

## Platform
- Source: On-Premises
- OS: Oracle Linux 8
- CPU Architecture: x86_64
- Storage: ASM
- Database Size: 2.5 TB

## Configuration
- ARCHIVELOG: Enabled
- FORCE LOGGING: Enabled
- Flashback Database: Enabled
- TDE: Enabled
- RMAN Backup: Enabled
- Data Guard: Not configured
- GoldenGate: Not configured

## HA
- RAC: No
- Single Instance: Yes

## Network
- Source DB Host: srcdb01.example.local
- Listener Port: 1521
- Service Name: PRODDB
- ZDM Host: zdm01.example.local

## Business Requirement
- Maximum Downtime: 30 minutes
- Migration Window: Saturday 22:00 - Sunday 06:00