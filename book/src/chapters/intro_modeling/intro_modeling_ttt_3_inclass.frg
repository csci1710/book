#lang forge/bsl 
-- ^ "Froglet" 

/*
Concepts we might want to include in the model:
  - grid, board
  - moves 
  - players X O (only)
  - finite amount of board _states_
  - win condition, tie condition

  - constraint: moves alternate
  - constraint: can't move if moved there already
  - constraint: game ends if someone has won
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
pred wellformed {
    all b: Board | { 
        all row, col: Int | {
            (row < MIN or row > 2 or 
            col < 0 or col > 2) implies
                no b.board[row][col]
    } }
}

-- show me a world in which...
-- run {wellformed}

example firstRowX_wellformed is {wellformed} for {
    Board = `Board0
    X = `X0
    O = `O0
    Player = X + O
    `Board0.board = (0,0) -> X + 
                    (0,1) -> X + 
                    (0,2) -> X
}
example offBoardX_not_wellformed is {not wellformed} for {
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
    //not winning[pre, O]
    //(not winning[post, X] or winning[post, O])
  }
}
test expect {
  winningPreserved: { 
    wellformed
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
        some row, col: Int, p: Player | 
            move[b, row, col, p, Game.next[b]]
        -- TODO: ensure X moves first
    }}
}
-- run { game_trace } for 10 Board for {next is linear}
// ^ the annotation is faster than the constraint

-----------------------------------
-- Added 2/5/24, from EdStem thread

-- Note I lowered the number of boards. We'll talk about why on Wednesday
--assert game_trace is sufficient for wellformed
--  for 5 Board for {next is linear}


