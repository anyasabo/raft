# Replication Transfer Selection Model

This model explores leadership-transfer target selection under replication
backoff and voter eligibility changes.

## Why this matters

`pickServer()` chooses transfer targets from replication `nextIndex` state.
Selection bugs can cause:

- stale targets to remain selected after backoff/catch-up updates,
- demoted/non-voter targets to be selected incorrectly,
- transfer attempts to oscillate or stall.

## Files

- `ReplicationTransferSelection.tla` - core model
- `ReplicationTransferSelection.cfg` - intended behavior (expected pass)
- `ReplicationTransferSelectionBugIncludeNonVoter.cfg` - includes non-voters bug
- `ReplicationTransferSelectionBugStickyTarget.cfg` - sticky target bug
- `ReplicationTransferSelectionBugStaleIndex.cfg` - stale-index preference bug

## Toggles

- `IncludeNonVoterCandidates`
- `StickyTargetAfterPick`
- `PreferStaleIndices`

## Properties

- `RebalancePickChoosesFreshest`
- `PostDemotionPickSkipsA`

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/replication_transfer_selection"

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-repl-transfer-fixed \
  ReplicationTransferSelection.tla -config ReplicationTransferSelection.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-repl-transfer-bug-nonvoter \
  ReplicationTransferSelection.tla -config ReplicationTransferSelectionBugIncludeNonVoter.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-repl-transfer-bug-sticky \
  ReplicationTransferSelection.tla -config ReplicationTransferSelectionBugStickyTarget.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-repl-transfer-bug-stale \
  ReplicationTransferSelection.tla -config ReplicationTransferSelectionBugStaleIndex.cfg
```

Expected:

- fixed config passes all checks
- each bug config violates a targeted invariant
