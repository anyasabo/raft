---- MODULE AppendConfigProcessFailure ----
EXTENDS Naturals

CONSTANTS RefreshLastLogOnConfigProcessFailure

VARIABLES lastLogIndex, lastLogTerm, storeLastIndex, storeLastTerm, storeAppended, configProcessFailed, tick

vars == <<lastLogIndex, lastLogTerm, storeLastIndex, storeLastTerm, storeAppended, configProcessFailed, tick>>

TypeOK ==
    /\ lastLogIndex \in Nat
    /\ lastLogTerm \in Nat
    /\ storeLastIndex \in Nat
    /\ storeLastTerm \in Nat
    /\ storeAppended \in BOOLEAN
    /\ configProcessFailed \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ lastLogIndex = 2
    /\ lastLogTerm = 1
    /\ storeLastIndex = 2
    /\ storeLastTerm = 1
    /\ storeAppended = FALSE
    /\ configProcessFailed = FALSE
    /\ tick = 0

AppendThenProcessFails ==
    /\ ~storeAppended
    /\ ~configProcessFailed
    /\ storeAppended' = TRUE
    /\ configProcessFailed' = TRUE
    /\ storeLastIndex' = 3
    /\ storeLastTerm' = 5
    /\ lastLogIndex' =
        IF RefreshLastLogOnConfigProcessFailure THEN storeLastIndex' ELSE lastLogIndex
    /\ lastLogTerm' =
        IF RefreshLastLogOnConfigProcessFailure THEN storeLastTerm' ELSE lastLogTerm
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<lastLogIndex, lastLogTerm, storeLastIndex, storeLastTerm, storeAppended, configProcessFailed>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ AppendThenProcessFails
    \/ Noop

LastLogMatchesStoreAfterConfigProcessFailure ==
    configProcessFailed => /\ lastLogIndex = storeLastIndex
                           /\ lastLogTerm = storeLastTerm

Spec ==
    /\ Init
    /\ [][Next]_vars

====
