# Protocol Compatibility Election Model

This model targets mixed-version election behavior where vote and pre-vote
messages can carry candidate identity in different fields across compatibility
paths.

## Why this matters

Raft vote/pre-vote handling combines several compatibility-sensitive decisions:

- candidate identity decoding (`Addr` vs legacy `Candidate` bytes),
- transfer-vote bypass behavior (`LeadershipTransfer`),
- pre-vote known-leader gating when only legacy candidate encoding is present.

Regressions here can produce false grants, false rejections, or transfer
liveness stalls.

## Files

- `ProtocolCompatElection.tla` - core model
- `ProtocolCompatElection.cfg` - intended behavior (expected pass)
- `ProtocolCompatElectionBugIdentity.cfg` - identity-source mismatch bug
- `ProtocolCompatElectionBugTransferFlag.cfg` - transfer-flag drop bug
- `ProtocolCompatElectionBugPreVoteFallback.cfg` - pre-vote fallback bug

## Toggles

- `PreferAddrFieldWhenPresent`
- `DropTransferFlagOnCompatPath`
- `PreVoteUsesLegacyCandidateFallback`

## Properties

- `VoteIdentityConsistent`
- `PreVoteKnownLeaderGateStable`
- `TransferVoteGrantedAfterRequest`

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/protocol_compat_election"

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-protocol-compat-fixed \
  ProtocolCompatElection.tla -config ProtocolCompatElection.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-protocol-compat-bug-identity \
  ProtocolCompatElection.tla -config ProtocolCompatElectionBugIdentity.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-protocol-compat-bug-transfer \
  ProtocolCompatElection.tla -config ProtocolCompatElectionBugTransferFlag.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-protocol-compat-bug-prevote \
  ProtocolCompatElection.tla -config ProtocolCompatElectionBugPreVoteFallback.cfg
```

Expected:

- fixed config passes all checks
- each bug config violates a targeted invariant
