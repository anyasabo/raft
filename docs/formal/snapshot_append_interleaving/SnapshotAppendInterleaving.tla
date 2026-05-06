---- MODULE SnapshotAppendInterleaving ----
EXTENDS Naturals

CONSTANTS RegressTermOnStaleAppend, OverwriteLeaderOnStaleAppend, RegressCommitOnStaleAppend

Leaders == {"SnapshotLeader", "StaleLeader"}

VARIABLES term, leader, commitIndex, snapshotInstalled, staleAppendSeen, tick

vars == <<term, leader, commitIndex, snapshotInstalled, staleAppendSeen, tick>>

TypeOK ==
    /\ term \in Nat
    /\ leader \in Leaders
    /\ commitIndex \in Nat
    /\ snapshotInstalled \in BOOLEAN
    /\ staleAppendSeen \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ term = 5
    /\ leader = "SnapshotLeader"
    /\ commitIndex = 100
    /\ snapshotInstalled = TRUE
    /\ staleAppendSeen = FALSE
    /\ tick = 0

StaleAppendAfterSnapshot ==
    /\ snapshotInstalled
    /\ ~staleAppendSeen
    /\ term' = IF RegressTermOnStaleAppend THEN 4 ELSE term
    /\ leader' = IF OverwriteLeaderOnStaleAppend THEN "StaleLeader" ELSE leader
    /\ commitIndex' = IF RegressCommitOnStaleAppend THEN 90 ELSE commitIndex
    /\ staleAppendSeen' = TRUE
    /\ UNCHANGED snapshotInstalled
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<term, leader, commitIndex, snapshotInstalled, staleAppendSeen>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ StaleAppendAfterSnapshot
    \/ Noop

TermNeverRegresses ==
    term >= 5

LeaderStableAfterStaleAppend ==
    staleAppendSeen => leader = "SnapshotLeader"

CommitIndexNeverRegresses ==
    commitIndex >= 100

Spec ==
    /\ Init
    /\ [][Next]_vars

====
