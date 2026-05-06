# Restore Inflight Abort Model

This model covers `restoreUserSnapshot` behavior when logs are inflight.

## Why this matters

A user restore must abort queued inflight log futures before attempting
snapshot persistence and restore work. Missing this can leave writes hanging or
misreported.

## Files

- `RestoreInflightAbort.tla` - core model
- `RestoreInflightAbort.cfg` - intended behavior (expected pass)
- `RestoreInflightAbortBugNoAbort.cfg` - restore forgets to abort inflight futures
- `RestoreInflightAbortBugNoClear.cfg` - restore aborts but leaves inflight queue uncleared

## Properties

- `RestoreAbortsAllInflight`
- `RestoreClearsInflightQueue`

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/restore_inflight_abort"

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-restore-inflight-fixed \
  RestoreInflightAbort.tla -config RestoreInflightAbort.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-restore-inflight-bug-noabort \
  RestoreInflightAbort.tla -config RestoreInflightAbortBugNoAbort.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-restore-inflight-bug-noclear \
  RestoreInflightAbort.tla -config RestoreInflightAbortBugNoClear.cfg
```

Expected:

- fixed config passes all checks
- each bug config violates a targeted invariant
