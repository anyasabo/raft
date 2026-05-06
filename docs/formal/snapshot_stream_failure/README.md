# Snapshot Stream Failure Model

This model covers partial/short-read snapshot transfer failures.

## Why this matters

When snapshot streaming fails before full payload receipt, follower state should
not advance as if the snapshot applied.

## Files

- `SnapshotStreamFailure.tla` - core model
- `SnapshotStreamFailure.cfg` - intended behavior (expected pass)
- `SnapshotStreamFailureBugSnapshot.cfg` - short read incorrectly advances snapshot index
- `SnapshotStreamFailureBugLastApplied.cfg` - short read incorrectly advances last applied

## Properties

- `ShortReadDoesNotAdvanceSnapshot`
- `ShortReadDoesNotAdvanceLastApplied`

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/snapshot_stream_failure"

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snapshot-stream-fixed \
  SnapshotStreamFailure.tla -config SnapshotStreamFailure.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snapshot-stream-bug-snapshot \
  SnapshotStreamFailure.tla -config SnapshotStreamFailureBugSnapshot.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snapshot-stream-bug-lastapplied \
  SnapshotStreamFailure.tla -config SnapshotStreamFailureBugLastApplied.cfg
```

Expected:

- fixed config passes all checks
- each bug config violates a targeted invariant
