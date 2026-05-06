# Append Config-Process Failure Model

This model captures a follower path where `appendEntries` persists new logs,
then fails while processing a configuration entry.

## Why this matters

When append succeeds but config processing fails, cached `lastLog` metadata
must still match durable storage. Leaving cache stale can corrupt subsequent
consistency checks and responses.

## Files

- `AppendConfigProcessFailure.tla` - core model
- `AppendConfigProcessFailure.cfg` - intended behavior (expected pass)
- `AppendConfigProcessFailureBug.cfg` - stale cached `lastLog` bug profile

## Property

- `LastLogMatchesStoreAfterConfigProcessFailure`

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/append_config_process_failure"

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-append-config-process-fixed \
  AppendConfigProcessFailure.tla -config AppendConfigProcessFailure.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-append-config-process-bug \
  AppendConfigProcessFailure.tla -config AppendConfigProcessFailureBug.cfg
```

Expected:

- fixed config passes all checks
- bug config violates `LastLogMatchesStoreAfterConfigProcessFailure`
