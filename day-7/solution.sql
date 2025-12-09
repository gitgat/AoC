-- Day 7: Laboratories
--
-- Beam starts at S, moves down. Hits ^ and splits left/right.
-- Beams merge if they end up at the same column.
--
-- Part 1: Count total splits.
-- Part 2: Count total timelines (each split doubles timelines for that beam,
--         merged beams add their timeline counts).

WITH RECURSIVE

-- parse the grid into individual cells
grid AS (
    SELECT
        line_num AS row,
        col,
        SUBSTRING(line, col, 1) AS ch
    FROM day7_input
    CROSS JOIN LATERAL generate_series(1, LENGTH(line)) AS col
),

-- find where the beam starts (the S)
start_pos AS (
    SELECT row, col FROM grid WHERE ch = 'S'
),

-- find all the splitters
splitters AS (
    SELECT row, col FROM grid WHERE ch = '^'
),

-- find the bottom row of the grid
max_row AS (
    SELECT MAX(row) AS val FROM grid
),

-- Part 1: simulate beam movement, count splits
-- track: current row, array of beam columns, cumulative split count
beam_sim_p1 AS (
    SELECT
        row AS current_row,
        ARRAY[col] AS beam_cols,
        0::BIGINT AS total_splits
    FROM start_pos

    UNION ALL

    SELECT
        b.current_row + 1,
        (
            SELECT ARRAY_AGG(DISTINCT new_col ORDER BY new_col)
            FROM (
                SELECT unnest(ARRAY[bc - 1, bc + 1]) AS new_col
                FROM unnest(b.beam_cols) AS bc
                WHERE EXISTS (SELECT 1 FROM splitters s WHERE s.row = b.current_row + 1 AND s.col = bc)
                UNION
                SELECT bc AS new_col
                FROM unnest(b.beam_cols) AS bc
                WHERE NOT EXISTS (SELECT 1 FROM splitters s WHERE s.row = b.current_row + 1 AND s.col = bc)
            ) AS all_new
        ),
        b.total_splits + (
            SELECT COUNT(*)
            FROM unnest(b.beam_cols) AS bc
            WHERE EXISTS (SELECT 1 FROM splitters s WHERE s.row = b.current_row + 1 AND s.col = bc)
        )
    FROM beam_sim_p1 b
    CROSS JOIN max_row m
    WHERE b.current_row < m.val
      AND CARDINALITY(b.beam_cols) > 0
),

-- Part 2: track timeline counts per position
-- each beam position has a count of how many timelines are there
-- splits double timelines, merges add them
beam_sim_p2 AS (
    -- start with 1 timeline at S
    SELECT
        row AS current_row,
        col AS beam_col,
        1::BIGINT AS timeline_count
    FROM start_pos

    UNION ALL

    -- move beams down, use LATERAL to generate new positions
    SELECT
        next_row,
        new_col,
        SUM(tc)::BIGINT AS timeline_count
    FROM (
        SELECT
            b.current_row + 1 AS next_row,
            moves.new_col,
            b.timeline_count AS tc
        FROM beam_sim_p2 b
        CROSS JOIN max_row m
        LEFT JOIN splitters s ON s.row = b.current_row + 1 AND s.col = b.beam_col
        CROSS JOIN LATERAL (
            -- if hit splitter: go left and right (-1 and +1)
            -- if no splitter: stay in same column (0)
            SELECT b.beam_col + d AS new_col
            FROM unnest(
                CASE WHEN s.col IS NOT NULL
                     THEN ARRAY[-1, 1]
                     ELSE ARRAY[0]
                END
            ) AS d
        ) AS moves
        WHERE b.current_row < m.val
    ) AS all_moves
    GROUP BY next_row, new_col
)

-- output both parts
SELECT 'Part 1' AS part, MAX(total_splits) AS answer FROM beam_sim_p1
UNION ALL
SELECT 'Part 2' AS part, SUM(timeline_count) AS answer FROM beam_sim_p2 b
WHERE b.current_row = (SELECT val FROM max_row);
