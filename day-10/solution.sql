-- ============================================================================
-- Day 10: Factory
-- ============================================================================
--
-- Part 1: Find minimum button presses to configure indicator lights (XOR/toggle).
--         Each button toggles specific lights. Since pressing twice = not pressing,
--         we need to find the minimum-size subset of buttons whose XOR equals target.
--
-- Part 2: Find minimum button presses to reach joltage targets (additive ILP).
--         Each button adds 1 to specific counters. This is an Integer Linear
--         Programming problem: minimize sum(x) subject to A*x = b, x >= 0 integer.
--         Solved via Gaussian elimination to find solution space, then search.
--
-- ============================================================================

-- ============================================================================
-- Helper function: count set bits (popcount)
-- ============================================================================
-- PostgreSQL doesn't have a built-in BIT_COUNT function, so we implement one.
-- This counts the number of 1-bits in a BIGINT, used for counting button presses.
-- ============================================================================
CREATE OR REPLACE FUNCTION popcount(n BIGINT) RETURNS INT AS $$
DECLARE
    count INT := 0;
    val BIGINT := n;
BEGIN
    -- Standard bit-counting loop: check LSB, shift right, repeat
    WHILE val > 0 LOOP
        count := count + (val & 1)::INT;  -- Add 1 if LSB is set
        val := val >> 1;                   -- Shift right to check next bit
    END LOOP;
    RETURN count;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- Part 2: Solve ILP via Gaussian elimination with rational arithmetic
-- ============================================================================
-- This function solves the Integer Linear Programming problem:
--   Minimize: sum(x_i)  (total button presses)
--   Subject to: A*x = b  (each counter reaches its target)
--               x >= 0   (non-negative presses)
--               x integer
--
-- Algorithm:
-- 1. Build augmented matrix [A|b] where A[j][i]=1 if button i affects counter j
-- 2. Use Gaussian elimination to reduce to RREF (Reduced Row Echelon Form)
-- 3. Identify pivot columns (determined variables) and free columns (free variables)
-- 4. Search over all non-negative integer values of free variables
-- 5. For each combination, compute pivot variables and check if valid (integer, non-neg)
-- 6. Return minimum total found
--
-- Rational arithmetic is used throughout to maintain exact precision during
-- row operations. Each value is stored as (numerator, denominator) pair.
-- ============================================================================
CREATE OR REPLACE FUNCTION solve_joltage(
    btn_strings TEXT[],     -- btn_strings[i] = comma-separated positions (0-indexed)
    targets INT[]           -- targets[j] = target value for counter j (1-indexed array)
) RETURNS INT AS $$
DECLARE
    -- Dimensions
    n_counters INT;         -- Number of joltage counters (rows in matrix)
    n_buttons INT;          -- Number of buttons (columns in A matrix)
    n_cols INT;             -- Total columns in augmented matrix [A|b]

    -- Augmented matrix stored as rationals: mat[i][j] = mat_n[i][j] / mat_d[i][j]
    mat_n BIGINT[][];       -- Numerators
    mat_d BIGINT[][];       -- Denominators (always positive after normalization)

    -- Loop indices
    i INT; j INT; k INT; l INT;
    pivot_row INT;

    -- Temporary rational values for row operations
    pn BIGINT; pd BIGINT;   -- Pivot value (numerator/denominator)
    fn BIGINT; fd BIGINT;   -- Factor for elimination
    vn BIGINT; vd BIGINT;   -- Temporary value during computation
    g BIGINT;               -- GCD for fraction reduction

    -- Column classification after RREF
    pivot_cols INT[] := '{}';   -- Columns with leading 1s (determined variables)
    free_cols INT[] := '{}';    -- Other columns (free variables we search over)
    n_pivot INT;
    n_free INT;

    -- Search bounds and state
    max_val INT;                -- Upper bound for free variable search
    best INT := 2147483647;     -- Best (minimum) total found so far
    solution BIGINT[];          -- Current solution vector
    v1 INT; v2 INT; v3 INT; v4 INT;  -- Free variable values (up to 4)
    total INT;                  -- Current solution total
    valid BOOLEAN;              -- Whether current solution is valid
    rhs_n BIGINT; rhs_d BIGINT; -- Right-hand side during back-substitution
    btn_pos INT[];              -- Parsed button positions
BEGIN
    -- Get problem dimensions
    n_counters := array_length(targets, 1);
    n_buttons := array_length(btn_strings, 1);
    n_cols := n_buttons + 1;  -- +1 for the RHS column b

    IF n_counters IS NULL OR n_buttons IS NULL THEN
        RETURN 0;
    END IF;

    -- ========================================================================
    -- Initialize augmented matrix [A|b] with rational numbers
    -- ========================================================================
    -- All values start as 0/1 (zero), will be filled in below
    mat_n := ARRAY_FILL(0::BIGINT, ARRAY[n_counters, n_cols]);
    mat_d := ARRAY_FILL(1::BIGINT, ARRAY[n_counters, n_cols]);

    -- ========================================================================
    -- Fill coefficient matrix A from button strings
    -- ========================================================================
    -- A[j][i] = 1 if button i affects counter j (0-indexed in input)
    -- Button string "0,2,3" means button affects counters 0, 2, and 3
    FOR i IN 1..n_buttons LOOP
        btn_pos := string_to_array(btn_strings[i], ',')::INT[];
        IF btn_pos IS NOT NULL THEN
            FOREACH j IN ARRAY btn_pos LOOP
                IF j >= 0 AND j < n_counters THEN
                    mat_n[j+1][i] := 1;  -- +1 because SQL arrays are 1-indexed
                END IF;
            END LOOP;
        END IF;
    END LOOP;

    -- ========================================================================
    -- Fill RHS column b (target joltage values)
    -- ========================================================================
    FOR j IN 1..n_counters LOOP
        mat_n[j][n_cols] := targets[j];
    END LOOP;

    -- ========================================================================
    -- Gaussian Elimination to Reduced Row Echelon Form (RREF)
    -- ========================================================================
    -- We process each column (button) left to right. For each column:
    -- 1. Find a row with non-zero entry in this column (pivot)
    -- 2. Swap that row to current position
    -- 3. Scale row so pivot becomes 1
    -- 4. Eliminate this column in ALL other rows (both above and below)
    -- Result: Identity matrix in pivot columns, arbitrary values elsewhere
    -- ========================================================================
    k := 1;  -- Current row we're working on
    FOR i IN 1..n_buttons LOOP
        -- Find pivot: first non-zero entry in column i, rows k..n_counters
        pivot_row := NULL;
        FOR j IN k..n_counters LOOP
            IF mat_n[j][i] != 0 THEN
                pivot_row := j;
                EXIT;
            END IF;
        END LOOP;

        -- No pivot in this column = free variable, skip to next column
        IF pivot_row IS NULL THEN
            CONTINUE;
        END IF;

        -- Record this as a pivot column (determined variable)
        pivot_cols := array_append(pivot_cols, i);

        -- Swap pivot row into position k
        IF pivot_row != k THEN
            FOR l IN 1..n_cols LOOP
                vn := mat_n[k][l]; vd := mat_d[k][l];
                mat_n[k][l] := mat_n[pivot_row][l];
                mat_d[k][l] := mat_d[pivot_row][l];
                mat_n[pivot_row][l] := vn;
                mat_d[pivot_row][l] := vd;
            END LOOP;
        END IF;

        -- Scale row k so pivot becomes 1
        -- Division: (n/d) / (pn/pd) = (n*pd) / (d*pn)
        pn := mat_n[k][i]; pd := mat_d[k][i];
        FOR l IN 1..n_cols LOOP
            mat_n[k][l] := mat_n[k][l] * pd;
            mat_d[k][l] := mat_d[k][l] * pn;
            -- Reduce fraction using GCD
            g := gcd(ABS(mat_n[k][l]), ABS(mat_d[k][l]));
            IF g > 1 THEN
                mat_n[k][l] := mat_n[k][l] / g;
                mat_d[k][l] := mat_d[k][l] / g;
            END IF;
            -- Normalize: keep denominator positive
            IF mat_d[k][l] < 0 THEN
                mat_n[k][l] := -mat_n[k][l];
                mat_d[k][l] := -mat_d[k][l];
            END IF;
        END LOOP;

        -- Eliminate column i in ALL other rows (makes it RREF, not just REF)
        FOR j IN 1..n_counters LOOP
            IF j != k AND mat_n[j][i] != 0 THEN
                -- row[j] -= factor * row[k], where factor = mat[j][i]
                fn := mat_n[j][i]; fd := mat_d[j][i];
                FOR l IN 1..n_cols LOOP
                    -- Subtraction of rationals:
                    -- (a/b) - (f/g)*(c/d) = (a*g*d - b*f*c) / (b*g*d)
                    vn := mat_n[j][l] * fd * mat_d[k][l] - mat_d[j][l] * fn * mat_n[k][l];
                    vd := mat_d[j][l] * fd * mat_d[k][l];
                    -- Reduce fraction
                    g := gcd(ABS(vn), ABS(vd));
                    IF g > 1 THEN vn := vn / g; vd := vd / g; END IF;
                    IF vd < 0 THEN vn := -vn; vd := -vd; END IF;
                    mat_n[j][l] := vn;
                    mat_d[j][l] := vd;
                END LOOP;
            END IF;
        END LOOP;

        k := k + 1;
        IF k > n_counters THEN EXIT; END IF;
    END LOOP;

    -- ========================================================================
    -- Identify free columns (variables we can choose freely)
    -- ========================================================================
    -- After RREF, pivot columns have leading 1s and are determined by the
    -- free variables. Free columns can take any value, and we search over them.
    FOR i IN 1..n_buttons LOOP
        IF NOT (i = ANY(pivot_cols)) THEN
            free_cols := array_append(free_cols, i);
        END IF;
    END LOOP;

    n_pivot := COALESCE(array_length(pivot_cols, 1), 0);
    n_free := COALESCE(array_length(free_cols, 1), 0);

    -- Upper bound for free variable search: max target value
    max_val := 0;
    FOR i IN 1..n_counters LOOP
        IF targets[i] > max_val THEN max_val := targets[i]; END IF;
    END LOOP;

    -- ========================================================================
    -- Search over all combinations of free variable values
    -- ========================================================================
    -- For each combination of free variables (v1, v2, v3, v4):
    -- 1. Compute pivot variables using back-substitution from RREF
    -- 2. Check if all values are non-negative integers
    -- 3. Track minimum total found
    --
    -- Uses nested loops instead of recursion (PL/pgSQL limitation)
    -- Supports up to 4 free variables (sufficient for this puzzle)
    -- ========================================================================
    FOR v1 IN 0..CASE WHEN n_free >= 1 THEN max_val ELSE 0 END LOOP
        FOR v2 IN 0..CASE WHEN n_free >= 2 THEN max_val ELSE 0 END LOOP
            FOR v3 IN 0..CASE WHEN n_free >= 3 THEN max_val ELSE 0 END LOOP
                FOR v4 IN 0..CASE WHEN n_free >= 4 THEN max_val ELSE 0 END LOOP
                    -- Early termination: if free vars alone exceed best, prune
                    total := v1 + v2 + v3 + v4;
                    IF total >= best THEN
                        IF n_free >= 4 THEN EXIT; END IF;
                        IF n_free >= 3 THEN EXIT; END IF;
                        IF n_free >= 2 THEN EXIT; END IF;
                        EXIT;
                    END IF;

                    -- Initialize solution vector with free variable values
                    solution := ARRAY_FILL(0::BIGINT, ARRAY[n_buttons]);
                    IF n_free >= 1 THEN solution[free_cols[1]] := v1; END IF;
                    IF n_free >= 2 THEN solution[free_cols[2]] := v2; END IF;
                    IF n_free >= 3 THEN solution[free_cols[3]] := v3; END IF;
                    IF n_free >= 4 THEN solution[free_cols[4]] := v4; END IF;

                    -- Compute pivot variables via back-substitution
                    -- From RREF row i: x[pivot_cols[i]] = b[i] - sum(coef[j] * x[free_cols[j]])
                    valid := TRUE;
                    FOR i IN 1..n_pivot LOOP
                        -- Start with RHS value from augmented matrix
                        rhs_n := mat_n[i][n_cols];
                        rhs_d := mat_d[i][n_cols];

                        -- Subtract contribution from each free variable
                        FOR j IN 1..n_free LOOP
                            fn := mat_n[i][free_cols[j]];
                            fd := mat_d[i][free_cols[j]];
                            vn := CASE j WHEN 1 THEN v1 WHEN 2 THEN v2 WHEN 3 THEN v3 ELSE v4 END;
                            -- Rational subtraction: rhs -= (fn/fd) * vn
                            rhs_n := rhs_n * fd - fn * vn * rhs_d;
                            rhs_d := rhs_d * fd;
                            -- Reduce fraction
                            g := gcd(ABS(rhs_n), ABS(rhs_d));
                            IF g > 1 THEN rhs_n := rhs_n / g; rhs_d := rhs_d / g; END IF;
                        END LOOP;

                        -- Normalize and check validity
                        IF rhs_d < 0 THEN rhs_n := -rhs_n; rhs_d := -rhs_d; END IF;

                        -- Must be non-negative integer: rhs_n >= 0 and rhs_n % rhs_d = 0
                        IF rhs_n < 0 OR rhs_n % rhs_d != 0 THEN
                            valid := FALSE;
                            EXIT;
                        END IF;

                        solution[pivot_cols[i]] := rhs_n / rhs_d;
                        total := total + solution[pivot_cols[i]]::INT;

                        -- Prune if we've already exceeded best
                        IF total >= best THEN valid := FALSE; EXIT; END IF;
                    END LOOP;

                    -- Update best if this is a valid, better solution
                    IF valid AND total < best THEN
                        best := total;
                    END IF;

                    -- Break out of unused inner loops
                    IF n_free < 4 THEN EXIT; END IF;
                END LOOP;
                IF n_free < 3 THEN EXIT; END IF;
            END LOOP;
            IF n_free < 2 THEN EXIT; END IF;
        END LOOP;
        IF n_free < 1 THEN EXIT; END IF;
    END LOOP;

    -- Return result (0 if no solution found)
    IF best = 2147483647 THEN RETURN 0; END IF;
    RETURN best;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Main Query: Solve both parts using CTEs
-- ============================================================================

WITH

-- ============================================================================
-- Step 1: Parse each input line
-- ============================================================================
-- Input format: [.##.] (0,1) (2,3) {5,10}
--   - [.##.] = target indicator light pattern
--   - (0,1) = button that affects lights 0 and 1
--   - {5,10} = joltage targets for part 2
parsed AS (
    SELECT
        line_num AS machine_id,
        (regexp_match(line, '\[([.#]+)\]'))[1] AS target,  -- Extract pattern in brackets
        line
    FROM day10_input
    WHERE line != ''
),

-- ============================================================================
-- Step 2: Convert target pattern to bitmask for Part 1
-- ============================================================================
-- Example: ".##." -> binary 0110 -> decimal 6
-- Position 0 is leftmost character, bit 0 is LSB
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

-- ============================================================================
-- Step 3: Extract button definitions as strings
-- ============================================================================
-- Uses WITH ORDINALITY to preserve button order (important for indexing)
-- Each button is a comma-separated list of positions it affects
button_strings AS (
    SELECT
        p.machine_id,
        m.btn_arr[1] AS btn_str,      -- The button string e.g. "0,2,3"
        m.ord AS btn_idx              -- Button index (1-based)
    FROM parsed p
    CROSS JOIN LATERAL regexp_matches(p.line, '\(([0-9,]+)\)', 'g') WITH ORDINALITY AS m(btn_arr, ord)
),

-- ============================================================================
-- Step 4: Convert button strings to bitmasks for Part 1
-- ============================================================================
-- Example: "0,2" -> bits 0 and 2 set -> binary 101 -> decimal 5
buttons AS (
    SELECT
        machine_id,
        btn_idx,
        -- Convert comma-separated positions to bitmask
        (SELECT COALESCE(SUM((1::BIGINT << pos::INT)), 0)
         FROM unnest(string_to_array(btn_str, ',')) AS pos) AS btn_mask
    FROM button_strings
),

-- ============================================================================
-- Step 5: Count buttons per machine
-- ============================================================================
button_counts AS (
    SELECT machine_id, MAX(btn_idx)::INT AS n_buttons
    FROM buttons
    GROUP BY machine_id
),

-- ============================================================================
-- Step 6: Aggregate button masks into arrays
-- ============================================================================
-- Each machine gets an array of its button bitmasks for efficient subset XOR
machine_buttons AS (
    SELECT
        machine_id,
        ARRAY_AGG(btn_mask ORDER BY btn_idx) AS btn_masks
    FROM buttons
    GROUP BY machine_id
),

-- ============================================================================
-- Step 7: Combine all machine data for Part 1
-- ============================================================================
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

-- ============================================================================
-- Step 8: Generate all possible subset masks (0 to 2^13-1)
-- ============================================================================
-- Maximum buttons observed is ~13, so 8191 = 2^13-1 covers all cases
-- Each number n represents a subset: bit i set means button i is included
numbers AS (
    SELECT generate_series(0, 8191) AS n
),

-- ============================================================================
-- Step 9: For each machine and subset, compute XOR of selected buttons
-- ============================================================================
-- This is the core Part 1 computation:
-- - subset_mask encodes which buttons to press (each bit = one button)
-- - XOR all selected button masks together
-- - popcount gives number of button presses
all_subsets AS (
    SELECT
        m.machine_id,
        m.target_bits,
        m.n_buttons,
        m.btn_masks,
        n.n AS subset_mask,
        popcount(n.n::BIGINT) AS subset_size,  -- Number of buttons in this subset
        -- Calculate XOR of all buttons where corresponding bit in subset_mask is set
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
    WHERE n.n < (1 << m.n_buttons)  -- Only valid subsets for this machine
),

-- ============================================================================
-- Step 10: Find minimum subset size achieving target for each machine (Part 1)
-- ============================================================================
min_presses AS (
    SELECT
        machine_id,
        MIN(subset_size) AS min_presses
    FROM all_subsets
    WHERE xor_result = target_bits  -- Subset XOR matches target
    GROUP BY machine_id
),

-- ============================================================================
-- Part 2: Parse joltage targets from {curly braces}
-- ============================================================================
-- Example: {5,10,3} means counter 0 should reach 5, counter 1 reach 10, etc.
joltage_parsed AS (
    SELECT
        p.machine_id,
        ARRAY_AGG(j.val::INT ORDER BY j.ord) AS targets
    FROM parsed p
    CROSS JOIN LATERAL unnest(string_to_array(
        (regexp_match(p.line, '\{([0-9,]+)\}'))[1], ','
    )) WITH ORDINALITY AS j(val, ord)
    GROUP BY p.machine_id
),

-- ============================================================================
-- Aggregate button strings for Part 2
-- ============================================================================
-- We pass TEXT[] (not INT[][]) to solve_joltage because PostgreSQL
-- cannot aggregate arrays of different sizes into a 2D array
buttons_text AS (
    SELECT
        bs.machine_id,
        ARRAY_AGG(bs.btn_str ORDER BY bs.btn_idx) AS btn_strs
    FROM button_strings bs
    GROUP BY bs.machine_id
),

-- ============================================================================
-- Part 2 results: Call solve_joltage for each machine
-- ============================================================================
-- This invokes the Gaussian elimination ILP solver for each machine
part2_results AS (
    SELECT
        j.machine_id,
        solve_joltage(bt.btn_strs, j.targets) AS presses
    FROM joltage_parsed j
    JOIN buttons_text bt ON j.machine_id = bt.machine_id
),

-- ============================================================================
-- Final aggregation: Sum of minimum presses across all machines
-- ============================================================================
part1 AS (
    SELECT SUM(min_presses) AS answer FROM min_presses
),

part2 AS (
    SELECT SUM(presses) AS answer FROM part2_results
)

-- ============================================================================
-- Output both answers
-- ============================================================================
SELECT 'Part 1' AS part, answer FROM part1
UNION ALL
SELECT 'Part 2' AS part, answer FROM part2;
