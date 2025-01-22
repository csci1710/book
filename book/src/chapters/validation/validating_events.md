# Validating Models

* Now that we have the full discrete-event story, we can talk more carefully about model validation.
* Adapt from work with Pamela and credit her. 





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

~~~admonish note title="Have we been disciplined about this so far?"
No we have not! And we may be about to encounter some problems because of that.
~~~

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

