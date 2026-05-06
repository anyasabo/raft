---- MODULE AppendPrevLogSnapshotBoundary ----
EXTENDS Naturals

CONSTANTS UseSnapshotBoundaryTerm, AssumeMatchBeforeSnapshot

VARIABLES snapshotIndex, snapshotTerm, prevLogEntry, prevLogTerm, accepted, evaluated, tick

vars == <<snapshotIndex, snapshotTerm, prevLogEntry, prevLogTerm, accepted, evaluated, tick>>

TypeOK ==
    /\ snapshotIndex \in Nat
    /\ snapshotTerm \in Nat
    /\ prevLogEntry \in Nat
    /\ prevLogTerm \in Nat
    /\ accepted \in BOOLEAN
    /\ evaluated \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ snapshotIndex = 100
    /\ snapshotTerm = 5
    /\ prevLogEntry = 100
    /\ prevLogTerm = 5
    /\ accepted = FALSE
    /\ evaluated = FALSE
    /\ tick = 0

EvaluatePrevLog ==
    /\ ~evaluated
    /\ accepted' =
        IF prevLogEntry < snapshotIndex THEN
            AssumeMatchBeforeSnapshot
        ELSE IF prevLogEntry = snapshotIndex THEN
            UseSnapshotBoundaryTerm /\ (prevLogTerm = snapshotTerm)
        ELSE
            FALSE
    /\ evaluated' = TRUE
    /\ UNCHANGED <<snapshotIndex, snapshotTerm, prevLogEntry, prevLogTerm>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<snapshotIndex, snapshotTerm, prevLogEntry, prevLogTerm, accepted, evaluated>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ EvaluatePrevLog
    \/ Noop

SnapshotBoundaryAcceptsMatchingTerm ==
    (evaluated /\ prevLogEntry = snapshotIndex /\ prevLogTerm = snapshotTerm) => accepted

Spec ==
    /\ Init
    /\ [][Next]_vars

====
