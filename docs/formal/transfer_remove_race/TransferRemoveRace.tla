---- MODULE TransferRemoveRace ----
EXTENDS TLC

CONSTANTS TreatLeaderLossAsSuccess

VARIABLES oldLeaderState, targetState, targetPresent, transferState, voteGranted, termChanged, tick

vars == <<oldLeaderState, targetState, targetPresent, transferState, voteGranted, termChanged, tick>>

TypeOK ==
    /\ oldLeaderState \in {"Leader", "Follower"}
    /\ targetState \in {"Follower", "Candidate", "Leader"}
    /\ targetPresent \in BOOLEAN
    /\ transferState \in {"Idle", "InProgress", "Succeeded", "Failed"}
    /\ voteGranted \in BOOLEAN
    /\ termChanged \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ oldLeaderState = "Leader"
    /\ targetState = "Follower"
    /\ targetPresent = TRUE
    /\ transferState = "Idle"
    /\ voteGranted = FALSE
    /\ termChanged = FALSE
    /\ tick = 0

StartTransfer ==
    /\ transferState = "Idle"
    /\ oldLeaderState = "Leader"
    /\ transferState' = "InProgress"
    /\ voteGranted' = FALSE
    /\ UNCHANGED <<oldLeaderState, targetState, targetPresent, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

RemoveTarget ==
    /\ transferState = "InProgress"
    /\ targetPresent
    /\ targetPresent' = FALSE
    /\ UNCHANGED <<oldLeaderState, targetState, transferState, voteGranted, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

TimeoutNowCandidate ==
    /\ transferState = "InProgress"
    /\ targetState = "Follower"
    /\ targetState' = "Candidate"
    /\ UNCHANGED <<oldLeaderState, targetPresent, transferState, voteGranted, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

RequestVoteFromTarget ==
    /\ transferState = "InProgress"
    /\ targetState = "Candidate"
    /\ IF targetPresent THEN
          /\ voteGranted' = TRUE
          /\ UNCHANGED <<oldLeaderState, termChanged>>
       ELSE
          /\ voteGranted' = FALSE
          /\ oldLeaderState' = "Follower"
          /\ termChanged' = TRUE
    /\ UNCHANGED <<targetState, targetPresent, transferState>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

ElectTarget ==
    /\ transferState = "InProgress"
    /\ targetState = "Candidate"
    /\ targetPresent
    /\ voteGranted
    /\ targetState' = "Leader"
    /\ oldLeaderState' = "Follower"
    /\ transferState' = "Succeeded"
    /\ UNCHANGED <<targetPresent, voteGranted, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

FinishAfterLeaderLoss ==
    /\ transferState = "InProgress"
    /\ oldLeaderState = "Follower"
    /\ transferState' =
        IF TreatLeaderLossAsSuccess THEN "Succeeded" ELSE "Failed"
    /\ UNCHANGED <<oldLeaderState, targetState, targetPresent, voteGranted, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<oldLeaderState, targetState, targetPresent, transferState, voteGranted, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ StartTransfer
    \/ RemoveTarget
    \/ TimeoutNowCandidate
    \/ RequestVoteFromTarget
    \/ ElectTarget
    \/ FinishAfterLeaderLoss
    \/ Noop

NoFalseSuccessAfterRemoval ==
    ~(~targetPresent /\ transferState = "Succeeded" /\ targetState # "Leader")

TransferEventuallyResolves ==
    <> (transferState = "Succeeded" \/ transferState = "Failed")

Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ WF_vars(StartTransfer)
    /\ WF_vars(RemoveTarget)
    /\ WF_vars(TimeoutNowCandidate)
    /\ WF_vars(RequestVoteFromTarget)
    /\ WF_vars(ElectTarget)
    /\ WF_vars(FinishAfterLeaderLoss)

====
