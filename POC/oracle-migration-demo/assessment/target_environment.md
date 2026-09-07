# Target Environment

## Target Database
- Platform: Oracle Database@Azure
- Database Service: Exadata Database Service
- Oracle Version: 19c
- Target DB Unique Name: PRODDBAZ
- Target Host: targetdb01
- Target Oracle Home: /u02/app/oracle/product/19.0.0.0/dbhome_1

## Network
- Connectivity from ZDM Host: Required
- SSH User: opc
- SSH Private Key: /home/zdmuser/.ssh/id_rsa
- sudo: /usr/bin/sudo

## Migration Policy
- Preferred Migration: Online Physical
- Target Downtime: <= 30 minutes
- Migration Tool: Oracle ZDM

## Validation Requirements
- Database Open Mode
- PDB Open Status
- Schema Count
- Object Count
- Invalid Objects
- Row Count for Critical Tables
- Tablespace Status
- Application Connectivity
- Basic Performance Check