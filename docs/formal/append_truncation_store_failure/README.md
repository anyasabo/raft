# Append Truncation + Store Failure Model

This model captures a follower conflict-truncation flow where `StoreLogs` fails
after deleting a suffix.

## Why this matters

When conflict truncation succeeds but appending replacement entries fails, the
cached `lastLog` metadata must be recomputed from durable storage. Leaving it
stale can corrupt subsequent consistency checks.

## Files

- `AppendTruncationStoreFailure.tla` - core model
- `AppendTruncationStoreFailure.cfg` - intended behavior (expected pass)
- `AppendTruncationStoreFailureBug.cfg` - stale cached `lastLog` bug profile

## Property

- `LastLogMatchesStoreAfterFailure`

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/append_truncation_store_failure"

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-append-store-fail-fixed \
  AppendTruncationStoreFailure.tla -config AppendTruncationStoreFailure.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-append-store-fail-bug \
  AppendTruncationStoreFailure.tla -config AppendTruncationStoreFailureBug.cfg
```

Expected:

- fixed config passes all checks
- bug config violates `LastLogMatchesStoreAfterFailure`
