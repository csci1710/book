# CEGIS and Synthesis

<!-- Note for next year: see board layout in lecture capture. This was likely more effective than trying to do this in Forge as the notes suggest.
 -->
 
## CounterExample Guided Inductive Synthesis (CEGIS)

~~~admonish warning title="Pseudocode"
Many of the Forge expressions shown in this section will be demonstrative only, and won't actually run. You'll see why as we progress, but be warned!
~~~

Consider modeling [Kruskal](https://en.wikipedia.org/wiki/Kruskal%27s_algorithm) or [Prim–Jarník's](https://en.wikipedia.org/wiki/Prim%27s_algorithm) approach to finding a minimum spanning tree on a weighted graph. 

I wrote a rough model of Prim's algorithm last year, intending to turn it into a lecture or assignment. It never appeared in that setting, but it will be useful here as a motivational example. We looked at this earlier in the semester; let's return to it. 

The model itself has a number of predicates, such as:
* `wellformedgraph` (a well-formedness predicate to force the graphs to be weighted, directed, etc.); and
* `runPrimComplete` (produce a complete execution of Prim's algorithm on the underlying graph)

There are a few questions we might want to ask about MSTs in general. Not all of them involve the algorithm. 
  * Find a minimal spanning tree for a graph, independent of any algorithm model. 
  * Find a counter-example to correctness for Prim's algorithm (i.e., falsify "Prim's always produces a minimal spanning tree). 
  * Find a valid MST that Prim's algorithm cannot produce. 
All of these questions have a different character, even though they may seem similar. 

### Question 1: Finding a MST

What does it mean to find a _minimum spanning tree_ for an undirected, weighted graph $G = (V,E,w)$? It must be a set of edges $T$, such that:

* $T \subseteq E$;
* $T$ forms a tree;
* $T$ spans $V$ (i.e., $V$ contains at least one edge connected to every vertex in $V$); and
* for all other sets of edges $T_2$, if $T_2$ satisfies the previous 3 criteria, then the total weight of $T_2$ must be no less than the total weight of $T$ (i.e., $T$ is a _minimal_ weight spanning tree).

Checking the final criterion requires higher-order universal quantification. We'd need to write something like this:

```alloy
some t: set Node->Node |
  spanningTree[t]
  all t2: set Node->Node | 
    spanningTree[t2] implies weight[t2] >= weight[t]
```

Forge can eliminate the outer `some` quantifier via Skolemization: turn it into a new relation to solve for. But it can't do that for the inner `all` quantifier. How many possible edge sets are there? If there are 5 possible `Node` objects, then there are 25 possible edges between those objects, and thus $2^{25} = 33554432$ possible edge sets. 

**Aside**: The exponent will vary depending on the modeling idiom. If you can exclude all self-loops, for example, it will be $20$. If you are working in a tool that understands undirected edges in a non-relational way, it will be $10$, etc.

While, technically, Forge probably could produce a big `and` formula with 33 million children, this approach doesn't scale. So the solver engine won't even try---it will stop running if given such a constraint.

We need a different, more structured way of attacking this problem.

### An Alternative Formula

Suppose that, instead of the above shape, we had something like this, with respect to a fixed edge set `t`:

```alloy
  // some edge-set "t" already defined at this point
  some t2: set Node->Node | 
    spanningTree[t2] and weight[t2] < weight[t]
```

That is, suppose we had a prospective candidate solution `t`, and we want to search for _better solution_. This is fine: Forge can handle higher-order `some`. So we can use Forge to check a candidate solution.

### The Idea

This suggests an iterative approach. Find a candidate spanning tree---any spanning tree. Call its weight $k$. Then try to find something better, a spanning tree with length less than $k$. And then try again. And again. Until nothing better can be found. At that point, you've found a minimal spanning tree.

Since Forge is a Racket library, you can use this technique via loop in Racket. It's a bit less straightforward, since you need to break out of the Forge language itself, and because this use of Forge isn't yet documented well, you'd probably need to ask questions if you needed this technique for your project. 

~~~admonish tip title="This works for any solver that lets you make iterated queries."
Note that since Z3py is a Python library, you can use this technique in Z3 as well. If you need to backtrack (usually you don't, with this technique), use the `pop` and `push` functions in Z3py.
~~~

### More Complicated Learning

This technique is pretty specialized, though. It relies on:
* having a metric for _goodness_ (here, total edge weight); and
* a well-defined and easily checkable precondition for candidacy (here, the notion of being a spanning tree). 

Not all higher-order universal constraints exhibit these nice properties, and others which aren't higher-order can still benefit from this idea. 

Here's a classical example from formal methods: program synthesis. Suppose we were trying to [synthesize a program (see this link for the full work)](http://www.csl.sri.com/users/tiwari/papers/pldi2011-bitvector.pdf) that takes a machine integer as input, and outputs the number of `1` bits in that number. We might express the goal roughly as:

```alloy
some p: program |  
  all i: Int | 
    p[i] = countBitsInInteger[i] // assume we have this helper
```

We might proceed as follows:
* Generate a candidate program, any candidate program. 
* Check it by seeing if `some i: Int | p[i] != countBitsInInteger[i]` is satisfiable. 
    * If no, we've found a good program.
    * If yes, there's an integer `i` that the current program doesn't work for. instantiate the formula `p[i] = countBitsInInteger[i]` with the concrete value, add it to our constraints, and repeat. This doesn't rule out a _lot_ of the search space, but it does prevent the exact same problem from arising again in future candidates. 

This broad technique is called CounterExample Guided Inductive Synthesis (or CEGIS). It and related ideas are used heavily in synthesis tools. Similar ideas are also used inside SMT solvers to help eliminate universal quantifiers.

Sophisticated versions of CEGIS will try to infer root causes for failure (rather than just learning, essentially, "...yes, but make it work for `i`, too." This tends to be what makes the technique scale well: the more focused a cause you can learn, the more of the search space you can rule out with each iteration. 

~~~admonish note title="Inductive"
If you've used proof by induction before, note that the use of "inductive" here is different! Inductive synthesis learns by example; in essence, automating [inductive reasoning](https://en.wikipedia.org/wiki/Inductive_reasoning), which is not the same thing as the inductive principle in mathematics. 
~~~

For more information, I suggest skimming the paper linked above about synthesizing bit-vector manipulation programs.
