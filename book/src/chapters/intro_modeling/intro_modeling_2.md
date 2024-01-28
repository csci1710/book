# Introduction to Modeling (Part 2)

**THESE NOTES ARE IN DRAFT FORM, AND MAY CHANGE BEFORE THE CORRESPONDING CLASS MEETING.**

<!-- NEED TO MAKE ROOM FOR A TEST OR TWO; USE EXAMPLE AND ASSERT -->

## Logistics

The first lab starts today! The starter model is a _variant_ of the livecode that we produced in class. It also contains a possible version of the `move` predicate we started writing. 

Expect Forge updates roughly weekly. Please keep Forge updated. You'll want to update it for the lab, today.

## Where We Left Off

Last time, we started running Forge to get _instances_ that contained tic-tac-toe boards. Let's try some variant `run` commands (inspired by live questions in class).

### No Boards

Is it possible for an instance with _no_ boards to still satisfy constraints like these?

```alloy
run {    
     all b: Board | {
         -- X has won, and the board looks OK
         wellformed[b]
         winner[b, X]
         balanced[b]    
     }
 }
```

<details>
<summary>Think, then click!</summary>
Yes! There aren't any boards, so there's no obligation for anything to satisfy the constraints inside the quantifier. You can think of the `all` as something like a `for` loop in Java or the `all()` function in Python: it checks every `Board` in the instance. If there aren't any, there's nothing to check---return true.
</details>

### Adding More

We can add more constraints if we have a more focused idea of what we want Forge to find. For example, this addition also requires that `X` moved in the middle of the board:

```alloy
run {    
     all b: Board | {
         -- X has won, and the board looks OK
         wellformed[b]
         winner[b, X]
         balanced[b]
         -- X started in the middle
         b.board[1][1] = X
     }
 } for exactly 2 Board
```

Notice that, because we said `exactly 2 Board` here, Forge _must_ find instances containing 2 tic-tac-toe boards, and both of them must satisfy the constraints: wellformedness, `X` moving in the middle, etc.

#### By Request (added after class)

Yes, `not` also works. So you could ask for a board where `X` _hasn't_ won by adding `not winner[b, X]`. 

You also have `implies` and `iff` (if and only if), although you can still do something like comparing two predicates without `iff` (try, e.g., asking for instances where `A and not B` holds).

## From Boards to Games

What do you think a _game_ of tic-tac-toe looks like? How should we model the moves between board states?

<details>
<summary>Think, then click!</summary>

It's often convenient to think of the game as a big graph, where the nodes are the states (possible board configurations) and the edges are transitions (in this case, legal moves of the game). Here's a rough sketch:  
    
![](https://i.imgur.com/YmsbRp8.png)
  
</details>
<br/>

A game of tic-tac-toe is a sequence of steps in this graph, starting from the empty board. Let's model it.

First, what does a move look like? A player puts their mark at a specific location. In Alloy, we'll represent this using a _transition predicate_: a predicate that says when it's legal for one state to evolve into another. We'll often call these the _pre-state_ and _post-state_ of the transition:

```alloy
pred move[pre: Board, row: Int, col: Int, p: Player, post: Board] {
  // ...
}
```

What constraints should we add? It's useful to divide the contents of such a predicate into:
* a _guard_, which allows the move only if the pre-state is suitable; and 
* an _action_, which defines what is in the post-state based on the pre-state and the move parameters.
 
For the guard, in order for the move to be valid, it must hold that in the pre-state:
* nobody has already moved at the target location; and
* it's the moving player's turn.

For the action:
* the new board is the same as the old, except for the addition of the player's mark at the target location.

Now we can fill in the predicate. Let's try something like this:

```alloy
pred move[pre: Board, row: Int, col: Int, p: Player, post: Board] {
  -- guard:
  no pre.board[row][col]   -- nobody's moved there yet
  p = X implies XTurn[pre] -- appropriate turn
  p = O implies OTurn[pre]  
  
  -- action:
  post.board[row][col] = p
  all row2: Int, col2: Int | (row!=row2 and col!=col2) implies {        
     post.board[row2][col2] = pre.board[row2][col2]     
  }  
}
```

There are many ways to write this predicate. However, we're going to stick with this form because it calls out an important point. Suppose we had only written `post.board[row][col] = p` for the action, without the `all` on the next following lines. Those added lines, which we'll call a _frame condition_, say that all other squares remain unchanged; without them, the contents of any other square might change in any way. Leaving them out would be what's called an _underconstraint bug_: the predicate would be too weak to accurately describe moves in tic-tac-toe. 

**Exercise**: comment out the 3 frame-condition lines and run the model. Do you see moves where the other 8 squares change arbitrarily?

**Exercise**: could there be a bug in this predicate? (Hint: run Forge and find out!)