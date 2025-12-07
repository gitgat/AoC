-- Day 6: Trash Compactor
--
-- We fell into a garbage smasher and a cephalopod family needs help with math homework.
-- The worksheet has math problems arranged in columns, numbers stacked vertically.
--
-- Example:
--   123 328
--    45  64
--     6  98
--   *   +
-- Two problems: 123 * 45 * 6 = 33210 and 328 + 64 + 98 = 490
--
-- Problems are separated by columns of all spaces.
-- We need to parse the grid, solve each problem, and sum all the results.
--
-- Part 1: read numbers horizontally (each row is one number per problem)
-- Part 2: read numbers vertically (each column is one number per problem)
--         cephalopod math! most significant digit at top, read top to bottom

WITH

-- figure out how wide the worksheet is
line_lengths AS (
    SELECT MAX(LENGTH(line)) AS max_len FROM day6_input
),

-- break the worksheet into individual characters at each position
-- pad shorter lines with spaces so we have a proper grid
chars AS (
    SELECT
        line_num AS row,
        col,
        CASE
            WHEN col <= LENGTH(line) THEN SUBSTRING(line, col, 1)
            ELSE ' '
        END AS ch
    FROM day6_input
    CROSS JOIN line_lengths
    CROSS JOIN LATERAL generate_series(1, max_len) AS col
),

-- the operator row is the bottom row (has * and + symbols)
op_row AS (
    SELECT MAX(row) AS row_num
    FROM chars
    WHERE ch IN ('*', '+')
),

-- find which columns have actual content (not all spaces)
-- these are NOT separator columns
non_separator_cols AS (
    SELECT DISTINCT col
    FROM chars, op_row
    WHERE row <= op_row.row_num
      AND ch != ' '
),

-- mark each column: 1 if its a separator (all spaces), 0 otherwise
col_markers AS (
    SELECT
        col,
        CASE WHEN col IN (SELECT col FROM non_separator_cols) THEN 0 ELSE 1 END AS is_sep
    FROM line_lengths
    CROSS JOIN LATERAL generate_series(1, max_len) AS col
),

-- group consecutive content columns into "islands" (problems)
-- each separator column bumps us to a new island
with_islands AS (
    SELECT
        col,
        is_sep,
        SUM(is_sep) OVER (ORDER BY col) AS island_id
    FROM col_markers
),

-- get the column range for each problem
problem_ranges AS (
    SELECT
        island_id,
        MIN(col) AS start_col,
        MAX(col) AS end_col
    FROM with_islands
    WHERE is_sep = 0
    GROUP BY island_id
),

-- pull out the operator (* or +) for each problem from the bottom row
problem_operators AS (
    SELECT
        p.island_id,
        p.start_col,
        p.end_col,
        MAX(c.ch) FILTER (WHERE c.ch IN ('*', '+')) AS op
    FROM problem_ranges p
    JOIN chars c ON c.col BETWEEN p.start_col AND p.end_col
    JOIN op_row ON c.row = op_row.row_num
    GROUP BY p.island_id, p.start_col, p.end_col
),

-- Part 1: extract numbers by reading HORIZONTALLY (each row = one number)
-- concat the chars in that column range, trim whitespace, convert to number
part1_numbers AS (
    SELECT
        p.island_id,
        c.row,
        NULLIF(TRIM(STRING_AGG(c.ch, '' ORDER BY c.col)), '')::BIGINT AS num
    FROM problem_ranges p
    JOIN chars c ON c.col BETWEEN p.start_col AND p.end_col
    JOIN op_row ON c.row < op_row.row_num
    GROUP BY p.island_id, c.row
    HAVING TRIM(STRING_AGG(c.ch, '' ORDER BY c.col)) ~ '^[0-9]+$'
),

-- Part 2: extract numbers by reading VERTICALLY (each column = one number)
-- concat the chars in that row range (top to bottom), trim, convert to number
part2_numbers AS (
    SELECT
        p.island_id,
        c.col,
        NULLIF(TRIM(STRING_AGG(c.ch, '' ORDER BY c.row)), '')::BIGINT AS num
    FROM problem_ranges p
    JOIN chars c ON c.col BETWEEN p.start_col AND p.end_col
    JOIN op_row ON c.row < op_row.row_num
    GROUP BY p.island_id, c.col
    HAVING TRIM(STRING_AGG(c.ch, '' ORDER BY c.row)) ~ '^[0-9]+$'
),

-- calculate each problems result for Part 1
-- for addition: just sum them
-- for multiplication: use the exp/ln trick since postgres doesnt have a product aggregate
part1_results AS (
    SELECT
        o.island_id,
        o.op,
        CASE
            WHEN o.op = '+' THEN SUM(n.num)
            WHEN o.op = '*' THEN EXP(SUM(LN(n.num)))::BIGINT
        END AS result
    FROM problem_operators o
    JOIN part1_numbers n ON n.island_id = o.island_id
    GROUP BY o.island_id, o.op
),

-- calculate each problems result for Part 2 (same logic, different numbers)
part2_results AS (
    SELECT
        o.island_id,
        o.op,
        CASE
            WHEN o.op = '+' THEN SUM(n.num)
            WHEN o.op = '*' THEN EXP(SUM(LN(n.num)))::BIGINT
        END AS result
    FROM problem_operators o
    JOIN part2_numbers n ON n.island_id = o.island_id
    GROUP BY o.island_id, o.op
)

-- add up all the problem answers for both parts
SELECT 'Part 1' AS part, SUM(result) AS answer FROM part1_results
UNION ALL
SELECT 'Part 2' AS part, SUM(result) AS answer FROM part2_results;
