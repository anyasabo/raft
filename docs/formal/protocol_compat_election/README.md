# Protocol Compatibility Election Modeling Scope

This document prioritizes the next model area after snapshot catch-up.

## Goal

Model mixed-version election behavior where vote/pre-vote identity fields and
transfer semantics differ between legacy and modern protocol paths.

## Prioritized Risks

1. Candidate identity source mismatch (`Addr` vs `Candidate`)
   - High risk because known-leader gating and vote persistence depend on
     consistent candidate identity decoding.
2. Leadership-transfer flag compatibility
   - High risk because transfer elections intentionally bypass known-leader
     rejection, and dropped flags can cause liveness failures or false rejects.
3. Pre-vote candidate identity under older headers
   - Medium risk because `requestPreVote` uses `RPCHeader.Addr`, which can be
     absent or encoded differently in compatibility paths.

## Proposed Model Toggles

- `PreferAddrFieldWhenPresent`
- `DecodeLegacyCandidateAsAddr`
- `DropTransferFlagOnCompatPath`
- `RequireKnownLeaderGateForTransferVote`
- `PreVoteUsesLegacyCandidateFallback`

## Candidate Properties

- `VoteIdentityConsistent`:
  equivalent candidate identity must be interpreted consistently across
  protocol variants.
- `TransferBypassOnlyWithFlag`:
  vote grant bypass under known leader is allowed only when transfer flag is
  preserved end-to-end.
- `PreVoteKnownLeaderGateStable`:
  non-leader pre-vote remains rejected when a known leader exists, independent
  of mixed encoding.
- `NoSameTermDualLeader`:
  no two nodes become leader for the same term.

## Runtime Mapping (Deterministic Tests)

1. Vote request where `Addr` and legacy `Candidate` disagree:
   expect deterministic winner for identity decoding and no accidental grant.
2. Leadership transfer vote where compat layer drops transfer flag:
   expect transfer election to stall/fail in bug profile and succeed in fixed
   profile.
3. Pre-vote request with legacy candidate encoding under known leader:
   expect rejection to remain stable across protocol versions.

## Execution Order

1. Build `ProtocolCompatElection.tla` with one fixed config and one bug config
   per toggle.
2. Validate TLC sensitivity (fixed passes, each bug profile fails a targeted
   property).
3. Derive 1-2 deterministic tests from shortest counterexamples and add to
   `raft_test.go`.
