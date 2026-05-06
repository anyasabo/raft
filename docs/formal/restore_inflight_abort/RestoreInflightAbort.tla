---- MODULE RestoreInflightAbort ----
EXTENDS Naturals

CONSTANTS AbortInflightOnRestore, ClearInflightQueue

VARIABLES inflightCount, abortedCount, restoreStarted, restoreFailed, tick

vars == <<inflightCount, abortedCount, restoreStarted, restoreFailed, tick>>

TypeOK ==
    /\ inflightCount \in Nat
    /\ abortedCount \in Nat
    /\ restoreStarted \in BOOLEAN
    /\ restoreFailed \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ inflightCount = 2
    /\ abortedCount = 0
    /\ restoreStarted = FALSE
    /\ restoreFailed = FALSE
    /\ tick = 0

StartRestore ==
    /\ ~restoreStarted
    /\ restoreStarted' = TRUE
    /\ restoreFailed' = TRUE
    /\ abortedCount' =
        IF AbortInflightOnRestore THEN inflightCount ELSE abortedCount
    /\ inflightCount' =
        IF AbortInflightOnRestore /\ ClearInflightQueue THEN 0 ELSE inflightCount
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<inflightCount, abortedCount, restoreStarted, restoreFailed>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ StartRestore
    \/ Noop

RestoreAbortsAllInflight ==
    restoreStarted => abortedCount = 2

RestoreClearsInflightQueue ==
    restoreStarted => inflightCount = 0

Spec ==
    /\ Init
    /\ [][Next]_vars

====
