-- Day 3: Lobby
--
-- We have battery banks where each line is a string of digits (1 to 9).
-- We need to pick digits from each bank to form the largest possible number.
--
-- Part 1: Pick exactly 2 digits (in order) to make the biggest 2 digit number
-- Part 2: Pick exactly 12 digits (in order) to make the biggest 12 digit number
--
-- The key insight for part 2 is greedy selection:
-- For each of the 12 positions, pick the largest digit available
-- while still leaving enough digits for the remaining positions.

WITH RECURSIVE

-- clean up input (some lines have weird escape chars) and get each bank
banks AS (
    SELECT
        line_num AS bank_id,
        REGEXP_REPLACE(line, '[^0-9]', '', 'g') AS bank_str,
        LENGTH(REGEXP_REPLACE(line, '[^0-9]', '', 'g')) AS bank_len
    FROM day3_input
    WHERE LENGTH(REGEXP_REPLACE(line, '[^0-9]', '', 'g')) > 0
),

-- explode each bank into individual digits with their positions
digits AS (
    SELECT
        b.bank_id,
        b.bank_len,
        pos,
        CAST(SUBSTRING(b.bank_str, pos, 1) AS INTEGER) AS digit
    FROM banks b
    CROSS JOIN LATERAL generate_series(1, b.bank_len) AS pos
),

-- Part 1: for each position, whats the max digit that comes after it?
-- then we can form candidates by pairing each digit with the best one after it
part1_suffix_max AS (
    SELECT
        bank_id,
        pos,
        digit,
        MAX(digit) OVER (
            PARTITION BY bank_id
            ORDER BY pos DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS max_after
    FROM digits
),

part1_candidates AS (
    SELECT
        bank_id,
        digit * 10 + max_after AS joltage
    FROM part1_suffix_max
    WHERE max_after IS NOT NULL
),

part1_result AS (
    SELECT SUM(max_joltage) AS answer
    FROM (
        SELECT bank_id, MAX(joltage) AS max_joltage
        FROM part1_candidates
        GROUP BY bank_id
    ) sub
),

-- Part 2: greedy selection, pick 12 digits one at a time
-- at each step, pick the leftmost occurrence of the max digit
-- within the valid window (must leave room for remaining picks)
part2_greedy AS (
    -- first pick: find the best digit in positions 1 to (bank_len - 11)
    -- we need to leave 11 more positions after this one
    SELECT
        bank_id,
        bank_len,
        1 AS iteration,
        selected_pos,
        selected_digit,
        selected_digit::BIGINT AS accumulated
    FROM (
        SELECT DISTINCT ON (bank_id)
            d.bank_id,
            d.bank_len,
            d.pos AS selected_pos,
            d.digit AS selected_digit
        FROM digits d
        WHERE d.pos <= d.bank_len - 11
        ORDER BY d.bank_id, d.digit DESC, d.pos ASC
    ) first_pick

    UNION ALL

    -- subsequent picks: start after the previous selection
    -- and leave enough room for whats left
    SELECT
        next_pick.bank_id,
        next_pick.bank_len,
        prev.iteration + 1,
        next_pick.selected_pos,
        next_pick.selected_digit,
        prev.accumulated * 10 + next_pick.selected_digit
    FROM part2_greedy prev
    CROSS JOIN LATERAL (
        SELECT DISTINCT ON (d.bank_id)
            d.bank_id,
            d.bank_len,
            d.pos AS selected_pos,
            d.digit AS selected_digit
        FROM digits d
        WHERE d.bank_id = prev.bank_id
          AND d.pos > prev.selected_pos
          AND d.pos <= d.bank_len - (12 - prev.iteration - 1)
        ORDER BY d.bank_id, d.digit DESC, d.pos ASC
    ) next_pick
    WHERE prev.iteration < 12
),

part2_result AS (
    SELECT SUM(accumulated) AS answer
    FROM part2_greedy
    WHERE iteration = 12
)

SELECT 'Part 1' AS part, answer FROM part1_result
UNION ALL
SELECT 'Part 2' AS part, answer FROM part2_result;
