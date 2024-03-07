#lang forge/temporal

option max_tracelength 10

/*
T1: read counter (0)
T2: read counter (0)
T1: adds 1 to value (1)
T1: write new value to counter 
T2: adds 1 to value (1)
T2: write new value to counter (1)
*/

/*
  Abstract algorithm: both threads running this code 

  while(true) {
    // location: uninterested 
    this.flag = true
    // location: waiting 
    while(other.flag == true) {} // hold until their flag is lowered
    // location: in CS 
    run_critical_section_code(); // don't care details
    this.flag = false
  }
*/

abstract sig Location {}
one sig Uninterested, Waiting, InCS extends Location {}

-- We might also call this "Process" in the notes; in the 
-- _abstract_ these are the same. 
abstract sig Thread {} 
one sig ThreadA, ThreadB extends Thread {} 

-- State of the locking algorithm (AND the threads' locations)
-- "quick" conversion to temporal mode
one sig World {
  var loc: func Thread -> Location,
  var flags: set Thread
}

-- are we in an initial state RIGHT NOW?
pred init {
    all t: Thread | { World.loc[t] = Uninterested }
    no World.flags
}

pred raise[t: Thread] {
    -- GUARD
    World.loc[t] = Uninterested 
    -- ACTION
    World.loc'[t] = Waiting
    World.flags' = World.flags + t -- also a bit of framing, because =
    -- FRAME
    all t2: Thread - t | World.loc'[t2] = World.loc[t2]
}

pred enter[t: Thread] {
    -- GUARD
    World.loc[t] = Waiting
    World.flags in t -- no other processes
    -- ACTION
    World.loc'[t] = InCS
    -- FRAME
    World.flags' = World.flags
    all t2: Thread - t | World.loc'[t2] = World.loc[t2]
}

pred leave[t: Thread] {
    -- GUARD
    World.loc[t] = InCS
    -- ACTION
    World.loc'[t] = Uninterested
    World.flags' = World.flags - t
    -- FRAME
    all t2: Thread - t | World.loc'[t2] = World.loc[t2]
}

-- Combine all transitions. In the past, we'd call this anyTransition 
-- or something like that.
pred delta { 
    some t: Thread | {
        raise[t] or 
        enter[t] or 
        leave[t] 
    }
}

run {
    init
    always { delta }
}
