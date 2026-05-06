# Config Decode Failure Model

This model captures behavior when untrusted configuration bytes fail to decode
in RPC handlers.

## Why this matters

Malformed configuration payloads from network RPCs should produce a normal
error response, not a panic. Panics turn a recoverable protocol error into
process termination.

## Files

- `ConfigDecodeFailure.tla` - core model
- `ConfigDecodeFailure.cfg` - intended behavior (expected pass)
- `ConfigDecodeFailureBug.cfg` - panic-on-decode bug profile

## Properties

- `MalformedConfigNeverPanics`
- `MalformedConfigGetsFailureResponse`

## Run TLC

```bash
cd "$(git rev-parse --show-toplevel)/docs/formal/config_decode_failure"

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-config-decode-fixed \
  ConfigDecodeFailure.tla -config ConfigDecodeFailure.cfg

java -XX:+UseParallelGC -cp "../tools/tla2tools-v1.8.0.jar" tlc2.TLC \
  -workers 4 -cleanup -metadir /tmp/tlc-config-decode-bug \
  ConfigDecodeFailure.tla -config ConfigDecodeFailureBug.cfg
```

Expected:

- fixed config passes all checks
- bug config violates `MalformedConfigNeverPanics`
