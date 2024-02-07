#lang forge/bsl 
-- ^ "Froglet" 

/*
  Continuing the tic-tac-toe example, this time with games 
*/

abstract sig Player {} 
one sig X, O extends Player {} 

sig Board {
    -- partial function from pairs of Int to Player
    -- read the inner -> as , 
    board: pfunc Int -> Int -> Player
}

-- AFTER CLASS QUESTION: yes you can define global constants like this:
fun MIN: one Int { 0 }
fun MAX: one Int { 2 }

-- predicate: rule out "garbage"
pred wellformed[b: Board] {
    all row, col: Int | {
            (row < MIN or row > 2 or 
            col < 0 or col > 2) implies
                no b.board[row][col]
    } 
}

-- show me a world in which...
-- run {some b: Board | wellformed[b]}

pred allBoardsWellformed { all b: Board | wellformed[b] }
example firstRowX_wellformed is {allBoardsWellformed} for {
    Board = `Board0
    X = `X0
    O = `O0
    Player = X + O
    `Board0.board = (0,0) -> X + 
                    (0,1) -> X + 
                    (0,2) -> X
}
example offBoardX_not_wellformed is {not allBoardsWellformed} for {
    Board = `Board0
    X = `X0
    O = `O0
    Player = X + O
    `Board0.board = (-1,0) -> X + 
                    (0,1) -> X + 
                    (0,2) -> X
}

-------------------------------------
-- Wednesday, Jan 31
-------------------------------------

/* An initial board */
pred initial[b: Board] {
    all row, col: Int | no b.board[row][col]
}

/* Whose turn is it (if anyone's)? */
pred xturn[b: Board] {
    #{row, col: Int | b.board[row][col] = X} 
    = 
    #{row, col: Int | b.board[row][col] = O} 
}

pred oturn[b: Board] {
    #{row, col: Int | b.board[row][col] = X} 
    = 
    add[#{row, col: Int | b.board[row][col] = O}, 1]
}

pred balanced[b: Board] {
    xturn[b] or oturn[b]
}

pred winning[b: Board, p: Player] {
    -- 3 in a row
    (some r: Int | { 
        b.board[r][0] = p and
        b.board[r][1] = p and
        b.board[r][2] = p 
    })
    or
    -- 3 in a col 
    (some c: Int | { 
        b.board[0][c] = p 
        b.board[1][c] = p 
        b.board[2][c] = p 
    })
    or { 
        b.board[0][0] = p 
        b.board[1][1] = p 
        b.board[2][2] = p 
    }
    or { 
        b.board[0][2] = p 
        b.board[1][1] = p 
        b.board[2][0] = p 
    }

}

-- "transition relation"
pred move[pre: Board, 
          row, col: Int, 
          turn: Player, 
          post: Board] {
    -- guard: conditions necessary to make a move  
    -- cant move somewhere with an existing mark
    -- valid move location
    -- it needs to be the player's turn 
    no pre.board[row][col]
    turn = X implies xturn[pre]
    turn = O implies oturn[pre]

    -- prevent winning boards from progressing
    all p: Player | not winning[pre, p]

    -- enforce valid move index
    row >= 0 
    row <= 2 
    col >= 0
    col <= 2

    -- balanced game
    -- game hasn't been won yet
    -- if it's a tie can't move 
    -- board needs to be well-formed 

    -- action: effects of making a move

    -- mark the location with the player 
    post.board[row][col] = turn 
    -- updating the board; check for winner or tie 
    -- other squares stay the same  ("frame condition")
    all row2: Int, col2: Int | (row!=row2 or col!=col2) implies {
        post.board[row2][col2] = pre.board[row2][col2]
    }
}

pred doNothing[pre, post: board] {
    -- guard
    some p: Player | winning[pre, p]

    -- action
    all r, c: Int | {
        pre.board[r][c] = post.board[r][c]
    }
}

-------------------------------------
-- Friday, Feb 02
-------------------------------------

-- What can we do with "move"?
-- Preservation: 
pred winningPreservedCounterexample {
  some pre, post: Board | {
    some row, col: Int, p: Player | 
      move[pre, row, col, p, post]
    winning[pre, X]
    not winning[post, X]
  }
}
test expect {
  winningPreserved: { 
    allBoardsWellformed
    winningPreservedCounterexample } is unsat
}

-- This gives Forge a visualizer script to automatically run, without requiring you
-- to copy-paste it into the script editor. CHANGES WILL NOT BE REFLECTED IN THE FILE!
option run_sterling "ttt_viz.js"

// run {
//     wellformed 
//     some pre, post: Board | {
//         some row, col: Int, p: Player | 
//             move[pre, row, col, p, post]
//     }
// }

one sig Game {
    first: one Board, 
    next: pfunc Board -> Board
}
pred game_trace {
    initial[Game.first]
    all b: Board | { some Game.next[b] implies {
        (some row, col: Int, p: Player | 
            move[b, row, col, p, Game.next[b]])
        or
        doNothing[b, Game.next[b]]
        -- TODO: ensure X moves first
    }}
}
// run { 
//     game_trace
//     all b: Board | { 
//         some r,c: Int | {
//             r >=0 r <= 2 
//             c >=0 c <= 2
//             no b.board[r][c]
//         }
//     }
// } for 10 Board for {next is linear}
// // ^ the annotation is faster than the constraint


-------------------------------
-- Validation
-------------------------------

pred moved[b: Board] { 
    some post: Board, r,c: Int, p: Player | 
        move[b, r, c, p, post] }
pred didntDoNothing[b: Board] {
    not { some post: Board | doNothing[b, post]} }
assert all b: Board | 
  moved[b] is sufficient for didntDoNothing[b]
// sufficient ~= implies
// necessary ~= implies-in-reverse
assert all b: Board | 
  moved[b] is necessary for didntDoNothing[b]
-- ^ This fails, perhaps because the _final_ board won't 
--   be able to take either transition (perhaps)...
