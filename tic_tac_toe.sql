-- Create the tic_tac_toe table
CREATE TABLE tic_tac_toe (
    game_id SERIAL PRIMARY KEY,
    board CHAR(9) NOT NULL DEFAULT '---------',
    current_player CHAR(1) NOT NULL DEFAULT 'X',
    game_status CHAR(10) NOT NULL DEFAULT 'ongoing'
);

-- Create the NewGame function
CREATE OR REPLACE FUNCTION NewGame() RETURNS INTEGER AS $$
DECLARE
    new_game_id INTEGER;
BEGIN
    INSERT INTO tic_tac_toe (board, current_player, game_status)
    VALUES ('---------', 'X', 'ongoing')
    RETURNING game_id INTO new_game_id;
    
    RETURN new_game_id;
END;
$$ LANGUAGE plpgsql;

-- Create the check_winner function
CREATE OR REPLACE FUNCTION check_winner(board CHAR(9)) RETURNS CHAR(1) AS $$
BEGIN
    IF board[1:3] = 'XXX' OR board[4:6] = 'XXX' OR board[7:9] = 'XXX' OR
       board[1] = 'X' AND board[4] = 'X' AND board[7] = 'X' OR
       board[2] = 'X' AND board[5] = 'X' AND board[8] = 'X' OR
       board[3] = 'X' AND board[6] = 'X' AND board[9] = 'X' OR
       board[1] = 'X' AND board[5] = 'X' AND board[9] = 'X' OR
       board[3] = 'X' AND board[5] = 'X' AND board[7] = 'X' THEN
        RETURN 'X';
    ELSIF board[1:3] = 'OOO' OR board[4:6] = 'OOO' OR board[7:9] = 'OOO' OR
          board[1] = 'O' AND board[4] = 'O' AND board[7] = 'O' OR
          board[2] = 'O' AND board[5] = 'O' AND board[8] = 'O' OR
          board[3] = 'O' AND board[6] = 'O' AND board[9] = 'O' OR
          board[1] = 'O' AND board[5] = 'O' AND board[9] = 'O' OR
          board[3] = 'O' AND board[5] = 'O' AND board[7] = 'O' THEN
        RETURN 'O';
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create the NextMove function with resolved ambiguity
CREATE OR REPLACE FUNCTION NextMove(p_game_id INTEGER, x INTEGER, y INTEGER, val CHAR DEFAULT NULL) RETURNS CHAR(10) AS $$
DECLARE
    current_board CHAR(9);
    current_player_var CHAR(1);
    new_board CHAR(9);
    position INTEGER;
    winner CHAR(1);
BEGIN
    -- Validate inputs
    IF x NOT BETWEEN 1 AND 3 OR y NOT BETWEEN 1 AND 3 THEN
        RAISE EXCEPTION 'Coordinates out of bounds';
    END IF;
    
    -- Get the current game state using a table alias to resolve ambiguity
    SELECT t.board, t.current_player INTO current_board, current_player_var 
    FROM tic_tac_toe t
    WHERE t.game_id = p_game_id FOR UPDATE;
    
    -- Determine the position in the board string
    position := (x - 1) * 3 + (y - 1);
    
    -- Check if the position is already occupied
    IF SUBSTRING(current_board FROM position + 1 FOR 1) <> '-' THEN
        RAISE EXCEPTION 'Position already occupied';
    END IF;
    
    -- Determine the symbol for the move
    IF val IS NULL THEN
        val := current_player_var;
    END IF;
    
    -- Update the board
    new_board := overlay(current_board placing val from position + 1 for 1);
    
    -- Check for a winner
    winner := check_winner(new_board);
    
    -- Update the game state
    IF winner IS NOT NULL THEN
        UPDATE tic_tac_toe
        SET board = new_board, game_status = winner || '_wins'
        WHERE game_id = p_game_id;
        RETURN winner || ' wins';
    ELSIF new_board NOT LIKE '%-%' THEN
        UPDATE tic_tac_toe
        SET board = new_board, game_status = 'draw'
        WHERE game_id = p_game_id;
        RETURN 'draw';
    ELSE
        -- Switch the current player
        current_player_var := CASE current_player_var WHEN 'X' THEN 'O' ELSE 'X' END;
        UPDATE tic_tac_toe
        SET board = new_board, current_player = current_player_var
        WHERE game_id = p_game_id;
        RETURN new_board;
    END IF;
END;
$$ LANGUAGE plpgsql;
