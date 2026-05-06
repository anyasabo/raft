# Config Truncation Rollback Model

This model verifies that conflict truncation rolls back the follower's latest
configuration pointer to the committed configuration index.

## Why this matters

When `AppendEntries` truncates across a configuration entry, leaving
`latestIndex` ahead of committed configuration can create stale membership
views.

## Files

- `ConfigTruncationRollback.tla` - core model
- `ConfigTruncationRollback.cfg` - intended behavior (expected pass)
- `ConfigTruncationRollbackBug.cfg` - stale latest-configuration bug profile

## Property

- `LatestConfigNotAheadAfterTruncate`

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/config_truncation_rollback"

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-config-trunc-fixed \
  ConfigTruncationRollback.tla -config ConfigTruncationRollback.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-config-trunc-bug \
  ConfigTruncationRollback.tla -config ConfigTruncationRollbackBug.cfg
```

Expected:

- fixed config passes all checks
- bug config violates `LatestConfigNotAheadAfterTruncate`
