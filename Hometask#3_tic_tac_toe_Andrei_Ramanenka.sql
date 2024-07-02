DROP TABLE IF EXISTS tic_tac_toe_board;

CREATE TABLE tic_tac_toe_board (
    id SERIAL PRIMARY KEY,
    x INT NOT NULL,
    y INT NOT NULL,
    value CHAR(1) CHECK (value IN ('X', 'O')),
    UNIQUE (x, y)
);

CREATE OR REPLACE FUNCTION NewGame() RETURNS VOID AS $$
BEGIN
    DELETE FROM tic_tac_toe_board;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS CheckGameState();

CREATE OR REPLACE FUNCTION CheckGameState() RETURNS TEXT AS $$
DECLARE
    winner CHAR(1);
    full_board BOOLEAN;
BEGIN
    FOR winner IN
        SELECT value FROM tic_tac_toe_board
        WHERE (x, y) IN ((1,1), (1,2), (1,3))
        GROUP BY value
        HAVING COUNT(*) = 3
        UNION
        SELECT value FROM tic_tac_toe_board
        WHERE (x, y) IN ((2,1), (2,2), (2,3))
        GROUP BY value
        HAVING COUNT(*) = 3
        UNION
        SELECT value FROM tic_tac_toe_board
        WHERE (x, y) IN ((3,1), (3,2), (3,3))
        GROUP BY value
        HAVING COUNT(*) = 3
        UNION
        SELECT value FROM tic_tac_toe_board
        WHERE (x, y) IN ((1,1), (2,1), (3,1))
        GROUP BY value
        HAVING COUNT(*) = 3
        UNION
        SELECT value FROM tic_tac_toe_board
        WHERE (x, y) IN ((1,2), (2,2), (3,2))
        GROUP BY value
        HAVING COUNT(*) = 3
        UNION
        SELECT value FROM tic_tac_toe_board
        WHERE (x, y) IN ((1,3), (2,3), (3,3))
        GROUP BY value
        HAVING COUNT(*) = 3
        UNION
        SELECT value FROM tic_tac_toe_board
        WHERE (x, y) IN ((1,1), (2,2), (3,3))
        GROUP BY value
        HAVING COUNT(*) = 3
        UNION
        SELECT value FROM tic_tac_toe_board
        WHERE (x, y) IN ((1,3), (2,2), (3,1))
        GROUP BY value
        HAVING COUNT(*) = 3
    LOOP
        RETURN 'Winner: ' || winner;
    END LOOP;

    SELECT COUNT(*) = 9 INTO full_board FROM tic_tac_toe_board;
    IF full_board THEN
        RETURN 'Draw';
    END IF;

    RETURN 'Game in progress!';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION NextMove(X INT, Y INT, Val CHAR(1) DEFAULT NULL) RETURNS TEXT AS $$
DECLARE
    next_symbol CHAR(1);
    last_symbol CHAR(1);
	board_state TEXT;
BEGIN
    IF CheckGameState() != 'Game in progress!' THEN
        RETURN CheckGameState();
    END IF;

    IF Val IS NULL THEN
        SELECT value INTO last_symbol FROM tic_tac_toe_board ORDER BY id DESC LIMIT 1;
        IF last_symbol IS NULL OR last_symbol = 'O' THEN
            next_symbol := 'X';
        ELSE
            next_symbol := 'O';
        END IF;
    ELSE
        next_symbol := Val;
    END IF;

    BEGIN
        INSERT INTO tic_tac_toe_board (x, y, value) VALUES (X, Y, next_symbol);
    EXCEPTION
        WHEN unique_violation THEN
            RETURN 'Invalid move: Position already taken';
    END;
	

    IF CheckGameState() = 'Game in progress!' THEN
        SELECT
            '{{"' || COALESCE(MAX(CASE WHEN tic_tac_toe_board.x = 1 AND tic_tac_toe_board.y = 1 THEN value END), ' ') || '","' ||
            COALESCE(MAX(CASE WHEN tic_tac_toe_board.x = 1 AND tic_tac_toe_board.y = 2 THEN value END), ' ') || '","' ||
            COALESCE(MAX(CASE WHEN tic_tac_toe_board.x = 1 AND tic_tac_toe_board.y = 3 THEN value END), ' ') || '"},{"' ||

            COALESCE(MAX(CASE WHEN tic_tac_toe_board.x = 2 AND tic_tac_toe_board.y = 1 THEN value END), ' ') || '","' ||
            COALESCE(MAX(CASE WHEN tic_tac_toe_board.x = 2 AND tic_tac_toe_board.y = 2 THEN value END), ' ') || '","' ||
            COALESCE(MAX(CASE WHEN tic_tac_toe_board.x = 2 AND tic_tac_toe_board.y = 3 THEN value END), ' ') || '"},{"' ||

            COALESCE(MAX(CASE WHEN tic_tac_toe_board.x = 3 AND tic_tac_toe_board.y = 1 THEN value END), ' ') || '","' ||
            COALESCE(MAX(CASE WHEN tic_tac_toe_board.x = 3 AND tic_tac_toe_board.y = 2 THEN value END), ' ') || '","' ||
            COALESCE(MAX(CASE WHEN tic_tac_toe_board.x = 3 AND tic_tac_toe_board.y = 3 THEN value END), ' ') || '"}}'
        INTO
            board_state
        FROM
            tic_tac_toe_board;
        
        RETURN board_state;
    END IF;
	
    RETURN CheckGameState();
END;
$$ LANGUAGE plpgsql;
