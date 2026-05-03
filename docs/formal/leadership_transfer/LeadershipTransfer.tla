---- MODULE LeadershipTransfer ----
EXTENDS Naturals, TLC

CONSTANTS Nodes, OldLeader, Target, Other, BlockWritesAfterTimeoutNow

ASSUME Nodes = {OldLeader, Target, Other}
ASSUME OldLeader /= Target /\ OldLeader /= Other /\ Target /= Other

NodeState == {"Leader", "Follower"}

VARIABLES role, logIndex, transferInProgress, writesBlocked,
          timeoutNowSent, transferOutcome, acceptedWritesDuringTransfer

vars == <<role, logIndex, transferInProgress, writesBlocked,
          timeoutNowSent, transferOutcome, acceptedWritesDuringTransfer>>

Init ==
  /\ role = [n \in Nodes |-> IF n = OldLeader THEN "Leader" ELSE "Follower"]
  /\ logIndex = [n \in Nodes |-> 5]
  /\ transferInProgress = FALSE
  /\ writesBlocked = FALSE
  /\ timeoutNowSent = FALSE
  /\ transferOutcome = "none"
  /\ acceptedWritesDuringTransfer = 0

StartTransfer ==
  /\ ~transferInProgress
  /\ role[OldLeader] = "Leader"
  /\ transferOutcome = "none"
  /\ transferInProgress' = TRUE
  /\ writesBlocked' = BlockWritesAfterTimeoutNow
  /\ timeoutNowSent' = TRUE
  /\ UNCHANGED <<role, logIndex, transferOutcome, acceptedWritesDuringTransfer>>

ClientWriteOnOldLeader ==
  /\ transferInProgress
  /\ role[OldLeader] = "Leader"
  /\ ~writesBlocked
  /\ logIndex' = [logIndex EXCEPT ![OldLeader] = @ + 1]
  /\ acceptedWritesDuringTransfer' = acceptedWritesDuringTransfer + 1
  /\ UNCHANGED <<role, transferInProgress, writesBlocked, timeoutNowSent, transferOutcome>>

TargetWinsElection ==
  /\ transferInProgress
  /\ timeoutNowSent
  /\ role[Target] = "Follower"
  /\ logIndex[Target] >= logIndex[Other]
  /\ logIndex[Target] >= logIndex[OldLeader]
  /\ role' = [role EXCEPT ![OldLeader] = "Follower", ![Target] = "Leader"]
  /\ transferInProgress' = FALSE
  /\ writesBlocked' = FALSE
  /\ transferOutcome' = "success"
  /\ UNCHANGED <<logIndex, timeoutNowSent, acceptedWritesDuringTransfer>>

TargetLosesElection ==
  /\ transferInProgress
  /\ timeoutNowSent
  /\ logIndex[Target] < logIndex[OldLeader]
  /\ transferInProgress' = FALSE
  /\ writesBlocked' = FALSE
  /\ transferOutcome' = "failed"
  /\ UNCHANGED <<role, logIndex, timeoutNowSent, acceptedWritesDuringTransfer>>

TransferTimeout ==
  /\ transferInProgress
  /\ timeoutNowSent
  /\ transferInProgress' = FALSE
  /\ writesBlocked' = FALSE
  /\ transferOutcome' = "failed"
  /\ UNCHANGED <<role, logIndex, timeoutNowSent, acceptedWritesDuringTransfer>>

PostResolutionWrite ==
  /\ transferOutcome # "none"
  /\ \E n \in Nodes : role[n] = "Leader"
  /\ LET leader == CHOOSE n \in Nodes : role[n] = "Leader" IN
     logIndex' = [logIndex EXCEPT ![leader] = @ + 1]
  /\ UNCHANGED <<role, transferInProgress, writesBlocked, timeoutNowSent, transferOutcome, acceptedWritesDuringTransfer>>

Next ==
  \/ StartTransfer
  \/ ClientWriteOnOldLeader
  \/ TargetWinsElection
  \/ TargetLosesElection
  \/ TransferTimeout
  \/ PostResolutionWrite

TypeInvariant ==
  /\ role \in [Nodes -> NodeState]
  /\ logIndex \in [Nodes -> Nat]
  /\ transferInProgress \in BOOLEAN
  /\ writesBlocked \in BOOLEAN
  /\ timeoutNowSent \in BOOLEAN
  /\ transferOutcome \in {"none", "success", "failed"}
  /\ acceptedWritesDuringTransfer \in Nat

NoWritesAcceptedDuringTransfer ==
  acceptedWritesDuringTransfer = 0

TransferResolutionUnblocksWrites ==
  transferOutcome # "none" => /\ ~transferInProgress
                              /\ ~writesBlocked

TransferEventuallyResolves ==
  transferInProgress ~> (transferOutcome # "none")

Spec == Init /\ [][Next]_vars

THEOREM Spec => []TypeInvariant
====
