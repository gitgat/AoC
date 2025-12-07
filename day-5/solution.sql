-- Day 5: Cafeteria
--
-- The kitchen has a database of fresh ingredient ID ranges.
-- Input has two sections separated by a blank line:
--   1. Fresh ranges (like 100-200, meaning IDs 100 through 200 are fresh)
--   2. Available ingredient IDs to check
--
-- Part 1: How many of the available IDs are fresh (fall in any range)?
-- Part 2: How many unique IDs total are covered by all the ranges?
--         Ranges can overlap, so we need to merge them first.

WITH

-- find where the blank line is (separates ranges from IDs)
blank_line AS (
    SELECT MIN(line_num) AS line_num
    FROM day5_input
    WHERE TRIM(line) = ''
),

-- parse the ranges section (everything before the blank line)
ranges AS (
    SELECT
        CAST(SPLIT_PART(line, '-', 1) AS BIGINT) AS range_start,
        CAST(SPLIT_PART(line, '-', 2) AS BIGINT) AS range_end
    FROM day5_input, blank_line
    WHERE day5_input.line_num < blank_line.line_num
      AND line LIKE '%-%'
),

-- parse the ingredient IDs (everything after the blank line)
ingredient_ids AS (
    SELECT CAST(line AS BIGINT) AS id
    FROM day5_input, blank_line
    WHERE day5_input.line_num > blank_line.line_num
      AND TRIM(line) != ''
      AND line ~ '^[0-9]+$'
),

-- Part 1: count IDs that fall within any range
part1_result AS (
    SELECT COUNT(*) AS answer
    FROM ingredient_ids i
    WHERE EXISTS (
        SELECT 1 FROM ranges r
        WHERE i.id BETWEEN r.range_start AND r.range_end
    )
),

-- Part 2: merge overlapping ranges and count total coverage
-- first sort by start position
sorted_ranges AS (
    SELECT
        range_start,
        range_end,
        ROW_NUMBER() OVER (ORDER BY range_start, range_end) AS rn
    FROM ranges
),

-- track the running max of range_end as we go through sorted ranges
-- this helps us detect when theres a gap (new island starts)
with_running_max AS (
    SELECT
        range_start,
        range_end,
        rn,
        MAX(range_end) OVER (ORDER BY rn ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prev_max_end
    FROM sorted_ranges
),

-- mark where new "islands" start
-- an island is a group of overlapping/adjacent ranges
-- a new island starts when the current start is beyond the previous max end + 1
with_island_markers AS (
    SELECT
        range_start,
        range_end,
        CASE
            WHEN prev_max_end IS NULL THEN 1
            WHEN range_start > prev_max_end + 1 THEN 1
            ELSE 0
        END AS new_island
    FROM with_running_max
),

-- assign island IDs using running sum of the markers
with_island_ids AS (
    SELECT
        range_start,
        range_end,
        SUM(new_island) OVER (ORDER BY range_start, range_end) AS island_id
    FROM with_island_markers
),

-- merge each island into a single range
merged_ranges AS (
    SELECT
        island_id,
        MIN(range_start) AS merged_start,
        MAX(range_end) AS merged_end
    FROM with_island_ids
    GROUP BY island_id
),

-- count how many IDs are covered by all merged ranges
part2_result AS (
    SELECT SUM(merged_end - merged_start + 1) AS answer
    FROM merged_ranges
)

SELECT 'Part 1' AS part, answer FROM part1_result
UNION ALL
SELECT 'Part 2' AS part, answer FROM part2_result;
