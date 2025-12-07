-- Day 2: Gift Shop
--
-- The elves have product ID ranges and need to find "invalid" IDs.
-- An ID is invalid if its a pattern repeated: 55, 1212, 123123, etc.
--
-- Part 1: Find IDs where the pattern repeats exactly twice (like 1212)
-- Part 2: Find IDs where the pattern repeats 2 or more times (like 121212)
--
-- The trick is we dont iterate through billions of numbers.
-- Instead we generate the valid "doubled" numbers directly and check if theyre in range.
-- For a pattern like 12, the doubled version is 12 * 101 = 1212
-- For a pattern like 123, the doubled version is 123 * 1001 = 123123

WITH

-- parse the comma separated ranges from the input
-- input looks like: 100-200,5000-6000,etc
raw_ranges AS (
    SELECT UNNEST(STRING_TO_ARRAY(line, ',')) AS range_str
    FROM day2_input
    WHERE line IS NOT NULL AND line != ''
),

ranges AS (
    SELECT
        CAST(SPLIT_PART(range_str, '-', 1) AS BIGINT) AS range_start,
        CAST(SPLIT_PART(range_str, '-', 2) AS BIGINT) AS range_end
    FROM raw_ranges
    WHERE range_str LIKE '%-%'
),

-- figure out how many digits were dealing with at most
max_info AS (
    SELECT MAX(LENGTH(range_end::TEXT)) AS max_digits FROM ranges
),

-- Part 1: generate all possible "doubled" patterns
-- a doubled pattern of length D is: base * (10^D + 1)
-- example: 12 (D=2) becomes 12 * 101 = 1212
doubled_patterns AS (
    SELECT DISTINCT num
    FROM (
        SELECT
            base * (POWER(10, LENGTH(base::TEXT))::BIGINT + 1) AS num
        FROM generate_series(1, 9999999) AS base
        CROSS JOIN max_info
        WHERE LENGTH(base::TEXT) * 2 <= max_digits
    ) sub
    WHERE EXISTS (
        SELECT 1 FROM ranges r
        WHERE sub.num BETWEEN r.range_start AND r.range_end
    )
),

-- Part 2: patterns repeated 2 or more times
-- for a pattern repeated N times, the multiplier is (10^(N*D) - 1) / (10^D - 1)
-- example: 12 repeated 3 times = 12 * (10^6 - 1) / (10^2 - 1) = 12 * 10101 = 121212
repeated_patterns AS (
    SELECT DISTINCT num
    FROM (
        SELECT
            base * ((POWER(10, LENGTH(base::TEXT) * reps)::BIGINT - 1) /
                    (POWER(10, LENGTH(base::TEXT))::BIGINT - 1)) AS num,
            LENGTH(base::TEXT) * reps AS total_len
        FROM generate_series(1, 9999999) AS base
        CROSS JOIN generate_series(2, 16) AS reps
        CROSS JOIN max_info
        WHERE LENGTH(base::TEXT) * reps <= max_digits
          AND LENGTH(base::TEXT) >= 1
    ) sub
    WHERE EXISTS (
        SELECT 1 FROM ranges r
        WHERE sub.num BETWEEN r.range_start AND r.range_end
    )
)

SELECT 'Part 1' AS part, SUM(num) AS answer FROM doubled_patterns
UNION ALL
SELECT 'Part 2' AS part, SUM(num) AS answer FROM repeated_patterns;
