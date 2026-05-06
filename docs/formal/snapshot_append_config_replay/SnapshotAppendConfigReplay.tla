---- MODULE SnapshotAppendConfigReplay ----
EXTENDS Naturals

CONSTANTS RollbackLatestOnConflictAfterSnapshot

VARIABLES committedCfgIndex, latestCfgIndex, sawUncommittedConfig, conflictTruncated, tick

vars == <<committedCfgIndex, latestCfgIndex, sawUncommittedConfig, conflictTruncated, tick>>

TypeOK ==
    /\ committedCfgIndex \in Nat
    /\ latestCfgIndex \in Nat
    /\ sawUncommittedConfig \in BOOLEAN
    /\ conflictTruncated \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ committedCfgIndex = 100
    /\ latestCfgIndex = 100
    /\ sawUncommittedConfig = FALSE
    /\ conflictTruncated = FALSE
    /\ tick = 0

AppendUncommittedConfig ==
    /\ ~sawUncommittedConfig
    /\ sawUncommittedConfig' = TRUE
    /\ latestCfgIndex' = 101
    /\ UNCHANGED <<committedCfgIndex, conflictTruncated>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

TruncateConflictAcrossConfig ==
    /\ sawUncommittedConfig
    /\ ~conflictTruncated
    /\ conflictTruncated' = TRUE
    /\ latestCfgIndex' =
        IF RollbackLatestOnConflictAfterSnapshot
           THEN committedCfgIndex
           ELSE latestCfgIndex
    /\ UNCHANGED <<committedCfgIndex, sawUncommittedConfig>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<committedCfgIndex, latestCfgIndex, sawUncommittedConfig, conflictTruncated>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ AppendUncommittedConfig
    \/ TruncateConflictAcrossConfig
    \/ Noop

LatestConfigRollsBackAfterConflict ==
    conflictTruncated => latestCfgIndex = committedCfgIndex

Spec ==
    /\ Init
    /\ [][Next]_vars

====
