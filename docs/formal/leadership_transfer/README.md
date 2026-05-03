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
- `LeadershipTransfer.cfg`: expected/correct write-gating configuration.
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

From this directory:

```bash
java -cp /path/to/tla2tools.jar tlc2.TLC LeadershipTransfer.tla -config LeadershipTransfer.cfg
```

To observe the expected counterexample for the bug-mode model:

```bash
java -cp /path/to/tla2tools.jar tlc2.TLC LeadershipTransfer.tla -config LeadershipTransferBug.cfg
```

## Mapping to Go tests

- Existing coverage: `TestRaft_LeadershipTransferWithWrites`,
  `TestRaft_LeadershipTransferToInvalidAddress`,
  `TestRaft_LeadershipTransferLeaderRejectsClientRequests`.
- Model-derived addition in this phase:
  `TestRaft_LeadershipTransferFailureUnblocksWrites`,
  `TestRaft_LeadershipTransferVoteFlagRespectsLogFreshness`,
  `TestRaft_LeadershipTransferRetryAfterFailure`.
