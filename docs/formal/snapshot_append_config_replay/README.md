# Snapshot + Append Config Replay Model

This model captures follower config-index behavior when a snapshot is installed,
an uncommitted config entry is appended, and later conflict truncation rewinds
that suffix.

## Why this matters

After snapshot install, replay can temporarily advance `latest` config beyond
`committed`. If a subsequent conflict truncates across that config entry,
`latest` must roll back to `committed`.

## Files

- `SnapshotAppendConfigReplay.tla` - core model
- `SnapshotAppendConfigReplay.cfg` - intended behavior (expected pass)
- `SnapshotAppendConfigReplayBug.cfg` - stale latest-config bug profile

## Property

- `LatestConfigRollsBackAfterConflict`

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/snapshot_append_config_replay"

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snap-append-config-fixed \
  SnapshotAppendConfigReplay.tla -config SnapshotAppendConfigReplay.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-snap-append-config-bug \
  SnapshotAppendConfigReplay.tla -config SnapshotAppendConfigReplayBug.cfg
```

Expected:

- fixed config passes all checks
- bug config violates `LatestConfigRollsBackAfterConflict`
