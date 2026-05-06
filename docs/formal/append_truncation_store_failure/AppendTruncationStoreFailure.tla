---- MODULE AppendTruncationStoreFailure ----
EXTENDS Naturals

CONSTANTS RecomputeLastLogOnStoreFailure

VARIABLES lastLogIndex, lastLogTerm, storeLastIndex, storeLastTerm, storeFailed, tick

vars == <<lastLogIndex, lastLogTerm, storeLastIndex, storeLastTerm, storeFailed, tick>>

TypeOK ==
    /\ lastLogIndex \in Nat
    /\ lastLogTerm \in Nat
    /\ storeLastIndex \in Nat
    /\ storeLastTerm \in Nat
    /\ storeFailed \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ lastLogIndex = 5
    /\ lastLogTerm = 1
    /\ storeLastIndex = 5
    /\ storeLastTerm = 1
    /\ storeFailed = FALSE
    /\ tick = 0

TruncateThenStoreFail ==
    /\ ~storeFailed
    /\ storeFailed' = TRUE
    /\ storeLastIndex' = 2
    /\ storeLastTerm' = 1
    /\ lastLogIndex' =
        IF RecomputeLastLogOnStoreFailure THEN storeLastIndex' ELSE lastLogIndex
    /\ lastLogTerm' =
        IF RecomputeLastLogOnStoreFailure THEN storeLastTerm' ELSE lastLogTerm
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<lastLogIndex, lastLogTerm, storeLastIndex, storeLastTerm, storeFailed>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ TruncateThenStoreFail
    \/ Noop

LastLogMatchesStoreAfterFailure ==
    storeFailed => /\ lastLogIndex = storeLastIndex
                   /\ lastLogTerm = storeLastTerm

Spec ==
    /\ Init
    /\ [][Next]_vars

====
