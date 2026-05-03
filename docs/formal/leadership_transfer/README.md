# Leadership Transfer TLA+ Model

This directory contains a focused TLA+ model for leadership transfer progress
and write-gating behavior.

## Scope

The model intentionally covers only the transfer path relevant to the
leadership-transfer write interleaving bug class:

- transfer starts while an old leader is active,
- `TimeoutNow` has been sent to a transfer target,
- writes may or may not be blocked during the transfer window,
- transfer eventually resolves as success or failure.

This is not a full Raft model and does not model replication internals, disk,
or network transport details.

## Files

- `LeadershipTransfer.tla`: model and properties.
- `LeadershipTransfer.cfg`: liveness + safety checks with bounded log indices.
- `LeadershipTransferSafety.cfg`: safety-only profile (no liveness property).
- `LeadershipTransferFast.cfg`: fast-iteration profile using a level bound.
- `LeadershipTransferBug.cfg`: bug-mode configuration that allows writes during
  transfer and should violate the no-write invariant.

## Properties

- `TypeInvariant`: state shape remains valid.
- `NoWritesAcceptedDuringTransfer`: no old-leader writes are accepted while a
  transfer is in progress.
- `KnownLeaderRequiresTransferFlag`: when a known leader exists, the transfer
  vote flag is required for the target to become leader.
- `TransferVoteRespectsLogFreshness`: even with transfer voting enabled, a
  stale target log cannot win leadership.
- `TransferResolutionUnblocksWrites`: once transfer resolves, write blocking is
  cleared.
- `TransferEventuallyResolves`: transfer-in-progress leads to a resolved
  outcome.

## How to run

From this directory, fetch the latest official jar (currently v1.8.0):

```bash
mkdir -p tools
curl -fsSL -o tools/tla2tools-v1.8.0.jar \
  "https://github.com/tlaplus/tlaplus/releases/download/v1.8.0/tla2tools.jar"
echo "556786039c954356cf970ed0dbd6a10541c70044  tools/tla2tools-v1.8.0.jar" | sha1sum --check
```

Then run the "good" model:

```bash
java -XX:+UseParallelGC -cp "tools/tla2tools-v1.8.0.jar" \
  tlc2.TLC -workers 8 -checkpoint 5 -config LeadershipTransfer.cfg LeadershipTransfer
```

Run safety-only checks (faster than liveness):

```bash
java -XX:+UseParallelGC -cp "tools/tla2tools-v1.8.0.jar" \
  tlc2.TLC -workers 8 -checkpoint 5 -config LeadershipTransferSafety.cfg LeadershipTransfer
```

Run a fast bounded model while iterating:

```bash
java -XX:+UseParallelGC -cp "tools/tla2tools-v1.8.0.jar" \
  tlc2.TLC -workers 8 -checkpoint 5 -config LeadershipTransferFast.cfg LeadershipTransfer
```

To observe the expected counterexample for the bug-mode model:

```bash
java -XX:+UseParallelGC -cp "tools/tla2tools-v1.8.0.jar" \
  tlc2.TLC -workers 8 -checkpoint 5 -config LeadershipTransferBug.cfg LeadershipTransfer
```

Reference: [TLA+ v1.8.0 release](https://github.com/tlaplus/tlaplus/releases/tag/v1.8.0)

## Mapping to Go tests

- Existing coverage: `TestRaft_LeadershipTransferWithWrites`,
  `TestRaft_LeadershipTransferToInvalidAddress`,
  `TestRaft_LeadershipTransferLeaderRejectsClientRequests`.
- Model-derived addition in this phase:
  `TestRaft_LeadershipTransferFailureUnblocksWrites`,
  `TestRaft_LeadershipTransferVoteFlagRespectsLogFreshness`,
  `TestRaft_LeadershipTransferRetryAfterFailure`.
