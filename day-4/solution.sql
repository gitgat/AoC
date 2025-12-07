-- Day 4: Printing Department
--
-- We have a grid of paper rolls (@) and empty spaces (.)
-- Forklifts can only access a roll if it has fewer than 4 neighbors.
--
-- Part 1: Count how many rolls are currently accessible
-- Part 2: Keep removing accessible rolls until none are left.
--         Once you remove a roll, its neighbors might become accessible.
--         How many total rolls can we remove?
--
-- For part 2 we use a recursive approach:
-- store all the roll positions in an array, then each iteration
-- we filter out the ones with < 4 neighbors and keep the rest.

WITH RECURSIVE

-- find all the @ positions in the grid
cells AS (
    SELECT
        line_num AS row,
        pos AS col
    FROM day4_input
    CROSS JOIN LATERAL generate_series(1, LENGTH(line)) AS pos
    WHERE SUBSTRING(line, pos, 1) = '@'
),

-- Part 1: count neighbors for each cell using a join
-- a neighbor is any cell within 1 step in any direction (including diagonal)
neighbor_counts AS (
    SELECT
        c.row,
        c.col,
        COUNT(n.row) AS neighbor_count
    FROM cells c
    LEFT JOIN cells n ON
        n.row BETWEEN c.row - 1 AND c.row + 1
        AND n.col BETWEEN c.col - 1 AND c.col + 1
        AND NOT (n.row = c.row AND n.col = c.col)
    GROUP BY c.row, c.col
),

part1_result AS (
    SELECT COUNT(*) AS answer
    FROM neighbor_counts
    WHERE neighbor_count < 4
),

-- Part 2: simulate removing accessible rolls iteratively
-- we store positions as "row,col" strings in an array
-- each iteration we keep only the cells that have >= 4 neighbors
grid_state(iter, coords, prev_size) AS (
    -- start with all cells
    SELECT 0, ARRAY_AGG(row || ',' || col), 0::BIGINT
    FROM cells

    UNION ALL

    -- each round: filter to keep only cells with 4+ neighbors
    SELECT
        gs.iter + 1,
        ARRAY(
            SELECT coord
            FROM UNNEST(gs.coords) AS coord
            WHERE (
                -- count how many neighbors this cell has
                SELECT COUNT(*)
                FROM UNNEST(gs.coords) AS other
                WHERE other != coord
                  AND ABS(SPLIT_PART(coord, ',', 1)::INT - SPLIT_PART(other, ',', 1)::INT) <= 1
                  AND ABS(SPLIT_PART(coord, ',', 2)::INT - SPLIT_PART(other, ',', 2)::INT) <= 1
            ) >= 4
        ),
        CARDINALITY(gs.coords)
    FROM grid_state gs
    -- keep going until nothing changes
    WHERE gs.iter < 100
      AND CARDINALITY(gs.coords) != gs.prev_size
),

-- the answer is how many we started with minus how many are left at the end
final_state AS (
    SELECT coords
    FROM grid_state
    WHERE iter = (SELECT MAX(iter) FROM grid_state)
),

part2_result AS (
    SELECT (SELECT COUNT(*) FROM cells) - CARDINALITY((SELECT coords FROM final_state)) AS answer
)

SELECT 'Part 1' AS part, answer FROM part1_result
UNION ALL
SELECT 'Part 2' AS part, answer FROM part2_result;
