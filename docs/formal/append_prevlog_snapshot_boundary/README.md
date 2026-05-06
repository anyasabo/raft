# Append PrevLog Snapshot Boundary Model

This model checks `appendEntries` prev-log validation when `PrevLogEntry`
targets the snapshot boundary.

## Why this matters

Followers compact logs after snapshot install. `PrevLogEntry` can validly refer
to the snapshot index even when that log no longer exists in the log store.

## Files

- `AppendPrevLogSnapshotBoundary.tla` - core model
- `AppendPrevLogSnapshotBoundary.cfg` - intended behavior (expected pass)
- `AppendPrevLogSnapshotBoundaryBug.cfg` - boundary-check bug profile

## Property

- `SnapshotBoundaryAcceptsMatchingTerm`

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/append_prevlog_snapshot_boundary"

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-prevlog-snap-fixed \
  AppendPrevLogSnapshotBoundary.tla -config AppendPrevLogSnapshotBoundary.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-prevlog-snap-bug \
  AppendPrevLogSnapshotBoundary.tla -config AppendPrevLogSnapshotBoundaryBug.cfg
```

Expected:

- fixed config passes all checks
- bug config violates `SnapshotBoundaryAcceptsMatchingTerm`
