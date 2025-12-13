-- Day 11: Reactor
-- Part 1: Count all paths from 'you' to 'out' in a directed graph
-- Part 2: Count paths from 'svr' to 'out' that visit both 'dac' and 'fft'

-- Create a function to count paths using memoization
-- This version properly handles nodes that don't lead to the target
CREATE OR REPLACE FUNCTION count_paths_day11(start_node TEXT, end_node TEXT) RETURNS BIGINT AS $$
DECLARE
    changed BOOLEAN := TRUE;
    iterations INT := 0;
    result BIGINT;
BEGIN
    -- Create temp table for edges
    DROP TABLE IF EXISTS d11_edges;
    CREATE TEMP TABLE d11_edges AS
    SELECT
        split_part(line, ': ', 1) AS src,
        unnest(string_to_array(split_part(line, ': ', 2), ' ')) AS dst
    FROM day11_input
    WHERE line LIKE '%: %';

    CREATE INDEX ON d11_edges(src);
    CREATE INDEX ON d11_edges(dst);

    -- Create temp table for path counts (memoization)
    -- NULL means not computed yet, 0 means no paths to target
    DROP TABLE IF EXISTS d11_paths;
    CREATE TEMP TABLE d11_paths (
        node TEXT PRIMARY KEY,
        paths BIGINT  -- NULL = not computed, >= 0 = computed
    );

    -- Initialize all nodes with NULL (not computed)
    INSERT INTO d11_paths (node, paths)
    SELECT DISTINCT src, NULL FROM d11_edges
    UNION
    SELECT DISTINCT dst, NULL FROM d11_edges;

    -- Base case: end_node has 1 path to itself
    UPDATE d11_paths SET paths = 1 WHERE node = end_node;

    -- Mark nodes with no outgoing edges (sinks other than end_node) as 0
    UPDATE d11_paths SET paths = 0
    WHERE node != end_node
      AND NOT EXISTS (SELECT 1 FROM d11_edges WHERE src = d11_paths.node);

    -- Iteratively compute path counts
    WHILE changed LOOP
        changed := FALSE;
        iterations := iterations + 1;

        -- Update nodes where ALL children have been computed
        WITH ready_nodes AS (
            SELECT p.node
            FROM d11_paths p
            WHERE p.paths IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM d11_edges e
                  JOIN d11_paths pc ON e.dst = pc.node
                  WHERE e.src = p.node AND pc.paths IS NULL
              )
        ),
        computed AS (
            SELECT e.src AS node, COALESCE(SUM(pc.paths), 0) AS paths
            FROM d11_edges e
            JOIN d11_paths pc ON e.dst = pc.node
            WHERE e.src IN (SELECT node FROM ready_nodes)
            GROUP BY e.src
        )
        UPDATE d11_paths p
        SET paths = c.paths
        FROM computed c
        WHERE p.node = c.node;

        IF FOUND THEN
            changed := TRUE;
        END IF;

        IF iterations > 1000 THEN
            RAISE EXCEPTION 'Too many iterations';
        END IF;
    END LOOP;

    SELECT COALESCE(paths, 0) INTO result FROM d11_paths WHERE node = start_node;
    RETURN COALESCE(result, 0);
END;
$$ LANGUAGE plpgsql;

-- Part 1: paths from 'you' to 'out'
SELECT 'Part 1' AS part, count_paths_day11('you', 'out') AS answer

UNION ALL

-- Part 2: paths from 'svr' to 'out' visiting both 'dac' and 'fft'
-- Two orderings: svr->dac->fft->out OR svr->fft->dac->out
SELECT 'Part 2' AS part,
    count_paths_day11('svr', 'dac') * count_paths_day11('dac', 'fft') * count_paths_day11('fft', 'out') +
    count_paths_day11('svr', 'fft') * count_paths_day11('fft', 'dac') * count_paths_day11('dac', 'out') AS answer;
