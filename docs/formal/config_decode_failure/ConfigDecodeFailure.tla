---- MODULE ConfigDecodeFailure ----
EXTENDS Naturals

CONSTANTS PanicOnDecodeFailure

VARIABLES decodeFailed, rpcResponded, success, panic, tick

vars == <<decodeFailed, rpcResponded, success, panic, tick>>

TypeOK ==
    /\ decodeFailed \in BOOLEAN
    /\ rpcResponded \in BOOLEAN
    /\ success \in BOOLEAN
    /\ panic \in BOOLEAN
    /\ tick \in {0, 1}

Init ==
    /\ decodeFailed = FALSE
    /\ rpcResponded = FALSE
    /\ success = FALSE
    /\ panic = FALSE
    /\ tick = 0

ReceiveMalformedConfig ==
    /\ ~decodeFailed
    /\ decodeFailed' = TRUE
    /\ panic' = PanicOnDecodeFailure
    /\ rpcResponded' = ~PanicOnDecodeFailure
    /\ success' = FALSE
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Noop ==
    /\ UNCHANGED <<decodeFailed, rpcResponded, success, panic>>
    /\ tick' = IF tick = 0 THEN 1 ELSE 0

Next ==
    \/ ReceiveMalformedConfig
    \/ Noop

MalformedConfigNeverPanics ==
    decodeFailed => ~panic

MalformedConfigGetsFailureResponse ==
    decodeFailed => /\ rpcResponded
                    /\ ~success

Spec ==
    /\ Init
    /\ [][Next]_vars

====
