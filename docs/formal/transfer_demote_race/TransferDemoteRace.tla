---- MODULE TransferDemoteRace ----
EXTENDS TLC

CONSTANTS TreatLeaderLossAsSuccess

Suffrage == {"Voter", "Nonvoter"}

VARIABLES oldLeaderState, targetState, targetSuffrage, transferState, voteGranted, termChanged, tick

vars == <<oldLeaderState, targetState, targetSuffrage, transferState, voteGranted, termChanged, tick>>

TypeOK ==
    /\ oldLeaderState \in {"Leader", "Follower"}
    /\ targetState \in {"Follower", "Candidate", "Leader"}
    /\ targetSuffrage \in Suffrage
    /\ transferState \in {"Idle", "InProgress", "Succeeded", "Failed"}
    /\ voteGranted \in BOOLEAN
    /\ termChanged \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ oldLeaderState = "Leader"
    /\ targetState = "Follower"
    /\ targetSuffrage = "Voter"
    /\ transferState = "Idle"
    /\ voteGranted = FALSE
    /\ termChanged = FALSE
    /\ tick = 0

StartTransfer ==
    /\ transferState = "Idle"
    /\ oldLeaderState = "Leader"
    /\ transferState' = "InProgress"
    /\ voteGranted' = FALSE
    /\ UNCHANGED <<oldLeaderState, targetState, targetSuffrage, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

DemoteTarget ==
    /\ transferState = "InProgress"
    /\ targetSuffrage = "Voter"
    /\ targetSuffrage' = "Nonvoter"
    /\ UNCHANGED <<oldLeaderState, targetState, transferState, voteGranted, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

TimeoutNowCandidate ==
    /\ transferState = "InProgress"
    /\ targetState = "Follower"
    /\ targetState' = "Candidate"
    /\ UNCHANGED <<oldLeaderState, targetSuffrage, transferState, voteGranted, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

RequestVoteFromTarget ==
    /\ transferState = "InProgress"
    /\ targetState = "Candidate"
    /\ IF targetSuffrage = "Voter" THEN
          /\ voteGranted' = TRUE
          /\ UNCHANGED <<oldLeaderState, termChanged>>
       ELSE
          /\ voteGranted' = FALSE
          /\ oldLeaderState' = "Follower"
          /\ termChanged' = TRUE
    /\ UNCHANGED <<targetState, targetSuffrage, transferState>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

ElectTarget ==
    /\ transferState = "InProgress"
    /\ voteGranted
    /\ targetSuffrage = "Voter"
    /\ targetState = "Candidate"
    /\ targetState' = "Leader"
    /\ oldLeaderState' = "Follower"
    /\ transferState' = "Succeeded"
    /\ UNCHANGED <<targetSuffrage, voteGranted, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

FinishAfterLeaderLoss ==
    /\ transferState = "InProgress"
    /\ oldLeaderState = "Follower"
    /\ transferState' =
        IF TreatLeaderLossAsSuccess THEN "Succeeded" ELSE "Failed"
    /\ UNCHANGED <<oldLeaderState, targetState, targetSuffrage, voteGranted, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<oldLeaderState, targetState, targetSuffrage, transferState, voteGranted, termChanged>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ StartTransfer
    \/ DemoteTarget
    \/ TimeoutNowCandidate
    \/ RequestVoteFromTarget
    \/ ElectTarget
    \/ FinishAfterLeaderLoss
    \/ Noop

NoFalseSuccessAfterDemotion ==
    ~(
      targetSuffrage = "Nonvoter"
        /\ transferState = "Succeeded"
        /\ targetState # "Leader"
    )

TransferEventuallyResolves ==
    <> (transferState = "Succeeded" \/ transferState = "Failed")

Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ WF_vars(StartTransfer)
    /\ WF_vars(DemoteTarget)
    /\ WF_vars(TimeoutNowCandidate)
    /\ WF_vars(RequestVoteFromTarget)
    /\ WF_vars(ElectTarget)
    /\ WF_vars(FinishAfterLeaderLoss)

====
