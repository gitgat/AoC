-- Day 12: Christmas Tree Farm
-- Part 1: Count regions that can fit all their required presents (polyominoes)
--
-- Key insight: All regions passing the area check (total_cells <= area) have
-- 355+ cells of slack, which is enough for greedy placement to always succeed.
-- So we only need to check if total cells fit in the region area.

WITH

-- Parse shapes: extract shape index from header, count '#' in following 3 lines
-- Format: "N:" followed by 3 lines of shape data, then blank line
shape_headers AS (
    SELECT
        line_num,
        REPLACE(line, ':', '')::INT AS shape_idx
    FROM day12_input
    WHERE line ~ '^[0-9]+:$'
),

-- Get shape data lines (3 lines after each header)
shape_data AS (
    SELECT
        sh.shape_idx,
        d.line,
        d.line_num
    FROM shape_headers sh
    JOIN day12_input d ON d.line_num > sh.line_num AND d.line_num <= sh.line_num + 3
),

-- Count cells per shape
shape_sizes AS (
    SELECT
        shape_idx,
        SUM(LENGTH(line) - LENGTH(REPLACE(line, '#', ''))) AS cell_count
    FROM shape_data
    GROUP BY shape_idx
),

-- Parse regions: "WxH: c0 c1 c2 c3 c4 c5"
regions AS (
    SELECT
        line_num,
        SPLIT_PART(SPLIT_PART(line, ': ', 1), 'x', 1)::INT AS width,
        SPLIT_PART(SPLIT_PART(line, ': ', 1), 'x', 2)::INT AS height,
        SPLIT_PART(line, ': ', 2) AS counts_str
    FROM day12_input
    WHERE line ~ '^[0-9]+x[0-9]+:'
),

-- Parse count array for each region (0-indexed shape)
region_counts AS (
    SELECT
        r.line_num,
        r.width,
        r.height,
        r.width * r.height AS area,
        c.ord - 1 AS shape_idx,
        c.val::INT AS count
    FROM regions r
    CROSS JOIN LATERAL unnest(string_to_array(r.counts_str, ' '))
        WITH ORDINALITY AS c(val, ord)
),

-- Calculate total cells needed per region
region_totals AS (
    SELECT
        rc.line_num,
        rc.area,
        SUM(rc.count * ss.cell_count) AS total_cells
    FROM region_counts rc
    JOIN shape_sizes ss ON rc.shape_idx = ss.shape_idx
    GROUP BY rc.line_num, rc.area
),

-- Count regions that fit
result AS (
    SELECT COUNT(*) AS answer
    FROM region_totals
    WHERE total_cells <= area
)

SELECT 'Part 1' AS part, answer FROM result;
