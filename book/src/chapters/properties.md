# From Tests to Properties 

<!-- (Working in code, not modeling yet)

Implementation of a linked list. 
* What should `add` guarantee?
* 


tests as specification: a partial, point-wise one, not great for fully describing what you want. But cheap, non-trivially useful, and better than nothing.

relational problems: how do you test them?

* change-making 
  * simple greedy algorithm (largest coins first)
  * apply PBT (correct total, in drawer)
  * let's try this on LLM-generated code

* cheapest path in a graph 
  * dijkstra
  * apply PBT... can get most, but "is shortest" seems...expensive.
  * apply MBT (alone): different algos different results, potentially
  * combine PBT + MBT (MBT for only the _length_)


 -->

## (Brown CSCI 1710) Logistics

The first assignment goes out today: it's a homework, in Python. If you're not familiar with Python, you should check out our optional Python lab. The homework uses a library called Hypothesis, which we'll see some of in lecture today. You'll also be asked to use ChatGPT to generate code. Next Wednesday's lab will also use ChatGPT. 

## Where are we going?

We'll talk about more than just software soon. For now, let's go back to testing.

Most of us have learned how to write test cases. Given an input, here's the output to expect. We talked a bit [last time](./manifesto.md) about how tests aren't always good enough: they carry our biases, they can't cover an infinite input space, etc. But even more, they're not always adequate carriers of intent: if I write `assert median([1,2,3]) == 2`, what exactly is the behavior of the system I'm trying to confirm? Surely I'm not writing the test because I care specifically about `[1,2,3]` only, and not about `[3,4,5]` in the same way? Maybe there was some broader aspect, some _property_ of median I cared about when I wrote that test. What do you think it was? What makes an implementation of `median` correct?

<details>
<summary>Think, then click!</summary>
There might be many things! One particular idea is that, if the input list has odd length, the median needs to be an element of the list. 
</details>
</br>

There isn't always an easy-to-extract property for every unit test. But this idea---of encoding _goals_ instead of specific behaviors---forces us to start thinking critically about _what we want_ from a system and helps us to express it in a way that others (including, perhaps, LLMs) can use. It's only a short hop from there to some of the real applications we talked about last time, like verifying firewalls or modeling the Java type system.

## A New Kind of Testing

### Cheapest Paths

Consider the problem of finding cheapest paths in a weighted graph. There are quite a few algorithms you might use: Dijkstra, Bellman-Ford, even a plain breadth-first search for an unweighted graph. You might have implemented one of these for another class! 

The problem statement seems simple: take a graph $GRAPH$ and two vertex names $V1$ and $V2$ as input. Produce the cheapest path from $V1$ to $V2$ in $GRAPH$. But it turns out that this problem hides a lurking issue.

Find the cheapest path from vertex $G$ to vertex $E$ on the graph below.

![](https://i.imgur.com/CT7MSgl.jpg)

<details>
<summary>Think, then click!</summary>
The path is G to A to B to E.    
    
Great! We have the answer. Now we can go and add a test case for with that graph as input and (G, A, B, E) as the output. 
    
Wait -- you found a different path? G to D to B to E?
    
And another path? G to H to F to E?
</details>

If we add a traditional test case corresponding to _one_ of the correct answers, our test suite will falsely raise alarms for correct implementations that happen to find different answers. In short, we'll be over-fitting our tests to @italic{one specific implementation}: ours. But there's a fix. Maybe instead of writing:

`shortest(GRAPH, G, E) == [(G, A), (A, B), (B, E)]`

we write:

```
shortest(GRAPH, G, E) == [(G, A), (A, B), (B, E)] or
shortest(GRAPH, G, E) == [(G, D), (D, B), (B, E)] or
shortest(GRAPH, G, E) == [(G, H), (H, F), (F, E)]
```

What's wrong with the "big or" strategy? Can you think of a graph where it'd be unwise to try to do this?

<details>
    <summary>Think, then click!</summary>

There are at least two problems. First, we might have missed some possible solutions, which is quite easy to do; the first time Tim was preparing these notes, he missed the third path above! Second, there might be an unmanageable number of equally correct solutions. The most pathological case might be something like a graph with all possible edges present, all of which have weight zero. Then, every path is cheapest.
    
</details>

This problem -- multiple correct answers -- occurs in every part of Computer Science. Once you're looking for it, you can't stop seeing it. Most graph problems exhibit it. Worse, so do most optimization problems. Unique solutions are convenient, but the universe isn't built for our convenience. 

What's the solution? If _test cases_ won't work, is there an alternative? (Hint: instead of defining correctness bottom-up, by small test cases, think top-down: can we say what it __means__ for an implementation to be correct, at a high level?)

<details>
<summary>Think, then click!</summary>

In the cheapest-path case, we can notice that the costs of all cheapest paths are the same. This enables us to write:

`cost(cheapest(GRAPH, G, E)) = 11`

which is now robust against multiple implementations of `cheapest`.
    
</details>


This might be something you were taught to do when implementing cheapest-path algorithms, or it might be something you did on your own, unconsciously. (You might also have been told to ignore this problem, or not told about it at all...) We're not going to stop there, however.

Notice that we just did something subtle and interesting. Even if there are a billion cheapest paths between two vertices in the input graph, they all have that same, minimal length. Our testing strategy has just evolved past naming _specific_ values of output to checking broader _properties_ of output.

Similarly, we can move past specific inputs: randomly generate them. Then, write a function `is_valid` that takes an arbitrary `input, output` pair and returns true if and only if the output is a valid solution for the input. Just pipe in a bunch of inputs, and the function will try them all. You can apply this strategy to most any problem, in any programming language. (For your homework this week, you'll be using Python.)

Let's be more careful, though. Is there something _else_ that `cheapest` needs to guarantee for that input, beyond finding a path with the same cost as our solution?

<details>
<summary>Think, then click!</summary>

We also need to confirm that the path returned by `cheapest` is indeed a path in the graph! 

</details>

Here's a sketch of an `is_valid` function for cheapest path:

<details>
<summary>Think, then click!</summary>

```
isValid : input: (graph, vertex, vertex), output: list(vertex) -> bool
  returns true IFF:
    (1) cost(output) is cost(trustedImplementation(output))
    (2) every vertex in output is in input's graph
    (3) every step in output is an edge in input
    ...
```

</details>

This style of testing is called Property-Based Testing (PBT). When we're using a trusted implementation---or some other artifact---to either evaluate the output or to help generate useful inputs, it is also a variety of Model-Based Testing (MBT). 

~~~admonish note title="Model-Based Testing"
There's a lot of techniques under the umbrella of MBT. If time permits, we'll talk 
more about this later in the semester. For now, know that modeling systems, which 
is what we'll be doing 
for much of this class, can be used to help generate good tests. 
~~~

There are a few questions, though...

**Question:** Can we really trust a "trusted" implementation?

No, not completely. It's impossible to reach a hundred percent trust; anybody who tells you otherwise is selling something. Even if you spend years creating a correct-by-construction system, there could be a bug in (say) how it is deployed or connected to other systems. 

But often, questions of correctness are really about the _transfer of confidence_: my old, slow implementation has worked for a couple of years now, and it's probably mostly right. I don't trust my new, optimized implementation at all: maybe it uses an obscure data structure, or a language I'm not familiar with, or maybe I don't even have access to the source code at all. 

And anyway, often we don't need recourse to any trusted model; we can just phrase the properties directly. 

**Exercise:** What if we don't have a trusted implementation?

You can use this approach whenever you can write a function that checks the correctness of a given output. It doesn't need to use an existing implementation (it's just easier to talk about that way). In the next example we won't use a trusted implementation at all!

**Question:** Where do the inputs come from?

Great question! Some we will manually create based on our own cleverness and understanding of the problem. Others, we'll generate randomly.

Random inputs are used for many purposes in software engineering: "fuzz testing", for instance, creates vast quantities of random inputs in an attempt to find crashes and other serious errors. We'll use that same idea here, except that our notion of correctness is usually a bit more nuanced.

Concretely:

![](https://i.imgur.com/gCGDK6m.jpg)

It's important to note that some creativity is still involved here: you need to come up with an `is_valid` function (the "property"), and you'll almost always want to create some hand-crafted inputs (don't trust a random generator to find the subtle corner cases you already know about!) The strength of this approach lies in its resilience against problems with multiple correct answers, and in its ability to _mine for bugs while you sleep_. Did your random testing find a bug? Fix it, and then add that input to your list of regression tests. Rinse, repeat.

If we were still thinking in terms of traditional test cases, this would make no sense: where would the outputs come from? Instead, we've created a testing system where concrete outputs aren't something we need to provide. Instead, we check whether the program under test produces _any valid output_.

## Hypothesis

There are PBT libraries for most every popular language. For your homework, you'll be using a library for Python called Hypothesis. I want to spend the rest of class stepping you through using the library. Let's test a function in Python itself: the `median` function in the `statistics` library, which we began this chapter with. What are some important properties of `median`?

Now let's use Hypothesis to test at least one of those properties. We'll start with this template:

```python
from hypothesis import given, settings
from hypothesis.strategies import integers, lists
from statistics import median

@given(lists(integers()))
@settings(max_examples=500)
def test_python_median(l):    
    pass

if __name__ == "__main__":
    test_python_median()

```

Let's start by filling in the _shape_ of the property-based test case:

```python
def test_python_median(l):    
    output_median = median(input_list) # call the implementation under test
    print(f'{input_list} -> {output_median}') # for debugging our property function
    if len(input_list) % 2 == 1:
        assert output_median in input_list 
    # The above checks a conditional property. But what if the list length isn't even?
    # ...
```

After some back and forth, we might end up somewhere like this:

```python
def test_python_median(input_list):
    output_median = median(input_list)
    print(f'{input_list} -> {output_median}')
    if len(input_list) % 2 == 1:
        assert output_median in input_list
    
    # Question 1: What's going wrong? The _property_ seems reasonable...
    lower_or_eq =  [val for val in input_list if val <= output_median]
    higher_or_eq = [val for val in input_list if val >= output_median]
    assert len(lower_or_eq) >= len(input_list) // 2    # // ~ floor
    assert len(higher_or_eq) >= len(input_list) // 2   # // ~ floor
    # Question 2: Is this enough? :-)
```

As the questions in the code hint, there's still a problem with this. What do you think is missing? 

<!-- <details>
  <summary>Think, then click!</summary>

  What do you think? 

<details> -->


Notice how _being precise_ about what correctness means is very important. With ordinary unit tests, we're able to think about behavior point-wise; here, we need to broadly describe our goals. There's advantages to that work: comprehension, more powerful testing, better coverage, etc. 

There's more to do, but hopefully this gives you a reasonably nice starting point.
