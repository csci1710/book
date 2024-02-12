#lang forge/bsl 

/*
  Rough model of binary search on an array of integers.  

  Demonstrates:
   -- need for global assumptions (in this case, to prevent overflow bug)
   -- need to enrich the invariant when using inductive verification (in this case, limits on low/high in prestate)

  Recall: binary search (on an array) searches the array as if it embedded a tree; each step narrows
    the range-to-be-searched by half. 

  Tim Feb 2023/2024
*/

sig IntArray {
    elements: pfunc Int -> Int,
    lastIndex: one Int
}

-- think of this like a well-formedness predicate that we will also use as an invariant to check
pred validArray[arr: IntArray] {
    -- We can make these more efficient, but good enough for now

    -- no elements before index 0
    all i: Int | i < 0 implies no arr.elements[i]
    -- if there's an element, either i=0 or there's something at i=1
    -- also the array is sorted:
    all i: Int | some arr.elements[i] implies {
        i = 0 or some arr.elements[subtract[i, 1]]
        arr.elements[i] >= arr.elements[subtract[i, 1]]
    }
    -- size variable reflects actual size of array    
    all i: Int | (no arr.elements[i] and some arr.elements[subtract[i, 1]]) implies {
        arr.lastIndex = subtract[i, 1]
    }    
    {all i: Int | no arr.elements[i]} implies 
      {arr.lastIndex = -1}

}

fun firstIndex[arr: IntArray]: one Int {    
    arr.lastIndex = -1  => -1    
                      else  0
}

-- Model the current state of a binary-search run on the array: the area to be searched
-- is everything from index [low] to index [high], inclusive of both. The [target] is 
-- the value being sought, and [arr] is the entire array being searched.
sig SearchState {
    arr: one IntArray,
    low: one Int,
    high: one Int,
    target: one Int
}

-- What is an initial state of the search? There are many, depending on the actual 
-- array and the actual target. But it should be a valid array, and it should start
-- with the obligation to search the entire array.
pred init[s: SearchState] {
    validArray[s.arr]
    s.low = firstIndex[s.arr]
    s.high = s.arr.lastIndex    
    -- no constraints on the target; may search for any value
}

-- Our transition predicate. There are no parameters, because the 
-- target, etc. are fixed at the start of the search. 
pred stepNarrow[pre: SearchState, post: SearchState] {    
    -- mid = (low+high)/2  (rounded down)
    let mid = divide[add[pre.low, pre.high], 2] | {
      -- GUARD: must continue searching, this isn't it
      pre.arr.elements[mid] != pre.target
      -- ACTION: narrow left or right
      (pre.arr.elements[mid] < pre.target)
          => {
            -- need to go higher
            post.low = add[mid, 1]
            post.high = pre.high            
          }
          else {
            -- need to go lower
            post.low = pre.low
            post.high = subtract[mid, 1]
          }
      -- FRAME: these don't change
      post.arr = pre.arr
      post.target = pre.target
    }
}

-- Termination condition for the search: if low > high, we should stop.
pred searchFailed[pre: SearchState] {
    pre.low > pre.high
}
-- Termination condition for the search: if we found the element, stop.
pred searchSucceed[pre: SearchState] {
    let mid = divide[add[pre.low, pre.high], 2] |
        pre.arr.elements[mid] = pre.target      
}

-- For trace-based analysis, prevent early deadlock
pred stepDoneFail[pre: SearchState, post: SearchState] {    
    -- GUARD: low and high have crossed 
    searchFailed[pre]
    -- ACTION: no change
    post.arr = pre.arr
    post.target = pre.target
    post.low = pre.low
    post.high = pre.high    
}
pred stepDoneSucceed[pre: SearchState, post: SearchState] {
    -- GUARD: mid = target
    -- Note: bad error message if we leave out .elements and say pre.arr[mid]
    searchSucceed[pre]
    -- ACTION: no change
    post.arr = pre.arr
    post.target = pre.target
    post.low = pre.low
    post.high = pre.high    
}

pred anyTransition[pre: SearchState, post: SearchState] {
    stepNarrow[pre, post]      or
    stepDoneFail[pre, post]    or
    stepDoneSucceed[pre, post]
}

-- Binary search (not so) famously breaks if the array is too long, and low+high overflows
-- We can always represent max[Int] (but not #Int; we'd never have enough integers since negatives exist) 
pred safeArraySize[arr: IntArray] {
    -- E.g., if lastIndex is 5, there are 6 elements in the array. If the first step takes us from (0, 6) to
    -- (3,6) then (high+low) = 9, which cannot be represented in Forge with 4 bits. We need to prevent that.
    -- (See: https://ai.googleblog.com/2006/06/extra-extra-read-all-about-it-nearly.html)
    
    // FILL (Exercise 2--3)
}

test expect {
    -- It's possible to narrow on the first transition (this is the common case)
    narrowFirstPossible: {
        some s1,s2: SearchState | { 
            init[s1]
            safeArraySize[s1.arr]        
            stepNarrow[s1, s2]
        }
    } for exactly 1 IntArray, exactly 2 SearchState 
    is sat

    -- If the first state has the target exactly in the middle, we can succeed immediately
    doneSucceedFirstPossible: {
        some s1,s2: SearchState | { 
            init[s1]
            safeArraySize[s1.arr]        
            stepDoneSucceed[s1, s2]
        }
    } for exactly 1 IntArray, exactly 2 SearchState
    is sat

    -- Since we start with high >= low, the failure condition can't already be reached
    doneFailFirstPossible: {
        some s1,s2: SearchState | { 
            init[s1]
            safeArraySize[s1.arr]        
            stepDoneFail[s1, s2]
        }
    } for exactly 1 IntArray, exactly 2 SearchState
    is unsat
}

pred bsearchInvariant[s: State] {
    -- If the target is present, it's located between low and high
    all i: Int | {    
        s.arr.elements[i] = s.target => {
            s.low <= i
            s.high >= i

            // FILL (exercise 2--3)
        }        
    }    
}

//////////////////////
// EXERCISE 1
//////////////////////
// test expect {
//     initStep: {
//         // FILL: what describes the check that init states must satisfy the invariant?
//     } for exactly 1 IntArray, exactly 1 SearchState
//     is unsat

//     inductiveStep: {
//         // FILL: what describes the check that transitions always satisfy the invariant?
//     } for exactly 1 IntArray, exactly 2 SearchState
//     is unsat
//
//}

-- Visual check: show a first transition of any type
run {
    some s1,s2: SearchState | { 
        init[s1]
        safeArraySize[s1.arr]        
        anyTransition[s1, s2]
    }
} for exactly 1 IntArray, exactly 2 SearchState

