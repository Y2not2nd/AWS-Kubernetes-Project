# Supported AWS RDS PostgreSQL Engine Versions

The `infra/rds` module now exposes a `db_engine_version` variable so that the backend can pin to a version that is actually available in the chosen AWS region. Below are engine versions that are currently offered in standard commercial AWS regions for PostgreSQL on RDS and work with the `db.t3.micro` instance class used in this project:

| Major Version | Example Engine Version | Notes |
| ------------- | ---------------------- | ----- |
| 16.x | 16.3 | Latest generation with logical decoding enhancements. Requires PostgreSQL 16-compatible client libraries. |
| 15.x | 15.6 | Long-term supported and broadly available. Backwards-compatible with earlier 15.x minor versions. |
| 14.x | 14.11 | Recommended if you need compatibility with older extensions that are not yet certified for 15.x+. |

To discover the complete list that is available in **your** AWS region at deployment time, run:

```bash
aws rds describe-db-engine-versions \
  --engine postgres \
  --query 'DBEngineVersions[].EngineVersion'
```

Update `var.rds_engine_version` (or provide `-var "rds_engine_version=..."` at `terraform apply` time) with one of the versions returned by the CLI above.
