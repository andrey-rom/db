-- Drop the tic_tac_toe table if it already exists
DROP TABLE IF EXISTS tic_tac_toe;

-- Create the tic_tac_toe table with board as TEXT
CREATE TABLE tic_tac_toe (
    game_id SERIAL PRIMARY KEY,
    board TEXT NOT NULL DEFAULT '---------',
    current_player CHAR(1) NOT NULL DEFAULT 'X',
    game_status CHAR(10) NOT NULL DEFAULT 'ongoing'
);

-- Drop the NewGame function if it already exists
DROP FUNCTION IF EXISTS NewGame();

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

-- Drop the check_winner function if it already exists
DROP FUNCTION IF EXISTS check_winner(TEXT);

-- Create the check_winner function
CREATE OR REPLACE FUNCTION check_winner(board TEXT) RETURNS CHAR(1) AS $$
BEGIN
    IF SUBSTRING(board FROM 1 FOR 3) = 'XXX' OR SUBSTRING(board FROM 4 FOR 3) = 'XXX' OR SUBSTRING(board FROM 7 FOR 3) = 'XXX' OR
       SUBSTRING(board FROM 1 FOR 1) = 'X' AND SUBSTRING(board FROM 4 FOR 1) = 'X' AND SUBSTRING(board FROM 7 FOR 1) = 'X' OR
       SUBSTRING(board FROM 2 FOR 1) = 'X' AND SUBSTRING(board FROM 5 FOR 1) = 'X' AND SUBSTRING(board FROM 8 FOR 1) = 'X' OR
       SUBSTRING(board FROM 3 FOR 1) = 'X' AND SUBSTRING(board FROM 6 FOR 1) = 'X' AND SUBSTRING(board FROM 9 FOR 1) = 'X' OR
       SUBSTRING(board FROM 1 FOR 1) = 'X' AND SUBSTRING(board FROM 5 FOR 1) = 'X' AND SUBSTRING(board FROM 9 FOR 1) = 'X' OR
       SUBSTRING(board FROM 3 FOR 1) = 'X' AND SUBSTRING(board FROM 5 FOR 1) = 'X' AND SUBSTRING(board FROM 7 FOR 1) = 'X' THEN
        RETURN 'X';
    ELSIF SUBSTRING(board FROM 1 FOR 3) = 'OOO' OR SUBSTRING(board FROM 4 FOR 3) = 'OOO' OR SUBSTRING(board FROM 7 FOR 3) = 'OOO' OR
          SUBSTRING(board FROM 1 FOR 1) = 'O' AND SUBSTRING(board FROM 4 FOR 1) = 'O' AND SUBSTRING(board FROM 7 FOR 1) = 'O' OR
          SUBSTRING(board FROM 2 FOR 1) = 'O' AND SUBSTRING(board FROM 5 FOR 1) = 'O' AND SUBSTRING(board FROM 8 FOR 1) = 'O' OR
          SUBSTRING(board FROM 3 FOR 1) = 'O' AND SUBSTRING(board FROM 6 FOR 1) = 'O' AND SUBSTRING(board FROM 9 FOR 1) = 'O' OR
          SUBSTRING(board FROM 1 FOR 1) = 'O' AND SUBSTRING(board FROM 5 FOR 1) = 'O' AND SUBSTRING(board FROM 9 FOR 1) = 'O' OR
          SUBSTRING(board FROM 3 FOR 1) = 'O' AND SUBSTRING(board FROM 5 FOR 1) = 'O' AND SUBSTRING(board FROM 7 FOR 1) = 'O' THEN
        RETURN 'O';
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Drop the NextMove function if it already exists
DROP FUNCTION IF EXISTS NextMove(INTEGER, INTEGER, INTEGER, CHAR);

-- Create the NextMove function with resolved ambiguity
CREATE OR REPLACE FUNCTION NextMove(p_game_id INTEGER, x INTEGER, y INTEGER, val CHAR DEFAULT NULL) RETURNS CHAR(10) AS $$
DECLARE
    current_board TEXT;
    current_player_var CHAR(1);
    new_board TEXT;
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
    position := (x - 1) * 3 + y;
    
    -- Check if the position is already occupied
    IF SUBSTRING(current_board FROM position FOR 1) <> '-' THEN
        RAISE EXCEPTION 'Position already occupied';
    END IF;
    
    -- Determine the symbol for the move
    IF val IS NULL THEN
        val := current_player_var;
    END IF;
    
    -- Update the board
    new_board := overlay(current_board placing val from position for 1);
    
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

/*
SELECT NewGame();
SELECT NextMove(1, 1, 1);
SELECT NextMove(1, 1, 2);
SELECT NextMove(1, 2, 2);
SELECT NextMove(1, 1, 3);
SELECT NextMove(1, 3, 3);
*/
