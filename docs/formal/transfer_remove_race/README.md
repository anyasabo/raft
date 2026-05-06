# Transfer-Removal Race Model

This model covers leadership transfer when the target is removed from
configuration while transfer is in progress.

## Why this matters

Transfer completion should not be reported as success unless the target actually
becomes leader. If completion treats "old leader lost leadership" as success,
target removal can produce false-success transfer outcomes and term churn.

## Files

- `TransferRemoveRace.tla` - core transfer/removal race model
- `TransferRemoveRace.cfg` - intended behavior (`TreatLeaderLossAsSuccess = FALSE`)
- `TransferRemoveRaceBug.cfg` - bug profile (`TreatLeaderLossAsSuccess = TRUE`)

## Properties

- `NoFalseSuccessAfterRemoval` invariant:
  - disallows successful transfer when target is no longer present and not leader.
- `TransferEventuallyResolves` liveness:
  - transfer reaches terminal success/failure.

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/transfer_remove_race"
java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-transfer-remove-fixed \
  TransferRemoveRace.tla -config TransferRemoveRace.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-transfer-remove-bug \
  TransferRemoveRace.tla -config TransferRemoveRaceBug.cfg
```

Expected:
- fixed config passes
- bug config violates `NoFalseSuccessAfterRemoval`
