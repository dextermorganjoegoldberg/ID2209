/**
* Name: NewModel
* Based on the internal empty template. 
* Author: Zhinan Gao & Jinyao Zhou
* Tags: 
*/


model NQueensProblem
global {
    int boardSize <- 12; 
    
    init {
        create QueenAgent number: boardSize;
    }
    list<QueenAgent> queenAgents;
    list<Chessboard> chessboards;
}

species QueenAgent skills:[fipa] {
    int agentIndex;
    int currentRow <- 0;
    Chessboard currentPosition <- nil;
    bool noPositionFound <- false; 	
    bool foundPosition <- false; 
    bool searchPosition <- false; 
    
    init {
        queenAgents << self;
        location <- {-10, 0};
        agentIndex <- length(queenAgents) - 1;
        if (length(queenAgents) = boardSize) {
            do start_conversation with:(to: [queenAgents[0]], protocol: 'fipa-request', performative: 'inform', contents: ['FindPosition']);        
            write "Let's get started!!!!";
        }
    }
    
    reflex receiveMessages when: !empty(informs) {
        message msg <- informs[0];
        if(container(msg.contents)[0] = 'FindPosition') {
            searchPosition <- true;
            write name + ": Searching a new position";
        } else if (container(msg.contents)[0] = 'RePosition') {
            currentRow <- (currentRow + 1) mod boardSize;
            foundPosition <- false;
            currentPosition.busy <- false;
            currentPosition <- nil; 
            location <- {-10, 0};
            
            if (currentRow = 0) {
                noPositionFound <- true;
            } else {
                searchPosition <- true;
            }
        }
        informs <- nil;
    }
    
   reflex inform when: (noPositionFound or foundPosition) {
    if (noPositionFound) {
        QueenAgent predecessor <- queenAgents[agentIndex - 1];
        do start_conversation with:(to: [predecessor], protocol: 'fipa-request', performative: 'inform', contents: ['RePosition']);
        write name + ": is asking " + predecessor.name + " to move";
        noPositionFound <- false;
    } else if (foundPosition) {
        if (agentIndex != boardSize - 1) {
            QueenAgent successor <- queenAgents[agentIndex + 1];
            write name + ": Found a position: " + currentPosition.name;
            do start_conversation with:(to: [successor], protocol: 'fipa-request', performative: 'inform', contents: ['FindPosition']);
        } else {
            write "All queens found their positions!";
        }
        foundPosition <- false;
    }
}
    
    reflex searchPosition when: searchPosition{
        bool safePlace;
        searchPosition <- false;
        loop i from: currentRow to: boardSize - 1 {   
            safePlace <- checkRowAndColumnAndDiagonal(i, agentIndex);
            if(safePlace) {
                currentRow <- i;
                currentPosition <- chessboards[(boardSize * i) + agentIndex];
                location <- currentPosition.location;
                currentPosition.busy <- true;
                foundPosition <- true;
                break;
            }
            
            if(i = (boardSize-1) and !foundPosition) {
                noPositionFound <- true;
                currentRow <- 0;
                foundPosition <- false;
                location <- (point(-10,0));
                break;
            }
        } 
    }
    
    bool checkRowAndColumnAndDiagonal(int row, int col) {
        int c <- agentIndex - 1;
        loop while: c >= 0 {
            Chessboard square <- chessboards[(boardSize * row) + c];
            if (square.busy = true) {
                return false;
            }
            c <- c - 1;
        }

        int r <- row - 1;
        loop while: r >= 0 {
            Chessboard square <- chessboards[(boardSize * r) + col];
            if (square.busy = true) {
                return false;
            }
            r <- r - 1;
        }

        int x <- col - 1;
        int y <- row - 1;
        loop while: (y >= 0 and x >= 0) {
            Chessboard square <- chessboards[(boardSize * y) + x];
            if (square.busy = true) {
                return false;
            }
            y <- y - 1;
            x <- x - 1;
        }

        x <- col + 1;
        y <- row - 1;
        loop while: (y < boardSize and y >= 0 and x >= 0) {
            Chessboard square <- chessboards[(boardSize * y) + x];
            if (square.busy = true) {
                return false;
            }
            y <- y + 1;
            x <- x - 1;
        }

        x <- col + 1;
        y <- row + 1;
        loop while: (y < boardSize and x < boardSize) {
            Chessboard square <- chessboards[(boardSize * y) + x];
            if (square.busy = true) {
                return false;
            }
            y <- y + 1;
            x <- x + 1;
        }

        x <- col - 1;
        y <- row + 1;
        loop while: (y < boardSize and y >= 0 and x >= 0) {
            Chessboard square <- chessboards[(boardSize * y) + x];
            if (square.busy = true) {
                return false;
            }
            y <- y + 1;
            x <- x - 1;
        }

        return true;
    }
    
    aspect default {
        draw circle(2) at: location  color: #skyblue;
    }
}

grid Chessboard skills: [fipa] width: boardSize height: boardSize {
    bool busy <- false;
    
    init {
        if (even(grid_x) and even(grid_y)) {
            color <- #black;
        } else if (!even(grid_x) and !even(grid_y)) {
            color <- #black;
        } else {
            color <- #pink;
        }
        chessboards << self;
    }
}

experiment NQueens type: gui {
    output {
        display QueensDisplay {
            grid Chessboard lines: #black ;
            species QueenAgent;
        }
    }
}
