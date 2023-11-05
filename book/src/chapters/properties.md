# From Tests to Properties 

(Working in code, not modeling yet)

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
