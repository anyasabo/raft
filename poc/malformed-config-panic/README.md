# Raft malformed-config panic PoC

This is a standalone reproducer for the malformed configuration decode panic class in `hashicorp/raft`.
It flips one bit in a valid encoded `Configuration`, then sends that payload through real Raft TCP RPCs.

## What this demonstrates

- A payload can be malformed at the semantic decode level while still passing:
  - outer RPC envelope decoding,
  - protocol/version checks,
  - snapshot transfer size checks (`req.Size` / `io.Copy`),
  - transport framing.
- In vulnerable code paths, this can trigger panic-on-decode behavior in append/snapshot handlers.

## Why a bit flip can evade other guards

`InstallSnapshotRequest.Configuration` and config-entry `Log.Data` are opaque `[]byte` until explicitly decoded as `Configuration`.

1. RPC envelope decode validates field structure/types, not meaning of nested config blob.
2. Snapshot length checks prove byte-count integrity, not payload schema correctness.
3. Version checks prove compatibility class, not that bytes decode into a valid `Configuration`.
4. CRC checks in file snapshot stores are local at-open checks; they do not validate arbitrary inbound RPC config blobs.

## Build

From the repo root:

```bash
go build -o ./poc/malformed-config-panic/poc ./poc/malformed-config-panic
```

## Run

Two terminals:

Terminal 1:

```bash
./poc/malformed-config-panic/poc follower 127.0.0.1:13000
```

Terminal 2:

```bash
./poc/malformed-config-panic/poc inject-append 127.0.0.1:13000
./poc/malformed-config-panic/poc inject-snapshot 127.0.0.1:13000
```

Or use the one-shot script:

```bash
chmod +x ./poc/malformed-config-panic/demo.sh
./poc/malformed-config-panic/demo.sh append
./poc/malformed-config-panic/demo.sh snapshot
```

`demo.sh` prints whether the follower stayed alive and whether a panic was observed.
