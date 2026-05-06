# Snapshot Catch-Up Race Model

This model explores snapshot installation during follower catch-up when election
and membership side-effects are in flight.

## Why this matters

`installSnapshot` is a multi-step path in Raft with term updates, leader
tracking, and state persistence. Small regressions can produce:

- term regressions from stale snapshots,
- config changes applied while snapshot install is in progress,
- incorrect known-leader resets after successful snapshot application.

## Files

- `SnapshotCatchupRace.tla` - core model
- `SnapshotCatchupRace.cfg` - intended behavior (expected pass)
- `SnapshotCatchupRaceBugTermRegression.cfg` - stale snapshot term bug
- `SnapshotCatchupRaceBugConfigDuringSnapshot.cfg` - config mutation during snapshot bug
- `SnapshotCatchupRaceBugLeaderReset.cfg` - known-leader reset bug

## Properties

- `NoTermRegression`
- `ConfigStableDuringSnapshot`
- `KnownLeaderRetainedAfterSnapshot`
- `CatchupEventuallyVisible`

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/snapshot_catchup_race"

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snapshot-catchup-fixed \
  SnapshotCatchupRace.tla -config SnapshotCatchupRace.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snapshot-catchup-bug-term \
  SnapshotCatchupRace.tla -config SnapshotCatchupRaceBugTermRegression.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snapshot-catchup-bug-config \
  SnapshotCatchupRace.tla -config SnapshotCatchupRaceBugConfigDuringSnapshot.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snapshot-catchup-bug-leader \
  SnapshotCatchupRace.tla -config SnapshotCatchupRaceBugLeaderReset.cfg
```

Expected:

- fixed config passes all checks
- each bug config violates at least one invariant
