-- Day 1: Secret Entrance
--
-- We have a safe dial that goes 0 to 99 in a circle. Starts pointing at 50.
-- Input is a list of rotations like R21 (right 21 clicks) or L37 (left 37).
--
-- Part 1: How many times does the dial land exactly on 0 after a rotation?
-- Part 2: How many times does the dial pass through 0 during ANY rotation?
--         (a big rotation like R1000 could cross 0 multiple times)

WITH RECURSIVE

-- first parse out the direction and distance from each line
parsed AS (
    SELECT
        line_num,
        SUBSTRING(line, 1, 1) AS direction,
        CAST(SUBSTRING(line, 2) AS INTEGER) AS distance
    FROM day1_input
),

-- now we walk through each rotation, tracking where we end up
-- and counting how many times we cross zero along the way
positions AS (
    -- start with the first rotation from position 50
    SELECT
        line_num,
        direction,
        distance,
        -- figure out where we land after this rotation
        -- right adds, left subtracts, mod 100 to wrap around
        CASE
            WHEN direction = 'R' THEN (50 + distance) % 100
            ELSE ((50 - distance) % 100 + 100) % 100
        END AS pos,
        -- for part 2: count how many times we hit zero during this rotation
        -- if going right from position P by distance D:
        --   we first hit 0 after (100 - P) steps, then every 100 after that
        -- if going left from position P by distance D:
        --   we first hit 0 after P steps, then every 100 after that
        CASE
            WHEN direction = 'R' THEN
                CASE
                    WHEN 50 = 0 THEN distance / 100
                    WHEN distance >= (100 - 50) THEN (distance - (100 - 50)) / 100 + 1
                    ELSE 0
                END
            ELSE
                CASE
                    WHEN 50 = 0 THEN distance / 100
                    WHEN distance >= 50 THEN (distance - 50) / 100 + 1
                    ELSE 0
                END
        END AS zero_crossings
    FROM parsed
    WHERE line_num = 1

    UNION ALL

    -- each subsequent rotation starts from where the previous one ended
    SELECT
        p.line_num,
        p.direction,
        p.distance,
        CASE
            WHEN p.direction = 'R' THEN (prev.pos + p.distance) % 100
            ELSE ((prev.pos - p.distance) % 100 + 100) % 100
        END AS pos,
        CASE
            WHEN p.direction = 'R' THEN
                CASE
                    WHEN prev.pos = 0 THEN p.distance / 100
                    WHEN p.distance >= (100 - prev.pos) THEN (p.distance - (100 - prev.pos)) / 100 + 1
                    ELSE 0
                END
            ELSE
                CASE
                    WHEN prev.pos = 0 THEN p.distance / 100
                    WHEN p.distance >= prev.pos THEN (p.distance - prev.pos) / 100 + 1
                    ELSE 0
                END
        END AS zero_crossings
    FROM parsed p
    JOIN positions prev ON p.line_num = prev.line_num + 1
)

SELECT 'Part 1' AS part, COUNT(*) FILTER (WHERE pos = 0) AS answer FROM positions
UNION ALL
SELECT 'Part 2' AS part, SUM(zero_crossings) AS answer FROM positions;
