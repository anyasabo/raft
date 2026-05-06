---- MODULE ConfigTruncationRollback ----
EXTENDS Naturals

CONSTANTS RollbackLatestConfigOnTruncate

VARIABLES committedIndex, latestIndex, conflictTruncated, tick

vars == <<committedIndex, latestIndex, conflictTruncated, tick>>

TypeOK ==
    /\ committedIndex \in Nat
    /\ latestIndex \in Nat
    /\ conflictTruncated \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ committedIndex = 1
    /\ latestIndex = 5
    /\ conflictTruncated = FALSE
    /\ tick = 0

TruncateConflictSuffix ==
    /\ ~conflictTruncated
    /\ conflictTruncated' = TRUE
    /\ latestIndex' =
        IF RollbackLatestConfigOnTruncate
           THEN committedIndex
           ELSE latestIndex
    /\ UNCHANGED committedIndex
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<committedIndex, latestIndex, conflictTruncated>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ TruncateConflictSuffix
    \/ Noop

LatestConfigNotAheadAfterTruncate ==
    conflictTruncated => latestIndex = committedIndex

Spec ==
    /\ Init
    /\ [][Next]_vars

====
