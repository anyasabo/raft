# Snapshot + Append Interleaving Model

This model captures stale `AppendEntries` arriving after a follower has already
installed a newer snapshot state.

## Why this matters

After snapshot catch-up, stale append RPCs should never:

- regress follower term,
- overwrite the known leader established by newer state,
- decrease commit index.

## Files

- `SnapshotAppendInterleaving.tla` - core model
- `SnapshotAppendInterleaving.cfg` - intended behavior (expected pass)
- `SnapshotAppendInterleavingBugTerm.cfg` - stale append regresses term
- `SnapshotAppendInterleavingBugLeader.cfg` - stale append overwrites leader
- `SnapshotAppendInterleavingBugCommit.cfg` - stale append regresses commit index

## Properties

- `TermNeverRegresses`
- `LeaderStableAfterStaleAppend`
- `CommitIndexNeverRegresses`

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/snapshot_append_interleaving"

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snapshot-append-fixed \
  SnapshotAppendInterleaving.tla -config SnapshotAppendInterleaving.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snapshot-append-bug-term \
  SnapshotAppendInterleaving.tla -config SnapshotAppendInterleavingBugTerm.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snapshot-append-bug-leader \
  SnapshotAppendInterleaving.tla -config SnapshotAppendInterleavingBugLeader.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snapshot-append-bug-commit \
  SnapshotAppendInterleaving.tla -config SnapshotAppendInterleavingBugCommit.cfg
```

Expected:

- fixed config passes all checks
- each bug config violates a targeted invariant
