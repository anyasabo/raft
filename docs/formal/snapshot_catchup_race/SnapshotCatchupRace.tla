---- MODULE SnapshotCatchupRace ----
EXTENDS Naturals, Integers

CONSTANTS LeaderTerm, ApplySnapshotAfterTermRegression, AllowConfigChangeDuringSnapshot, ResetKnownLeaderIncorrectly

VARIABLES followerTerm, maxTermSeen, snapshotTerm, snapshotInProgress, snapshotApplied, appliedSnapshotTerm, knownLeader, configVersion, configChangePending, snapshotConfigVersion, tick

vars ==
    <<followerTerm, maxTermSeen, snapshotTerm, snapshotInProgress, snapshotApplied,
      appliedSnapshotTerm, knownLeader, configVersion, configChangePending,
      snapshotConfigVersion, tick>>

TypeOK ==
    /\ LeaderTerm \in Nat \ {0}
    /\ followerTerm \in Nat \ {0}
    /\ maxTermSeen \in Nat \ {0}
    /\ snapshotTerm \in Nat \ {0}
    /\ snapshotInProgress \in BOOLEAN
    /\ snapshotApplied \in BOOLEAN
    /\ appliedSnapshotTerm \in Nat \cup {0}
    /\ knownLeader \in BOOLEAN
    /\ configVersion \in Nat
    /\ configChangePending \in BOOLEAN
    /\ snapshotConfigVersion \in Nat \cup {0}
    /\ tick \in {0, 1}

Init ==
    /\ followerTerm = LeaderTerm
    /\ maxTermSeen = LeaderTerm
    /\ snapshotTerm = LeaderTerm
    /\ snapshotInProgress = FALSE
    /\ snapshotApplied = FALSE
    /\ appliedSnapshotTerm = 0
    /\ knownLeader = TRUE
    /\ configVersion = 1
    /\ configChangePending = TRUE
    /\ snapshotConfigVersion = 0
    /\ tick = 0

StartSnapshot ==
    /\ ~snapshotInProgress
    /\ ~snapshotApplied
    /\ snapshotInProgress' = TRUE
    /\ snapshotConfigVersion' = configVersion
    /\ snapshotTerm' =
        IF ApplySnapshotAfterTermRegression
           THEN IF followerTerm = 1 THEN 1 ELSE followerTerm - 1
           ELSE followerTerm
    /\ UNCHANGED <<followerTerm, maxTermSeen, snapshotApplied, appliedSnapshotTerm,
                  knownLeader, configVersion, configChangePending>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

AdvanceConfig ==
    /\ configChangePending
    /\ (AllowConfigChangeDuringSnapshot \/ ~snapshotInProgress)
    /\ configVersion' = configVersion + 1
    /\ configChangePending' = FALSE
    /\ UNCHANGED <<followerTerm, maxTermSeen, snapshotTerm, snapshotInProgress,
                  snapshotApplied, appliedSnapshotTerm, knownLeader,
                  snapshotConfigVersion>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

ApplySnapshot ==
    /\ snapshotInProgress
    /\ snapshotInProgress' = FALSE
    /\ snapshotApplied' = TRUE
    /\ appliedSnapshotTerm' = snapshotTerm
    /\ followerTerm' =
        IF ApplySnapshotAfterTermRegression
           THEN snapshotTerm
           ELSE IF snapshotTerm > followerTerm THEN snapshotTerm ELSE followerTerm
    /\ maxTermSeen' =
        IF followerTerm' > maxTermSeen THEN followerTerm' ELSE maxTermSeen
    /\ knownLeader' =
        IF ResetKnownLeaderIncorrectly THEN FALSE ELSE knownLeader
    /\ UNCHANGED <<snapshotTerm, configVersion, configChangePending,
                  snapshotConfigVersion>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

ObserveLeader ==
    /\ ~knownLeader
    /\ knownLeader' = TRUE
    /\ followerTerm' = IF LeaderTerm > followerTerm THEN LeaderTerm ELSE followerTerm
    /\ maxTermSeen' = IF followerTerm' > maxTermSeen THEN followerTerm' ELSE maxTermSeen
    /\ UNCHANGED <<snapshotTerm, snapshotInProgress, snapshotApplied,
                  appliedSnapshotTerm, configVersion, configChangePending,
                  snapshotConfigVersion>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<followerTerm, maxTermSeen, snapshotTerm, snapshotInProgress,
                  snapshotApplied, appliedSnapshotTerm, knownLeader, configVersion,
                  configChangePending, snapshotConfigVersion>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ StartSnapshot
    \/ AdvanceConfig
    \/ ApplySnapshot
    \/ ObserveLeader
    \/ Noop

NoTermRegression ==
    followerTerm >= maxTermSeen

ConfigStableDuringSnapshot ==
    snapshotInProgress => configVersion = snapshotConfigVersion

KnownLeaderRetainedAfterSnapshot ==
    snapshotApplied => knownLeader

CatchupEventuallyVisible ==
    <> (snapshotApplied /\ followerTerm >= LeaderTerm)

Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ WF_vars(StartSnapshot)
    /\ WF_vars(AdvanceConfig)
    /\ WF_vars(ApplySnapshot)
    /\ WF_vars(ObserveLeader)

====
