---- MODULE TransferToNonVoter ----
EXTENDS TLC

CONSTANTS TargetIsVoter, TreatLostLeadershipAsSuccess

VARIABLES oldLeaderState, targetState, transferState, termChanged, tick

vars == <<oldLeaderState, targetState, transferState, termChanged, tick>>

TypeOK ==
    /\ oldLeaderState \in {"Leader", "Follower"}
    /\ targetState \in {"Follower", "Candidate", "Leader"}
    /\ transferState \in {"Idle", "InProgress", "Succeeded", "Failed"}
    /\ termChanged \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ oldLeaderState = "Leader"
    /\ targetState = "Follower"
    /\ transferState = "Idle"
    /\ termChanged = FALSE
    /\ tick = 0

StartTransfer ==
    /\ transferState = "Idle"
    /\ oldLeaderState = "Leader"
    /\ transferState' = "InProgress"
    /\ UNCHANGED <<oldLeaderState, targetState, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

TimeoutNowCandidate ==
    /\ transferState = "InProgress"
    /\ targetState = "Follower"
    /\ targetState' = "Candidate"
    /\ UNCHANGED <<oldLeaderState, transferState, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

RejectVoteAsNonVoter ==
    /\ transferState = "InProgress"
    /\ targetState = "Candidate"
    /\ ~TargetIsVoter
    /\ oldLeaderState = "Leader"
    /\ oldLeaderState' = "Follower"
    /\ termChanged' = TRUE
    /\ UNCHANGED <<targetState, transferState>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

ElectTarget ==
    /\ transferState = "InProgress"
    /\ targetState = "Candidate"
    /\ TargetIsVoter
    /\ targetState' = "Leader"
    /\ oldLeaderState' = "Follower"
    /\ transferState' = "Succeeded"
    /\ UNCHANGED termChanged
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

FinishAfterLeaderLoss ==
    /\ transferState = "InProgress"
    /\ oldLeaderState = "Follower"
    /\ transferState' =
        IF TreatLostLeadershipAsSuccess THEN "Succeeded" ELSE "Failed"
    /\ UNCHANGED <<oldLeaderState, targetState, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<oldLeaderState, targetState, transferState, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ StartTransfer
    \/ TimeoutNowCandidate
    \/ RejectVoteAsNonVoter
    \/ ElectTarget
    \/ FinishAfterLeaderLoss
    \/ Noop

NoFalseSuccessForNonVoter ==
    ~(~TargetIsVoter /\ transferState = "Succeeded" /\ targetState # "Leader")

TransferResolves ==
    <> (transferState = "Succeeded" \/ transferState = "Failed")

Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ WF_vars(StartTransfer)
    /\ WF_vars(TimeoutNowCandidate)
    /\ WF_vars(RejectVoteAsNonVoter)
    /\ WF_vars(ElectTarget)
    /\ WF_vars(FinishAfterLeaderLoss)

====
