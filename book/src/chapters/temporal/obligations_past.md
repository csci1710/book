# Obligations and The Past

~~~admonish hint title="Temporal Forge Reminders"
* Remember the definition of "configuration": the value of all relations that aren't marked `var`. Thus, if you click the Sterling button that asks for a _new configuration_, the solver will always find a new trace that varies on one or more of those relations. This is useful when you want to see different temporal behavior, but not vary the constants.
* _Do not_ try to use `example` in temporal mode. For reasons we'll get to soon (when we talk about how Forge works) `example` and `inst` constrain _all states_ in temporal mode, and so an example will prevent anything it binds from ever changing in the trace.
~~~

The in-class exercise is [here](https://docs.google.com/forms/d/e/1FAIpQLSemtfAG44sxqkRSS4imTcGC1LVwcHgJWOrgrHp3wXyLbuMAZw/viewform?usp=sf_link). The livecode is the same model we've been working on: the [locking algorithm](./mutex_temporal.frg).

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

## Interlude on Testing and Properties 

As we start modeling more complex systems, models become more complex. The more complex the model is, the more important it is to test the model carefully. Just like in software testing, however, you can never be 100% sure that you have tested everything. Instead, you proceed using your experience and following some methodology. 

Let's get some practice with this. Before we start modifying our locking algorithm model, we should think carefully---both about testing, but also about how the model reflects the real world. 

### Principle 1: What's the Domain? What's the System? 

When we're writing a model, it's useful to know when we're talking about the _system_, and when we're talking about the _domain_ that the system is operating on. 
* The domain has a set of behaviors it can perform on its own. In this example, the threads represent the domain: programs running concurrently. 
* The system affects that set of behaviors in a specific way. In this example, the locking algorithm is the system. Usually the system functions by putting limits and structure on otherwise unfettered behavior. (E.g., without a locking algorithm in place, in reality threads would still run and violate mutual exclusion.)
* Because we usually have goals about how, exactly, the system constrains the domain, we state _requirements_ about how the domain behaves in the system's presence. Think of these as the top-level goals that we might be modeling in order to prove (or disprove) about the system or otherwise explore.  
* Because the domain cannot "see" inside the system, we'll try to avoid stating requirements in terms of internal system variables. However, models are imperfect! We will also have some _validation tests_ that are separate from the requirements. These may or may not involve internal system state.

We'll develop these ideas more over the next few weeks. For now, keep in mind that when you add something to a model, it's good to have a sense of where it comes from. Does it represent an internal system state, which should probably not be involved in a requirement, but perhaps should be checked in model validation?

### Principle 2: What Can Be Observed?

Ask what behaviors might be important in the domain, but not necessarily always observed. These are sometimes referred to as _optional predicates_, because they may or may not hold. In real life, here are some optional predicates:
* we have class today;
* it's raining today; 
* homework is due today; etc. 

**Exercise:** What are some optional predicates about the domain in our locking algorithm model? 

<details>
<summary>Think, then click!</summary>

We might see, but won't necessarily always see:
* combinations of different transitions; 
* threads that are both simultaneously interested;
* threads that are uninterested; 
* etc.

As the model includes more domain complexity, the set of optional predicates grows. 

</details>

Let's write some actual tests to confirm that these behaviors can happen (or not), and check whether that matches our modeling intuition. 

~~~admonish note title="For Next Time"
We'll consider questions of atomicity (how granular should transitions be?), and model a different variation of this lock.
~~~

