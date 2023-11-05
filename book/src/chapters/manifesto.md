# Manifesto: Logic for Systems

## Setting the Stage

If you're taking this course or reading this book, you've probably had to complete a class with programming assignments -- or at least written some small program. Take a moment to list a handful of such assignments: what did you have to build? 

Now ask yourself:
* How did you know what was the "right" behavior to implement?
* How did you know what data structures or algorithms were the "right" ones to use?
* How did you know your program "worked", in the end?

Some of these questions have "expected" answers. For instance, you might say you know your code worked because you tested it. But is that really the truth? In terms of consequences, the true bar for "correctness" in your programming classes is the grade you got. That is, you "know" your programs worked because _someone else said they did_. And you knew what to do because you were told what to do. And you knew which algorithms to use, probably, because they'd just been taught to you.

Some time from now, you might be a professional software engineer. You might be working on a program that controls the fate of billions of dollars, tempers geopolitical strife, or controls a patient's insulin pump. Would you trust a TA to tell you those programs worked "good enough"? Would you trust your boss to understand _exactly_ what needed to happen, and tell you _exactly_ how to do it? Probably not!

<!-- So we need to critically think about the question of what we want from a system, from both directions: 
* are you trying to do the correct thing?
* is what you're doing correct?  -->

Instead, we need to think about what "correctness" means in our setting, and what level of confidence we need. Maybe we can't get to 100% confidence in correctness, but the perfect should never be the enemy of the good.

Let's start with unit-testing (as practiced in intro, 0320, and many other courses) and deconstruct it. What does it do well? What does it do poorly?

**Exercise:** Make two lists to answer the above question. Why do we test? What could go wrong, and how can the sort of testing you've done in other classes let us down? 

Hopefully we all agree that concrete input-output testing has its virtues and that we should keep doing it. But let's focus on the things that testing _doesn't_ do well. You might have observed that (for most interesting programs, anyway) tests cannot be exhaustive because there are infinitely many possible inputs. And since we're forced to test non-exhaustively, we have to hope we pick good tests---tests that not only focus on our own implementation, but on others (like the implementation that replaces yours eventually) too.

Worse, we can't test the things we don't think of, or don't know about; we're vulnerable to our limited knowledge, the availability heuristic, confirmation bias, and so on. In fact, we humans are generally ill equipped for logical reasoning, even if trained. Let's see if I can convince you of that.

## Classic (and not-so-classic) Puzzles

### Supervision

Suppose we're thinking about the workings of a small company. We're given some facts about the company, and have to answer a question based on those facts. Here's an example. We know that:

* Alice supervises Bob.
* Bob supervises Charlie.
* Alice graduated Brown.
* Charlie graduated Harvale.

**Question:** Does someone who graduated from Brown directly supervise someone who graduated from another University?

<details>
    <summary>Think, then click.</summary>
Yes! Regardless of whether Bob graduated from Brown, _some_ Brown graduate supervises _some_ non-Brown graduate. Reasoning by hypotheticals, there is one fact we don't know: where Bob graduated. In case he graduated Brown, he supervises Charlie, a non-Brown graduate. In case he graduated from another school, he's supervised by Alice, a Brown graduate.
    
Humans tend to be very bad at reasoning by hypotheticals. There's a temptation to think that this puzzle isn't solvable because we don't know where Bob graduated from. Even Tim thought this at first after seeing the puzzle---in grad school! For logic!    
</details>

Now imagine a puzzle with a thousand of these unknowns. A thousand boolean variables means $2^{1000}$ cases to reason through. Want to use a computer yet?

### Reasoning about knowledge

There is a prison in a magical world where an evil wizard holds a family of four gnomes. Every day, the wizard forces the gnomes to play a game for their freedom: he lines them up, single-file, in one or more rooms, facing the wall. The gnomes cannot move or communicate with each other; they can only look straight ahead. The wizard then pulls out four hats: two orange and two blue, and magics one onto each gnome's head.

The wizard then walks the line, asking each gnome: "What is your hat color?" They may try to answer, or remain silent for 10 seconds (and then the wizard moves on). If a gnome guesses correctly, they all immediately go free. But if one guesses incorrectly, they become the wizard's magical servants forever. So it's in their best interest to not answer unless they are absolutely convinced that they have guessed correctly.

Neither the wizard nor the gnomes can cheat. It's against magical law. The gnomes are, however, very intelligent. Smarter than the wizard for sure: they're perfect logical reasoners.

Here's an example configuration of the puzzle room:

| ![Picture of gnomes-puzzle setup](https://i.imgur.com/SFAoYZy.jpg) |
|:--:| 
|  *(Why are they smiling?)* |

In this configuration, can the gnomes escape? If so, why?

<details>
    <summary>Think, then click.</summary>
    Yes! The gnomes can escape, because they're able to use the knowledge of other gnomes _without explicit communication. When the wizard asks Gnome #2 what color their hat is, Gnome #2 can conclude nothing, and is silent. Gnome #3 can then reason that his hat, and the hat of Gnome #4, must be different colors. Only two colors are possible. And so the wizard is thwarted.
</details>

To solve this puzzle, you need to reason about what the other agents know, and what we expect them to do with that knowledge. These sorts of epistemic statements can be useful in practice.

### A Real Scenario

There's a real cryptographic protocol called the Needham-Schroeder public-key protocol. You can read about it [here](https://en.wikipedia.org/wiki/Needham–Schroeder_protocol#The_public-key_protocol). Unfortunately the protocol has a bug: it's vulnerable to attack if one of the principles can be fooled into starting an exchange with a badly-behaved or compromised agent. We won't go into specifics. Instead, let's focus on the fact that it's quite easy to get things like protocols wrong, and sometimes challenging for us humans to completely explore all possible behaviors -- especially since there might be behaviors we'd never even considered! It sure would be nice if we could get a computer to help out with that.

A pair of former 1710 students did an [ISP on modeling crypto protocols](http://cs.brown.edu/~tbn/publications/ssdnk-fest21-forge.pdf), using the tools you'll learn in class. Here's an example picture, generated by their model, of the flaw in the Needham-Schroeder protocol:

![](https://i.imgur.com/60jnj0s.png)

You don't need to understand the specifics of the visualization; the point is that someone who has studied crypto protocols **would**. And this really does show the classic attack on Needham-Schroeder. You may not be a crypto-protocol person, but you probably are an expert in something you'd like to model, and you might very well get the chance to do so this semester.

## Logic for Systems: Automated Reasoning as an Assistive Device

The human species has been so successful, in part, because of our ability to use assistive devices -- tools! Eyeglasses, bicycles, hammers, bridges: all devices that assist us in navigating the world in our fragile meat-bodies. One of our oldest inventions, writing, is an assistive device that increases our long-term memory space and makes that memory _persistent_. Computers are only one in a long line of such inventions.

So why not (try to):
* use computers to help us test our ideas?
* use computers to exhaustively check program correctness?
* use computers to help us find gaps in our intuition about a program?
* use computers to help us explore the design space of a data structure, or algorithm, card game, or chemical reaction?
* anything else you can think of...

There's a large body of work in Computer Science that tries to do all those things and more.
It covers topics like system modeling, formal methods, and constraint solving. That's what Logic for Systems is about. This course will give you the foundational knowledge to engage with many different applications of these ideas, even if you don't end up working with them directly every day. 

## Computer Science in 2024

The shape of engineering is changing, for better or worse. Lots of people are excited, scared, or both about language models like ChatGPT. This course won't teach you how to use generative AI (in spite of the fact that we now have multiple assignments that use it). So, especially now, it's reasonable to wonder: _what will you get from this course?_

There are two questions that will never go out of style, and won't be answered by AI (at least, I think, not in my lifetime):
* **What do you want to build?** That is, what does your customer really need? Answering this requires talking to them and other stakeholders, watching their processes, seeking their feedback, and adjusting your design based on it. And no matter who -- or what -- is writing the actual code, you need to be able to express all this precisely enough that they can succeed at the implementation.  
* **How will you evaluate what you get?** No matter who -- or what -- is building the system, validation and verification will remain important. 

In short: software engineering is more than just code. Even setting aside the customer-facing aspects, we'll still need to think critically about what it is we want and how to evaluate whether we're getting it. So I'm not just vaguely optimistic about the future; I'm confident that the importance of formal methods, modeling, and other skills that you'll learn here will continue to be useful -- or even become more so -- as engineering evolves.

## Overview of the Semester

See the syllabus for a timeline. In short, you'll have weekly homeworks, with occasional interruption for a project. Project topics are proposed by _you_; our definition of "system" is pretty broad: in the past, groups have modeled and reasoned about puzzles, games, laws, chemical reactions, etc. in addition to obviously "computer-science" systems. We have one case study, and labs most weeks. Some class meetings will have exercises, which are graded for participation. 

~~~admonish note "Brown CS: LfS as Capstone"~~~
If you're using the old Sc.B. requirements: using this course as your capstone involves doing a bit more work for your final project; I like to make sure the topic you propose lets you integrate some other ideas from other courses.
~~~

### Textbook

This free, online textbook grew out of Tim's lecture notes for 1710 and is our primary resource for readings. From time to time, we may provide supplementary reading. This isn't a course you'll want to passively consume; we expect that you'll do the readings, engage with exercises, and ask questions as appropriate. 

Often, the book will contain more than can be covered in class. It will still be useful to read.

### How can you use generative AI in this course?

You are allowed to "collaborate" with generative AI **using the specific method(s) we provide and within the limits we set**. You may not otherwise employ such tools in 1710; doing so would be a violation of the academic code. 

Note that *you shouldn't use the 2023 syllabus to gauge how we'll use AI in 2024*. AI has a much larger role in some of our assignments this year. (E.g., you'll now be using techniques from this course to work with LLM-generated code.)

### Tools we'll use 

The main tool we'll use in this course in [Forge](forge-fm.org). Forge is a tool for _relational modeling_; we'll talk about what that means later on. For now, be aware that we'll be progressing through three _language levels_ in Forge:
* Froglet, which restricts the set of operations available so that we can jump right in more easily. If you have intuitions about object-oriented programming, those intuitions will be useful in Froglet, although there are a few important differences that we'll talk about. (See also our [error gallery](./appendix/errors.md).)
* Relational Forge, which expands the set of operations available to include sets, relations, and relational operators. Again, we'll cover these in detail later. They are useful for reasoning about complex relationships between objects and for representing certain domains, like databases or graphs.
* Temporal Forge, which lets us easily model how a system's state evolves over time. 

We'll also use:
* [Hypothesis](https://hypothesis.readthedocs.io/en/latest/), a testing library for Python; and
* [Z3](https://github.com/Z3Prover/z3), an SMT solver library. 

