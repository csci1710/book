# Obligations and The Past

~~~admonish hint title="Temporal Forge Reminders"
* Remember the definition of "configuration": the value of all relations that aren't marked `var`. Thus, if you click the Sterling button that asks for a _new configuration_, the solver will always find a new trace that varies on one or more of those relations. This is useful when you want to see different temporal behavior, but not vary the constants.
* _Do not_ try to use `example` in temporal mode. For reasons we'll get to soon (when we talk about how Forge works) `example` and `inst` constrain _all states_ in temporal mode, and so an example will prevent anything it binds from ever changing in the trace.
~~~

## Reminder: Priming for "next state" expressions

You can talk about the value of an expression _in the next state_ by appending `'` to the expression. So writing `flags'` means the value of the flags relation in the state after the current one.

## Back to LTL: Obligation

Suppose we've written a model where `stopped` and `green_light` are predicates that express our car is stopped, and the light is green. Now, maybe we want to write a constraint like, at the current moment in time, it's true that:
* the light must eventually turn green; and 
* the `stopped` predicate must hold true until the light turns green. 

We can write the first easily enough: `eventually green`. But what about the second? We might initially think about writing something like: `always {not green implies stopped}`. But this doesn't quite express what we want. (Why?) 

<details>
<summary>Think, then click!</summary>

The formula `always {not green implies stopped}` says that at any single moment in time, if the light isn't green, our car is stopped. This isn't the same as "the `stopped` predicate holds until the light turns green", though; for one thing, the latter applies _until_ `green` happens, and after that there is no obligation remaining on `stopped`. 

</details>

In LTL, the `until` operator can be used to express a stronger sort of `eventually`. If I write `stopped until green_light`, it encodes the meaning above. This operator is a great way to phrase obligations that might hold only until some releasing condition occurs.

~~~admonish tip title="Strong vs. Weak Until"
Some logics include a "weak" `until` operator that doesn't actually enforce that the right-hand side ever holds, and so the left-hand side can just be true forever. But, for consistency with industrial languages, Forge's `until` is "strong", so it requires the right-hand side hold eventually.
~~~

~~~admonish warning title="The car doesn't have to move!"
The `until` operator doesn't prevent its _left_ side from being true after its right side is. E.g., `stopped until green_light` doesn't mean that the car has to move immediately (or indeed, ever) once the light is green. It just means that the light eventually turns green, and the car can't move until then.
~~~

## The Past (Rarely Used, but Sometimes Useful)

Forge also includes [temporal operators corresponding to the _past_](https://csci1710.github.io/forge-documentation/electrum/electrum-overview.html). This isn't standard in some LTL tools, but we include it for convenience. It turns out that past-time operators don't increase the expressive power of the language, but they do make it much easier and consise to write some constraints. 

~~~admonish note title="Elevator Critique"
These operators may be useful to you on the second Temporal Forge homework. You may also see them in lab.
~~~

Here are some examples:

### `prev_state init` 

This means that the _previous_ state satisfied the initial-state predicate. **But beware**: traces are infinite in the forward direction, but _not_ infinite in the backward direction. For any subformula `myPredicate`, `prev_state myPredicate` is _false_ if the current state is the first state of the trace.

There are also analogues to `always` and `eventually` in the past: `historically` and `once`. For more information, see the [documentation](https://csci1710.github.io/forge-documentation/electrum/electrum-overview.html).

## Modeling Deadlock

A deadlock state is one where _no_ outgoing transitions are possible. How can we write a test in temporal mode that tries to find a reachable deadlock state? There are two challenges:

* How do we phrase the constraint, in terms of the transition predicates we have to work with? 
* How do we even allow Forge to find a deadlock, given that temporal mode *only* ever finds lasso traces? (A deadlock in a lasso trace is impossible, since a deadlock prevents progress!)

Let's solve the second challenge first, since it's more foundational.

### Finding Deadlocks Via Lassos

We could prevent this issue by allowing a `doNothing` transition from every state. Then from Forge's perspective there's no "deadlock", and a lasso trace can be found. 

But this fix causes new problems. If we allow a `doNothing` transition to happen _anywhere_, our liveness property is definitely destroyed, even if we were modeling a smarter algorithm. So we need to reduce the power of `doNothing` somehow.

Put another way: we started with an _overconstraint_ bug: if only lassos can be found, then we can't find a trace exhibiting deadlock. Adding `doNothing` fixes the overconstraint but adds a new _underconstraint_, because we'll get a lot of garbage traces where the system can just pause arbitrarily (while the trace continues).

We saw this phenomenon earlier when we were modeling tic-tac-toe, and wanted to work around the fact that the `is linear` annotation forces exact bounds. We can use the same ideas in the fix here.

## Finding Deadlock

Let's look at one of our transitions:

```alloy
pred raise[p: Process] {
    World.loc[p] = Disinterested
    World.loc'[p] = Waiting
    World.flags' = World.flags + p
    all p2: Process - p | World.loc'[p2] = World.loc[p2]
}
```

Notice it's split (implictly) into a "guard" and an "action". If all the constraints in the guard are true, the transition _can_ occur. Formally, we say that if all the guard constraints hold, then the transition is _enabled_. When should `doNothing` be enabled? When no other transition is.

```alloy
pred doNothing {
    -- GUARD (nothing else can happen)
    not (some p: Process | enabledRaise[p]) 
    not (some p: Process | enabledEnter[p]) 
    not (some p: Process | enabledLeave[p]) 
    -- ACTION
    flags' = flags
    loc' = loc
}
```

We won't create a separate `enabledDoNothing` predicate. But we will add `doNothing` to the set of possible moves:

```alloy
pred trans {
    some p: Process | 
        raise[p] or
        enter[p] or 
        leave[p] or 
        doNothing 
}
```

And we'd also better create those 3 `enabled` predicates, too.

Finally, we can write a check looking for deadlocks:

```alloy
test expect {
    noDeadlocks_counterexample: {
        init
        always delta
        not always {
            some p: Process |
                enabledRaise[p] or
                enabledEnter[p] or
                enabledLeave[p] 
        }
    } is sat
}
```

which fails. But why?

The counterexample (at least, the one I got) is 3 states long. And in the final state, both processes are `Waiting`. Success! Or, at least, success in **finding the deadlock**.

But how should we fix the algorithm? And how can we avoid confusion like this in the future?



