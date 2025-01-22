#lang forge

/*
  Model of ROBDDs
  Tim Nelson (December 2024)
*/


sig Variable {}

abstract sig Node {}
sig Split extends Node {
    v: one Variable,
    t: one Node,
    f: one Node
}

// Allow duplicate True, False nodes in the overall model, so we can show reduction.
sig True, False extends Node {}

pred is_bdd {
    // There is only one split node with no parents (the root)
    one s: Split | no s.(~t + ~f)
    // There are no cycles (including no self loops)
    all n1, n2: Node | n1 in n2.^(t+f) implies n2 not in n1.^(t+f)
}

pred is_ordered {
    // There is an ordering of variables that the induced node-ordering of t, f respects. 
    // We won't make this explicit, but rather will say that any time there is reachability 
    // from n1 to n2, no other reachability with opposite variables exists. 
    all disj n1, n2: Split | n2 in n1.^(t+f) => {
        no m1, m2: Split | {
            m2 in m1.^(t+f)
            m1.v = n2.v
            m2.v = n1.v
        }
    }
}

pred is_reduced {
    // No node has the same t-child and f-child
    all s: Split | s.t != s.f
    // No 2 nodes are roots are isomorphic subgraphs. We'll encode this in a way that 
    // doesn't require a notion of isomorphism. Instead, we'll take advantage of an
    // induction property. 
    // Base case: no duplicate terminal nodes.
    lone True
    lone False 
    // Inductive case, on reverse-depth, no two nodes point to same T/F children.
    all disj s1, s2: Split | {
        s1.t != s2.t or s1.f != s2.f
    }
}

pred is_robdd {
    is_bdd
    is_ordered
    is_reduced
}

// Uncomment to visualize a 10-node ROBDD.
// run { is_robdd } for exactly 10 Node

-------------------
-- Examples
-------------------

/** Siddhartha's non-ordered BDD Example */
example not_ordered is {not is_ordered} for {
    Variable = `V0 + `V1 + `V2
    True = `True 
    False = `False 
    Split = `N0 + 
          `N1 + `N2 + 
          `N3 + `N4 
    Node = True + False + Split

    `N0.v = `V0 -- rank 0
    `N1.v = `V1 -- rank 1
    `N2.v = `V2 -- rank 1
    `N3.v = `V2 -- rank 2
    `N4.v = `V1 -- rank 2
    
    `N0.t = `N1 
    `N0.f = `N2
    
    `N1.t = `N3 
    `N1.f = True
    `N2.t = True 
    `N2.f = `N4
    
    `N3.t = True 
    `N3.f = False 
    `N4.t = False 
    `N4.f = True
}

-----------------------------------------------------------------------------------------
// Ok, but now I have some things I want to confirm about BDDs (up to this definition).
-----------------------------------------------------------------------------------------

// The final non-terminal tier of the ROBDD must always have either 0 or 2 nodes, 
// as a consequence of the fact that no 2 nodes can represent the same boolean function.
// I expect...

/*
test expect { 
    final_nonterminal_2: {
        is_robdd implies {
            #(True.~(t+f) + False.~(t+f)) in (0 + 2)
        }
    } for 8 Node is checked
}*/

// That fails! But the CE is a single-variable example. Maybe it doesn't happen on a multi-var 
// example? (Click next.) It does! Right, because the point is that the final "tier" might only
// need 1 node, but other tiers skip directly to the terminals. 

-----------------------------------------------------

// I'd like to express the canonicity property: for any two non-isomorphic ROBDDs using the 
// same variable ordering, they express different boolean functions. This is challenging for 
// two reasons: 
//   (1) We need to express "non-isomorphic".
//   (2) we need to express "different boolean function". 

// (2) 
// In general we can't always use a sig Valuation with `all`, or we'll run into the 
// unbounded universal quantification problem (unless we create 2^#vars Valuations). But if 
// the polarity is always negative -- i.e., we're only ever saying that the two are _NOT_ 
// equivalent -- we could write `some vs: Valuation | isTrue[bdd1, vs] and not isTrue[bdd2, vs]. 
// It's when we start saying `all vs: Valuation | ...` that we run into the problem. 

// (1) 
// This *might* be easier than graph isomorphism (negated) modulo these are DAGs. They aren't 
// always trees, of course. But here the `all` is a problem: we aren't searching for an isomorphism
// function, we're saying that for _any_ such function, it isn't an isomorphism. 
// There may be better characterizations, however. So let's do the infrastructure, and slowly 
// add different partial characterizations. E.g., we can surely check whether the two have the 
// same number of nodes for each variable. Along the way, we'll get counterexamples and try 
// to use each to refine our definition. 

// We'll also need to enrich the model to allow for multiple BDDs. 

pred unfinished_isomorphic[root1, root2: Node] {

  // Same number of nodes assigned to each variable? 
  // 

}

pred non_equivalent[root1, root2: Node] {

}