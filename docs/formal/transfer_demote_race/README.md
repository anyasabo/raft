# Transfer-Demotion Race Model

This model targets a race where leadership transfer starts to a voter and that
same target is demoted to non-voter before election completes.

## Why this matters

A transfer should not be reported as successful unless the target actually
becomes leader. If leader loss is treated as success unconditionally, transfer
can falsely succeed after demotion while still causing term churn.

## Files

- `TransferDemoteRace.tla` - core race model
- `TransferDemoteRace.cfg` - intended behavior (`TreatLeaderLossAsSuccess = FALSE`)
- `TransferDemoteRaceBug.cfg` - bug profile (`TreatLeaderLossAsSuccess = TRUE`)

## Properties

- `NoFalseSuccessAfterDemotion` invariant:
  - disallows success when target is non-voter and never became leader.
- `TransferEventuallyResolves` liveness:
  - transfer reaches terminal success/failure.

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/transfer_demote_race"
java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-transfer-demote-fixed \
  TransferDemoteRace.tla -config TransferDemoteRace.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-transfer-demote-bug \
  TransferDemoteRace.tla -config TransferDemoteRaceBug.cfg
```

Expected:
- fixed config passes
- bug config violates `NoFalseSuccessAfterDemotion`
