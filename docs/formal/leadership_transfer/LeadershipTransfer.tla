---- MODULE LeadershipTransfer ----
EXTENDS Naturals, TLC

CONSTANTS Nodes, OldLeader, Target, Other,
          BlockWritesAfterTimeoutNow, PreserveTransferVoteFlag

ASSUME Nodes = {OldLeader, Target, Other}
ASSUME OldLeader /= Target /\ OldLeader /= Other /\ Target /= Other

NodeState == {"Leader", "Follower"}

VARIABLES role, logIndex, currentTerm, knownLeader,
          transferInProgress, writesBlocked, timeoutNowSent,
          requestVoteLeadershipTransfer, transferOutcome,
          acceptedWritesDuringTransfer

vars == <<role, logIndex, currentTerm, knownLeader,
          transferInProgress, writesBlocked, timeoutNowSent,
          requestVoteLeadershipTransfer, transferOutcome,
          acceptedWritesDuringTransfer>>

Init ==
  /\ role = [n \in Nodes |-> IF n = OldLeader THEN "Leader" ELSE "Follower"]
  /\ logIndex = [n \in Nodes |-> 5]
  /\ currentTerm = 1
  /\ knownLeader = TRUE
  /\ transferInProgress = FALSE
  /\ writesBlocked = FALSE
  /\ timeoutNowSent = FALSE
  /\ requestVoteLeadershipTransfer = FALSE
  /\ transferOutcome = "none"
  /\ acceptedWritesDuringTransfer = 0

LeaderWriteBeforeTransfer ==
  /\ ~transferInProgress
  /\ role[OldLeader] = "Leader"
  /\ logIndex' = [logIndex EXCEPT ![OldLeader] = @ + 1]
  /\ UNCHANGED <<role, currentTerm, knownLeader, transferInProgress, writesBlocked,
                timeoutNowSent, requestVoteLeadershipTransfer, transferOutcome,
                acceptedWritesDuringTransfer>>

StartTransfer ==
  /\ ~transferInProgress
  /\ role[OldLeader] = "Leader"
  /\ transferOutcome = "none"
  /\ transferInProgress' = TRUE
  /\ writesBlocked' = BlockWritesAfterTimeoutNow
  /\ timeoutNowSent' = TRUE
  /\ requestVoteLeadershipTransfer' = TRUE
  /\ UNCHANGED <<role, logIndex, currentTerm, knownLeader, transferOutcome,
                acceptedWritesDuringTransfer>>

LoseTransferVoteFlag ==
  /\ transferInProgress
  /\ requestVoteLeadershipTransfer
  /\ ~PreserveTransferVoteFlag
  /\ requestVoteLeadershipTransfer' = FALSE
  /\ UNCHANGED <<role, logIndex, currentTerm, knownLeader, transferInProgress,
                writesBlocked, timeoutNowSent, transferOutcome,
                acceptedWritesDuringTransfer>>

ClientWriteOnOldLeader ==
  /\ transferInProgress
  /\ role[OldLeader] = "Leader"
  /\ ~writesBlocked
  /\ logIndex' = [logIndex EXCEPT ![OldLeader] = @ + 1]
  /\ acceptedWritesDuringTransfer' = acceptedWritesDuringTransfer + 1
  /\ UNCHANGED <<role, currentTerm, knownLeader, transferInProgress, writesBlocked,
                timeoutNowSent, requestVoteLeadershipTransfer, transferOutcome>>

GrantTransferVoteAndElectTarget ==
  /\ transferInProgress
  /\ timeoutNowSent
  /\ knownLeader
  /\ requestVoteLeadershipTransfer
  /\ role[Target] = "Follower"
  /\ logIndex[Target] >= logIndex[OldLeader]
  /\ logIndex[Target] >= logIndex[Other]
  /\ role' = [role EXCEPT ![OldLeader] = "Follower", ![Target] = "Leader"]
  /\ currentTerm' = currentTerm + 1
  /\ knownLeader' = TRUE
  /\ transferInProgress' = FALSE
  /\ writesBlocked' = FALSE
  /\ timeoutNowSent' = FALSE
  /\ requestVoteLeadershipTransfer' = FALSE
  /\ transferOutcome' = "success"
  /\ UNCHANGED <<logIndex, acceptedWritesDuringTransfer>>

TransferTimeout ==
  /\ transferInProgress
  /\ timeoutNowSent
  /\ transferInProgress' = FALSE
  /\ writesBlocked' = FALSE
  /\ timeoutNowSent' = FALSE
  /\ requestVoteLeadershipTransfer' = FALSE
  /\ transferOutcome' = "failed"
  /\ UNCHANGED <<role, logIndex, currentTerm, knownLeader, acceptedWritesDuringTransfer>>

PostResolutionWrite ==
  /\ transferOutcome # "none"
  /\ \E n \in Nodes : role[n] = "Leader"
  /\ LET leader == CHOOSE n \in Nodes : role[n] = "Leader" IN
     logIndex' = [logIndex EXCEPT ![leader] = @ + 1]
  /\ UNCHANGED <<role, currentTerm, knownLeader, transferInProgress, writesBlocked,
                timeoutNowSent, requestVoteLeadershipTransfer, transferOutcome,
                acceptedWritesDuringTransfer>>

ResolveTransfer ==
  GrantTransferVoteAndElectTarget \/ TransferTimeout

Next ==
  \/ LeaderWriteBeforeTransfer
  \/ StartTransfer
  \/ LoseTransferVoteFlag
  \/ ClientWriteOnOldLeader
  \/ GrantTransferVoteAndElectTarget
  \/ TransferTimeout
  \/ PostResolutionWrite

TypeInvariant ==
  /\ role \in [Nodes -> NodeState]
  /\ logIndex \in [Nodes -> Nat]
  /\ currentTerm \in Nat
  /\ knownLeader \in BOOLEAN
  /\ transferInProgress \in BOOLEAN
  /\ writesBlocked \in BOOLEAN
  /\ timeoutNowSent \in BOOLEAN
  /\ requestVoteLeadershipTransfer \in BOOLEAN
  /\ transferOutcome \in {"none", "success", "failed"}
  /\ acceptedWritesDuringTransfer \in Nat

NoWritesAcceptedDuringTransfer ==
  acceptedWritesDuringTransfer = 0

KnownLeaderRequiresTransferFlag ==
  transferInProgress /\ knownLeader /\ ~requestVoteLeadershipTransfer
    => role[Target] = "Follower"

TransferVoteRespectsLogFreshness ==
  transferInProgress /\ requestVoteLeadershipTransfer
    /\ (logIndex[Target] < logIndex[OldLeader] \/ logIndex[Target] < logIndex[Other])
    => role[Target] = "Follower"

TransferResolutionUnblocksWrites ==
  transferOutcome # "none" => /\ ~transferInProgress
                              /\ ~writesBlocked

TransferEventuallyResolves ==
  transferInProgress ~> (transferOutcome # "none")

FastConstraint ==
  TLCGet("level") < 35

BoundedLogConstraint ==
  /\ logIndex[OldLeader] <= 10
  /\ logIndex[Target] <= 10
  /\ logIndex[Other] <= 10

Spec ==
  Init /\ [][Next]_vars /\ WF_vars(ResolveTransfer)

THEOREM Spec => []TypeInvariant
====
