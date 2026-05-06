---- MODULE ReplicationTransferSelection ----
EXTENDS Naturals

CONSTANTS IncludeNonVoterCandidates, StickyTargetAfterPick, PreferStaleIndices

Targets == {"None", "A", "B"}

VARIABLES nextA, nextB, isVoterA, isVoterB, target, backoffDone, catchupDone, demotedA, rebalancePickDone, postDemotionPickDone, tick

vars ==
    <<nextA, nextB, isVoterA, isVoterB, target, backoffDone, catchupDone,
      demotedA, rebalancePickDone, postDemotionPickDone, tick>>

TypeOK ==
    /\ nextA \in Nat
    /\ nextB \in Nat
    /\ isVoterA \in BOOLEAN
    /\ isVoterB \in BOOLEAN
    /\ target \in Targets
    /\ backoffDone \in BOOLEAN
    /\ catchupDone \in BOOLEAN
    /\ demotedA \in BOOLEAN
    /\ rebalancePickDone \in BOOLEAN
    /\ postDemotionPickDone \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ nextA = 10
    /\ nextB = 9
    /\ isVoterA = TRUE
    /\ isVoterB = TRUE
    /\ target = "None"
    /\ backoffDone = FALSE
    /\ catchupDone = FALSE
    /\ demotedA = FALSE
    /\ rebalancePickDone = FALSE
    /\ postDemotionPickDone = FALSE
    /\ tick = 0

EligibleA ==
    IncludeNonVoterCandidates \/ isVoterA

EligibleB ==
    IncludeNonVoterCandidates \/ isVoterB

EffectiveNextA ==
    IF PreferStaleIndices THEN 10 ELSE nextA

EffectiveNextB ==
    IF PreferStaleIndices THEN 9 ELSE nextB

ChooseTarget ==
    IF EligibleA /\ EligibleB THEN
        IF EffectiveNextA >= EffectiveNextB THEN "A" ELSE "B"
    ELSE IF EligibleA THEN
        "A"
    ELSE IF EligibleB THEN
        "B"
    ELSE
        "None"

PickTarget ==
    /\ target' =
        IF StickyTargetAfterPick /\ target # "None"
           THEN target
           ELSE ChooseTarget
    /\ rebalancePickDone' =
        IF backoffDone /\ catchupDone THEN TRUE ELSE rebalancePickDone
    /\ postDemotionPickDone' =
        IF demotedA THEN TRUE ELSE postDemotionPickDone
    /\ UNCHANGED <<nextA, nextB, isVoterA, isVoterB, backoffDone, catchupDone, demotedA>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

BackoffA ==
    /\ ~backoffDone
    /\ nextA' = 8
    /\ backoffDone' = TRUE
    /\ UNCHANGED <<nextB, isVoterA, isVoterB, target, catchupDone, demotedA, rebalancePickDone, postDemotionPickDone>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

CatchupB ==
    /\ ~catchupDone
    /\ nextB' = 11
    /\ catchupDone' = TRUE
    /\ UNCHANGED <<nextA, isVoterA, isVoterB, target, backoffDone, demotedA, rebalancePickDone, postDemotionPickDone>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

DemoteA ==
    /\ ~demotedA
    /\ demotedA' = TRUE
    /\ isVoterA' = FALSE
    /\ UNCHANGED <<nextA, nextB, isVoterB, target, backoffDone, catchupDone, rebalancePickDone, postDemotionPickDone>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<nextA, nextB, isVoterA, isVoterB, target, backoffDone, catchupDone, demotedA, rebalancePickDone, postDemotionPickDone>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ PickTarget
    \/ BackoffA
    \/ CatchupB
    \/ DemoteA
    \/ Noop

RebalancePickChoosesFreshest ==
    rebalancePickDone => target = "B"

PostDemotionPickSkipsA ==
    postDemotionPickDone => target # "A"

Spec ==
    /\ Init
    /\ [][Next]_vars

====
