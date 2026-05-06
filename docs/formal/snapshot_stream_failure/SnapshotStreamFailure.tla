---- MODULE SnapshotStreamFailure ----
EXTENDS Naturals

CONSTANTS AdvanceSnapshotOnShortRead, AdvanceLastAppliedOnShortRead

VARIABLES lastSnapshotIndex, lastApplied, shortReadSeen, failed, tick

vars == <<lastSnapshotIndex, lastApplied, shortReadSeen, failed, tick>>

TypeOK ==
    /\ lastSnapshotIndex \in Nat
    /\ lastApplied \in Nat
    /\ shortReadSeen \in BOOLEAN
    /\ failed \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ lastSnapshotIndex = 100
    /\ lastApplied = 100
    /\ shortReadSeen = FALSE
    /\ failed = FALSE
    /\ tick = 0

ShortReadFailure ==
    /\ ~shortReadSeen
    /\ shortReadSeen' = TRUE
    /\ failed' = TRUE
    /\ lastSnapshotIndex' =
        IF AdvanceSnapshotOnShortRead THEN 120 ELSE lastSnapshotIndex
    /\ lastApplied' =
        IF AdvanceLastAppliedOnShortRead THEN 120 ELSE lastApplied
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<lastSnapshotIndex, lastApplied, shortReadSeen, failed>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ ShortReadFailure
    \/ Noop

ShortReadDoesNotAdvanceSnapshot ==
    shortReadSeen => lastSnapshotIndex = 100

ShortReadDoesNotAdvanceLastApplied ==
    shortReadSeen => lastApplied = 100

Spec ==
    /\ Init
    /\ [][Next]_vars

====
