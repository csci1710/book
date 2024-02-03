# 2023.7: Finite Traces: Doing Nothing (Productively)

**These notes are under construction. Expect edits up until after class.**

~~~admonish note title="How to contextualize homeworks"
The Forge homeworks have at least three learning goals, each of which represents a different _layer_ of the course content:
* getting you practice with the low-level details of using Forge (e.g., predicates, sigs, etc.); 
* familiarizing you with a number of modeling techniques (e.g., transition predicates, traces, assertions and examples, etc.); and
* giving you an opportunity to experiment with and critique different modeling choices (e.g., should this constraint be included in that predicate? What should we decide a well-formed state looks like? Is this set of sigs and fields right for our modeling goals? What should we interpret this English sentence as asking for?)

All of these will be vital when we get to the self-directed projects (and the first is coming fairly soon).
~~~

<!-- ### What is the role of a wheat?

In principle, wheats support all 3 of these learning goals. But if we treat wheats only as "the unique correct solution", they work rather poorly. Modeling choices can be complicated, and there are often multiple reasonable approaches. (As an example, consider how a programmer might choose to represent a graph as either an adjacency list or an adjacency matrix. Both have their own advantages and disadvantages.) 

Ideally, the wheat wouldn't need to be "correct". We could still have discussions and even critique what the wheat does. Some of you have done this on EdStem for Forge 1, which is great to see!

However, we also need a consistent behavioral target for you to aim for when doing assignments. This also helps us grade, both for the autograded and non-autograded parts of our rubrics. So the wheat also can't be "just another solution".

### So what exactly _is_ a wheat, then?

The wheat is the solution we had at the end of TA camp. This means that it is a decent baseline, but it might:
* contain bugs (actual _wrong_ behavior that isn't a matter of taste or debate); or 
* contain debatable modeling choices or interpretations of the English handout (which may not be either right or wrong, and may be more or less suited for specific modeling goals beyond the assignment).

In either of these cases:
* It's disruptive to replace the wheat in the middle of the assignment! (What should those who already finished do? What about those who are in the middle of working with the wheat?)
* It's missing an opportunity to encourage critique as a class, and exercise that third learning goal. (What makes a good model? How should we design one?)

Therefore, for future Forge assignments where we provide a wheat: 
* The wheat won't be changed during the semester, even if it's flawed. You'll still aim to write your predicate to match it, and we'll still be grading with respect to the wheat. Think of the wheat as providing the perspective of a stakeholder---you've got to meet their spec, but at the same time, you might discuss why their spec will not give them what they really want.
* However, you'll have the opportunity to file your concerns about the wheat as you do the assignment. (Is there behavior you disagree with? What do you think the disconnect is between the wheat and what you'd choose to do?)
* We'll also do a review in class for each homework. I'll bring up some critique that you sent in, and we'll discuss the relative pros and cons.  This will be our in-class exercise on those days.
* For those who find actual _bugs_ in the wheat, we'll be giving a small amount of extra credit.

Of course, any issues in _Forge_ are different, and we'll still be updating Forge regularly. And we'll be keeping an eye on this process and making needed changes as the semester continues. 
 -->

## Back To Tic-Tac-Toe: Ending Games

When we stopped last time, we'd written this `run` command:

```alloy
run {
  wellformed
  traces
} for exactly 10 State for {next is linear}
```

**Reminder:** Without a `run`, an `example`, or a similar _command_, running a Forge model will do nothing. 

From this `run` command, Forge will find _traces_ of the system (here, games of Tic-Tac-Toe) represented as a linear sequence of exactly 10 `State` objects.

Do you have any worries about the way this is set up?

<details>
<summary>Think, then click!</summary>
Are all Tic-Tac-Toe games 10 states long? 
    
Well, _maybe_; it depends on how we define a game. If we want a game to stop as soon as nobody can win, our `exactly 10 State` bound is going to prevent us from finding games that are won before the final cell of the board is filled.    
</details>

Let's add the following guard constraint to the `move` transition, which forces games to end as soon as somebody wins.

```alloy
all p: Player | not winner[pre, p]
```

Now we've got problems. Normally we could fix the issue by getting rid of the `exactly`. Unfortunately, there's a hidden snag: when we tell Forge in this way that that `next` is linear, it automatically makes the bound exact. 

This behavior, which I admit is bizarre at first, exists for two reasons:
* historical reasons: we inherit `is linear` from Alloy, which uses somewhat different syntax to mean the same thing; and
* performance reasons: since the `is linear` annotation is almost always used for trace-generation, and trace-generation solving time grows (in the worst case) exponentially in the length of the trace, we will almost always want to reduce unnecessary uncertainty. Forcing the trace length to always be the same reduces the load on the solver, and makes trace-generation somewhat more efficient.

But now we need to work around that constraint. Any ideas? Hint: do we need to have _only one_ kind of transition in our system?
 
<details>
<summary>Think, then click!</summary>

No. A common way to allow trace length to vary is by adding a "do nothing" transition. (In the literature, this is called a _stutter transition_.) 
    
The trick is in how to add it without also allowing a "game" to consist of nobody doing anything. To do that requires some more careful modeling.

</details>
</br>

Let's add an additional transition that does nothing. We can't "do nothing" in the predicate body, though -- an empty predicate body would just mean _anything_ could happen. What we mean to say is that the state of the board remains the same, even if the before and after `State` objects differ.

```alloy
pred doNothing[pre: State, post: State] {
    all row2: Int, col2: Int | 
        post.board[row2][col2] = pre.board[row2][col2]
}
```

We also need to edit the `traces` predicate to allow `doNothing` to take place:

```alloy
pred traces {
    -- The trace starts with an initial state
    starting[Game.initialState]
    no sprev: State | sprev.next = Game.initialState
    -- Every transition is a valid move
    all s: State | some Game.next[s] implies {
      some row, col: Int, p: Player | {
        move[s, row, col, p, Game.next[s]] 
      }
      or
      doNothing[s, Game.next[s]]      
    } 
}
```

As it stands, this fix solves the _overconstraint_ problem of never seeing an early win, but introduces a new _underconstraint_ problem: we don't want `doNothing` transitions to happen just anywhere!

Here's how I like to fix it:

```alloy
gameOver[s: State] {
  some p: Player | winner[s, p]
}
```

Why a new predicate? Because I want to use different predicates to represent different concepts. 

When should a `doNothing` transition be possible? _When the game is over!_

```alloy
pred doNothing[pre: State, post: State] {
    gameOver[pre] -- guard of the transition
    pre.board = post.board -- effect of the transition
}
```

If we wanted to, we could add a `not gameOver[pre]` to the `move` predicate, enforcing that nobody can move at all after someone has won.

## Do The Rules Allow Cheating?

Let's ask Forge whether a `cheating` state is possible under the rules. 

```alloy
run {
  wellformed
  traces
  some bad: State | cheating[bad]
} for exactly 10 State for {next is linear}
```

This should work---assuming we don't drop the `is linear` annotation. Without it, nothing says that every state must be in the trace, and so Forge could produce an instance with an "unused" cheating state.

## Checking Conjectures

When I was very small, I thought that moving in the middle of the board would guarantee a win at Tic-Tac-Toe. Now I know that isn't true. But could I have used Forge to check my conjecture (if I'd taken 1710 at that point in life)?

<details>
<summary>Think, then Click!</summary>
Here's how I did it:    
    
```alloy
run {
  wellformed
  traces
  -- "let" just lets us locally define an expression
  --  good for clarity in the model!
  -- here we say that X first moved in the middle
  let second = Trace.next[Trace.initialState] |
    second.board[1][1] = X
  -- ...but X didn't win
  all s: State | not winner[s, X]
} for exactly 10 State for {next is linear}
```    
    
</details>

We could also write this using an assertion, but since we knew in advance it was probably an incorrect belief, I chose to write it directly as a counter-example search.

### Reminder: The Evaluator

If you're viewing an instance, you can always select the evaluator tray and enter Forge syntax to see what it evaluates to in the instance shown. You can enter both formulas and expressions. We also have the ability to refer to objects in the world directly. E.g., we could try:

```alloy
all s: State | not winner[s, X]
```

but also (assuming `Board0` is an object):

```alloy
winner[Board0, X]
```

### Going Further

This illustrates a new class of queries we can ask Forge. Given parties following certain _strategies_, is it possible to find a trace where one strategy fails to succeed vs. another? 

**Challenge exercise:** Write a `run` that searches for a game where both parties always _block_ immediate wins by their opponent. Is it ever possible for one party to win, if both will act to prevent a 3-in-a-row on the next turn?

## Will This Always Work?

Let's say you're checking properties for a real system. A distributed-systems algorithm, maybe, or a new processor. Even a more complex version of Tic-Tac-Toe! 

Next time, we'll talk about the problems with traces, which turn out to be  **central challenges in software and hardware verification**. 


## (Optional) Modeling Tip: Dealing with Unsatisfiability

Many of you have had your first encounter with an over-constraint bug this week. Maybe you wrote an `assert` and it seemed to never stop. Maybe you wrote a `run` command and Sterling just produced an `UNSAT0` result. 

Getting back an unsat result can take a long time. Why? Think of the search process. If there is a satisfying instance, the solver can find it early. If there isn't, the solver needs to explore the entire space of possibilities. Yeah, there are smart algorithms for this, and it's not *really* enumerating the entire space of instances, but the general idea holds. 

So if you run Forge and it doesn't seem to ever terminate, it's not necessary a Forge problem---surprising over-constraint bugs can produce this behavior.

So, how do you debug a problem like this? The first thing I like to do is reduce the bounds (if possible) and, if I still get unsat, I'll use that smaller, faster run to debug. But at that point, we're kind of stuck. `UNSAT0` isn't very helpful. 

Today I want to show you a very useful technique for discovering the problem. There are more advanced approaches we'll get to later in the course, but for now this one should serve you well. 

The core idea is: encode an instance you'd expect to see as a set of constraints, run _those_ constraints only, and then use the evaluator to explore why it fails your other constraints. Let's do an example!

```alloy
#lang forge/bsl
-- NOT THE EXACT STENCIL!
sig State {
  top: lone Element
}
sig Element {
  next: lone Element             
}

pred buggy {
  all s: State | all e: Element {
    s.top = e or reachable[e, s.top, next]
  }
  some st1, st2: State | st1.top != st2.top     
  all e: Element | not reachable[e, e, next]
}
test expect {
  exampleDebug: {buggy} is sat
}
```

This test fails. But why?

```alloy
run {
  some st1, st2: State |
  some ele1, ele2: Element | {
    st1.top = ele1
    st2.top = ele2
    ele1.next = ele2   
    no ele2.next    
  }
} for exactly 2 State, exactly 2 Element
```

Given this instance, the question is: **why didn't Forge accept it?** There must be some constraint, or constraints, that it violates. Let's find out which one. We'll paste them into the evaluator...
* `some st1, st2: State | st1.top != st2.top`? This evaluates to `#t` (true). No problem there.
* `  all s: State | all e: Element {
    s.top = e or reachable[e, s.top, next]
  }`? This evaluates to `#f` (false). So this is a problem.
  
Now we proceed by breaking down the constraint. The outer shell is an `all`, so let's plug in a concrete value:
*  `all e: Element {
    State0.top = e or reachable[e, State0.top, next]
  }`? This evaluates to `#f`. So the constraint fails for `State0`. 
  
**Important**: Don't try to name specific states in your model. They _don't exist_ at that point. 

Which element does the constraint fail on? Again, we'll substitute concrete values and experiment:
*  `State0.top = Element0 or reachable[Element0, State0.top, next]`? This evaluates to `#t`. What about `State0.top = Element1 or reachable[Element1, State0.top, next]`?

Following this process very often leads to discovering an over-constraint bug, or a misconception the author had about the goals of the model or the meaning of the constraints. 

**Question: What's the problem here?**

<details>
<summary>Think, then click!</summary>

Since the `next` field never changes with time, the `all` constraint doesn't allow states to vary the `top` of the stack. Instead, we need a weaker constraint to enforce that the stack is shaped like a state.

</details>

