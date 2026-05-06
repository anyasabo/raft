---- MODULE ProtocolCompatElection ----
EXTENDS Naturals

CONSTANTS LeaderAddr, CandidateAddr, LegacyCandidateAddr, PreferAddrFieldWhenPresent, DropTransferFlagOnCompatPath, PreVoteUsesLegacyCandidateFallback

Addresses == {LeaderAddr, CandidateAddr, LegacyCandidateAddr}

VARIABLES knownLeader, addrFieldPresent, legacyOnlyScenario, resolvedCandidate, voteGranted, voteAttempted, preVoteGranted, tick

vars == <<knownLeader, addrFieldPresent, legacyOnlyScenario, resolvedCandidate, voteGranted, voteAttempted, preVoteGranted, tick>>

TypeOK ==
    /\ knownLeader \in BOOLEAN
    /\ addrFieldPresent \in BOOLEAN
    /\ legacyOnlyScenario \in BOOLEAN
    /\ resolvedCandidate \in Addresses
    /\ voteGranted \in BOOLEAN
    /\ voteAttempted \in BOOLEAN
    /\ preVoteGranted \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ knownLeader = TRUE
    /\ addrFieldPresent = TRUE
    /\ legacyOnlyScenario = FALSE
    /\ resolvedCandidate = CandidateAddr
    /\ voteGranted = FALSE
    /\ voteAttempted = FALSE
    /\ preVoteGranted = FALSE
    /\ tick = 0

ResolveVoteIdentity ==
    /\ resolvedCandidate' =
        IF addrFieldPresent /\ PreferAddrFieldWhenPresent
           THEN CandidateAddr
           ELSE LegacyCandidateAddr
    /\ UNCHANGED <<knownLeader, addrFieldPresent, legacyOnlyScenario, voteGranted, voteAttempted, preVoteGranted>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

RequestVoteDuringTransfer ==
    /\ ~voteGranted
    /\ voteAttempted' = TRUE
    /\ voteGranted' =
        IF knownLeader /\ resolvedCandidate # LeaderAddr /\ DropTransferFlagOnCompatPath
           THEN FALSE
           ELSE TRUE
    /\ UNCHANGED <<knownLeader, addrFieldPresent, legacyOnlyScenario, resolvedCandidate, preVoteGranted>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

EnterLegacyOnlyPreVoteScenario ==
    /\ ~legacyOnlyScenario
    /\ legacyOnlyScenario' = TRUE
    /\ addrFieldPresent' = FALSE
    /\ preVoteGranted' = FALSE
    /\ UNCHANGED <<knownLeader, resolvedCandidate, voteGranted, voteAttempted>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

HandlePreVote ==
    /\ legacyOnlyScenario
    /\ preVoteGranted' =
        IF knownLeader /\
           (IF addrFieldPresent
               THEN CandidateAddr
               ELSE IF PreVoteUsesLegacyCandidateFallback
                       THEN LegacyCandidateAddr
                       ELSE LeaderAddr) # LeaderAddr
           THEN FALSE
           ELSE TRUE
    /\ UNCHANGED <<knownLeader, addrFieldPresent, legacyOnlyScenario, resolvedCandidate, voteGranted, voteAttempted>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<knownLeader, addrFieldPresent, legacyOnlyScenario, resolvedCandidate, voteGranted, voteAttempted, preVoteGranted>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ ResolveVoteIdentity
    \/ RequestVoteDuringTransfer
    \/ EnterLegacyOnlyPreVoteScenario
    \/ HandlePreVote
    \/ Noop

VoteIdentityConsistent ==
    (addrFieldPresent /\ CandidateAddr # LegacyCandidateAddr) => resolvedCandidate = CandidateAddr

PreVoteKnownLeaderGateStable ==
    ~(legacyOnlyScenario /\ knownLeader /\ LegacyCandidateAddr # LeaderAddr /\ preVoteGranted)

TransferVoteGrantedAfterRequest ==
    ~(voteAttempted /\ knownLeader /\ resolvedCandidate # LeaderAddr /\ ~voteGranted)

Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ WF_vars(ResolveVoteIdentity)
    /\ WF_vars(RequestVoteDuringTransfer)
    /\ WF_vars(EnterLegacyOnlyPreVoteScenario)
    /\ WF_vars(HandlePreVote)

====
