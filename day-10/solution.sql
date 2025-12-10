-- Day 10: Factory
--
-- Find minimum button presses to configure indicator lights.
-- Each button toggles specific lights (XOR). Pressing twice = not pressing.
-- Find minimum subset of buttons that XORs to target state.

-- Helper function: count set bits (popcount)
CREATE OR REPLACE FUNCTION popcount(n BIGINT) RETURNS INT AS $$
DECLARE
    count INT := 0;
    val BIGINT := n;
BEGIN
    WHILE val > 0 LOOP
        count := count + (val & 1)::INT;
        val := val >> 1;
    END LOOP;
    RETURN count;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

WITH

-- Parse each line into machine_id, target pattern, and raw button data
parsed AS (
    SELECT
        line_num AS machine_id,
        (regexp_match(line, '\[([.#]+)\]'))[1] AS target,
        line
    FROM day10_input
    WHERE line != ''
),

-- Extract target as bitmask
targets AS (
    SELECT
        machine_id,
        target,
        LENGTH(target) AS n_lights,
        -- Convert target to bitmask: # at position i means bit i is set
        (SELECT COALESCE(SUM((1::BIGINT << pos)), 0)
         FROM generate_series(0, LENGTH(target)-1) AS pos
         WHERE SUBSTRING(target FROM pos+1 FOR 1) = '#') AS target_bits
    FROM parsed
),

-- Extract buttons using WITH ORDINALITY for proper ordering
button_strings AS (
    SELECT
        p.machine_id,
        m.btn_arr[1] AS btn_str,
        m.ord AS btn_idx
    FROM parsed p
    CROSS JOIN LATERAL regexp_matches(p.line, '\(([0-9,]+)\)', 'g') WITH ORDINALITY AS m(btn_arr, ord)
),

-- Convert button strings to bitmasks
buttons AS (
    SELECT
        machine_id,
        btn_idx,
        -- Convert comma-separated positions to bitmask using XOR fold
        (SELECT COALESCE(SUM((1::BIGINT << pos::INT)), 0)
         FROM unnest(string_to_array(btn_str, ',')) AS pos) AS btn_mask
    FROM button_strings
),

-- Get button count per machine
button_counts AS (
    SELECT machine_id, MAX(btn_idx)::INT AS n_buttons
    FROM buttons
    GROUP BY machine_id
),

-- Aggregate buttons into arrays for each machine
machine_buttons AS (
    SELECT
        machine_id,
        ARRAY_AGG(btn_mask ORDER BY btn_idx) AS btn_masks
    FROM buttons
    GROUP BY machine_id
),

-- Combine machine data
machines AS (
    SELECT
        t.machine_id,
        t.target_bits,
        bc.n_buttons,
        mb.btn_masks
    FROM targets t
    JOIN button_counts bc ON t.machine_id = bc.machine_id
    JOIN machine_buttons mb ON t.machine_id = mb.machine_id
),

-- Generate numbers 0 to 2^13-1 (max buttons seen is ~13)
numbers AS (
    SELECT generate_series(0, 8191) AS n
),

-- For each machine and each subset, calculate XOR result
-- Use # operator for XOR in PostgreSQL
all_subsets AS (
    SELECT
        m.machine_id,
        m.target_bits,
        m.n_buttons,
        m.btn_masks,
        n.n AS subset_mask,
        popcount(n.n::BIGINT) AS subset_size,
        -- Calculate XOR by selecting buttons where bit is set in subset_mask
        (SELECT COALESCE(
            (SELECT x FROM (
                SELECT BIT_XOR(m.btn_masks[i]::BIGINT) AS x
                FROM generate_series(1, m.n_buttons) AS i
                WHERE (n.n::BIGINT & (1::BIGINT << (i-1))) != 0
            ) t),
            0::BIGINT)
        ) AS xor_result
    FROM machines m
    CROSS JOIN numbers n
    WHERE n.n < (1 << m.n_buttons)
),

-- Find minimum subset size that achieves target for each machine
min_presses AS (
    SELECT
        machine_id,
        MIN(subset_size) AS min_presses
    FROM all_subsets
    WHERE xor_result = target_bits
    GROUP BY machine_id
)

SELECT 'Part 1' AS part, SUM(min_presses) AS answer
FROM min_presses;
