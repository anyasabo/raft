# Transfer-To-NonVoter Model

This model captures an explicit leadership-transfer request to a node that has
already been demoted to non-voter.

## Why model this

If transfer completion treats "old leader lost leadership" as success without
checking that the target actually became leader, a transfer to non-voter can be
falsely reported as success while causing avoidable term churn.

## Files

- `TransferToNonVoter.tla` - core behavior model
- `TransferToNonVoter.cfg` - intended behavior (non-voter transfer resolves as failure)
- `TransferToNonVoterBug.cfg` - bug behavior (leader-loss treated as success)

## Properties

- `NoFalseSuccessForNonVoter` invariant:
  - disallows success when target is non-voter and never became leader
- `TransferResolves` liveness:
  - transfer eventually reaches succeeded or failed terminal state

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/transfer_nonvoter_target"
java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-transfer-nonvoter-fixed \
  TransferToNonVoter.tla -config TransferToNonVoter.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-transfer-nonvoter-bug \
  TransferToNonVoter.tla -config TransferToNonVoterBug.cfg
```

Expected:
- fixed config passes
- bug config violates `NoFalseSuccessForNonVoter`
