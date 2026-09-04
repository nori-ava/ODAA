# Customer Hearing Sheet

## Business Requirements

- Production database
- Allowed downtime: Maximum 2 hours
- Target migration period: Within 3 months
- Application changes should be minimized.
- Data loss is not acceptable.
- Rollback procedure is mandatory.
- Migration rehearsal is required before production migration.

## Application Dependencies

- Application: Sales Management Application
- Middleware: WebLogic Server
- Batch: 35 scheduled batch jobs
- DB Link: 4
- External Interface: 6
- File Transfer: SFTP
- Monitoring: Existing enterprise monitoring platform

## Customer Constraints

- Production cutover must be performed during weekend.
- DNS switching is required.
- Security review must be completed before migration.
- Existing backup policy must be maintained.