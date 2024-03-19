# Peterson Lock and Fairness

Let's fix the broken locking algorithm we modeled before. We'll also talk about improving testing, modeling pitfalls, etc. as we go along. The livecode will be in [peterson.frg](./peterson.frg).

## Fixing Deadlock

Our little algorithm is 90% of the way to the the [Peterson lock](https://en.wikipedia.org/wiki/Peterson%27s_algorithm).  The Peterson lock just adds one extra bit of state, and one transition to set that bit. In short, if our current algorithm is analogous to raising hands for access, the other bit added is like a "no, you first" when two people are trying to get through the door at the same time; that's exactly the sort of situation our both-flags-raised deadlock represented.

We'll add a `polite: lone Process` field to each `Process`, to represent which process (if any) has just said "no, you go first". The algorithm now needs a step to set this value. It goes something like this (in pseudocode) after the process becomes interested:

```
// location: uninterested 
this.flag = true
// location: halfway
polite = me
// location: waiting 
while(other.flag == true || polite == me) {} // hold until their flag is lowered _or_ the other is being polite
// location: in CS 
run_critical_section_code(); // don't care details
this.flag = false
```         

Because we're modeling (as best as we can) individual operations executing, we'll need to add a new location to the state, which I'll call `Halfway`. We'll also need a new transition (and to change existing transitions):

```alloy
pred enabledNoYou[p: Process] {
    World.loc[p] = Halfway
}
pred noYou[p: Process] {
    enabledNoYou[p]
    World.loc'[p] = Waiting
    World.flags' = World.flags
    World.polite' = p
    all p2: Process - p | World.loc'[p2] = World.loc[p2]
}
```

one small edit in `raise`, to set 

```
World.loc'[p] = Halfway
```
instead of 
```
World.loc'[p] = Waiting
```

and a modification to the `enter` transition so that it's enabled if _either_ nobody else has their flag raised _or_ the current process isn't the one being polite anymore:

```alloy
pred enabledEnter[p: Process] {
    World.loc[p] = Waiting 
    -- no other processes have their flag raised *OR* this process isn't the polite one
    (World.flags in p or World.polite != p)
}
```

Then we add the new transition to the overall transition predicate, to `doNothing`, to the deadlock check test---anywhere we previously enumerated possible transitions.

We also need to expand the frame conditions of all other transitions to keep `polite` constant.

~~~admonish warning title="Watch out!" 
Beware of forgetting (or accidentally including) primes. This can lead to unsatisfiable results, since the constraints won't do what you expect between states.
~~~

### Let's Check Non-Starvation

```alloy
noStarvation: {
        lasso implies {
        all p: Process | {
            always {
                -- beware saying "p in World.flags"; using loc is safer
                --   (see why after fix disinterest issue)                
                p in World.flags =>
                eventually World.loc[p] = InCS
            }
        }}
    } is theorem
```

This passes. Yay!

~~~admonish tip title="Should we be suspicious?"
That was really easy. Everything seems to be working perfectly. Maybe we can stop early and go get ice cream. 

But we should probably do some validation to make sure we haven't missed something. Here's a question: *is our domain model realistic enough to trust these results?*
~~~

## Abstraction Choices We Made

We made a choice to model processes as always eventually _interested_ in accessing the critical section. There's no option to become uninterested, or to pass on a given cycle. 

Suppose we allowed processes to become uninterested and go to sleep. How could this affect the correctness of our algorithm, or of the non-starvation property? 

<details>
<summary>Think, then click!</summary>
    
The property might break because a process's flag is still raised as it is _leaving_ the critical section, so the implication is too strong. It might be safer to say `World.loc[p] = Waiting => ...`. 
    
But even the correct property will fail in this case: there's nothing that says one process can't completely dominate the overall system, locking its counterpart out. Suppose that `ProcessA` is `Waiting` and then `ProcessB` stops being interested. _If we modeled disinterest as a while loop_, perhaps using `doNothing` or a custom `stillDisinterested` transition, then `ProcessA` could follow that loop forever, leaving `ProcessB` enabled, but frozen.
</details>

#### Aside

In your next homework, you'll be _critiquing_ a set of properties and algorithms for managing an elevator. Channel your annoyance at the CIT elevators, here! Of course, none of our models encompass the complexity of the CIT elevators...

## Fairness

In a real system, it's not really up to the process itself whether it gets to run forever; it's also up to the operating system's scheduler or the system's hardware. Thus, "fairness" in this context isn't so much a property to guarantee as a **precondition to require**. Without the scheduler being at least _somewhat_ fair, the algorithm can guarantee very little.

Think of a precondition as an environmental assumption that we rely on when checking the algorithm. This is a common sort of thing in verification and, for that matter, in computer science. (If you take a cryptography course, you might encounter the phrase "...is correct, subject to standard cryptographic assumptions".) 

Let's add the precondition, which we'll call "fairness". There are many ways to phrasing fairness, and since we're making it an assumption about the world outside our algorithm, we'd really like to pick something that suffices for our needs, but _isn't any stronger than that._ 

```alloy
pred weakFairness {
    all p: Process | {
        (eventually always 
                (enabledRaise[p] or
                enabledEnter[p] or
                enabledLeave[p] or
                enabledNoYou[p])) 
        => 
        (always eventually (enter[p] or raise[p] or leave[p] or noYou[p]))        
    }
}
```

This may initially look a little strange. There are a few ways to express fairness (weak, strong, ...) but weak fairness is sufficient for our needs! It says that if a process is ready to go with some transition forever (possibly a different transition per state), it must be allowed to proceed (with some transition, possibly different each time) infinitely often.

Hillel Wayne has a [great blog post](https://www.hillelwayne.com/post/fairness/) on the differences between these. Unfortunately it's in a different modeling language, but the ideas come across well. 

Once we add `weakFairness` as an assumption, the properties pass. 
