-- Day 8: Playground
--
-- Part 1: Connect 1000 closest pairs, multiply 3 largest circuit sizes.
-- Part 2: Connect until one circuit, multiply X coords of last pair.
--
-- Part 1 uses Union-Find simulation (limited to 1000 steps).
-- Part 2 uses Prim's MST algorithm (only n-1 iterations needed).

WITH RECURSIVE

-- parse coordinates
points AS (
    SELECT
        line_num AS id,
        SPLIT_PART(line, ',', 1)::INT AS x,
        SPLIT_PART(line, ',', 2)::INT AS y,
        SPLIT_PART(line, ',', 3)::INT AS z
    FROM day8_input
    WHERE line != ''
),

num_points AS (SELECT COUNT(*)::INT AS n FROM points),

-- all pairwise distances
pairs AS (
    SELECT
        p1.id AS i, p2.id AS j,
        p1.x AS xi, p2.x AS xj,
        ((p1.x - p2.x)::BIGINT * (p1.x - p2.x) +
         (p1.y - p2.y)::BIGINT * (p1.y - p2.y) +
         (p1.z - p2.z)::BIGINT * (p1.z - p2.z)) AS dist_sq
    FROM points p1
    JOIN points p2 ON p1.id < p2.id
),

-- Part 1: first 1000 pairs for Union-Find
ranked_pairs_p1 AS (
    SELECT i, j, ROW_NUMBER() OVER (ORDER BY dist_sq, i, j) AS rn
    FROM pairs
),

top_pairs AS (
    SELECT i, j, rn FROM ranked_pairs_p1 WHERE rn <= 1000
),

union_find AS (
    SELECT
        0 AS step,
        ARRAY_AGG(id ORDER BY id) AS comp
    FROM points

    UNION ALL

    SELECT
        uf.step + 1,
        (
            SELECT ARRAY_AGG(
                CASE WHEN c = comp_j THEN comp_i ELSE c END
                ORDER BY idx
            )
            FROM unnest(uf.comp) WITH ORDINALITY AS t(c, idx)
            CROSS JOIN (
                SELECT uf.comp[tp.i] AS comp_i, uf.comp[tp.j] AS comp_j
                FROM top_pairs tp WHERE tp.rn = uf.step + 1
            ) AS pair_comps
        )
    FROM union_find uf
    WHERE uf.step < 1000
),

part1_state AS (SELECT comp FROM union_find WHERE step = 1000),

part1_sizes AS (
    SELECT c, COUNT(*) AS size
    FROM part1_state, unnest(comp) AS c
    GROUP BY c
),

part1_top3 AS (SELECT size FROM part1_sizes ORDER BY size DESC LIMIT 3),

-- Part 2: Prim's algorithm - much faster, only n-1 iterations
-- Start from node 1, greedily add closest edge to non-tree node
prim AS (
    SELECT
        1 AS tree_size,
        ARRAY[1::INT] AS in_tree,
        0 AS last_xi,
        0 AS last_xj

    UNION ALL

    SELECT
        p.tree_size + 1,
        p.in_tree || best.new_node,
        best.xi,
        best.xj
    FROM prim p
    CROSS JOIN LATERAL (
        SELECT
            CASE WHEN pr.i = ANY(p.in_tree) THEN pr.j ELSE pr.i END AS new_node,
            CASE WHEN pr.i = ANY(p.in_tree) THEN pr.xj ELSE pr.xi END AS xi,
            CASE WHEN pr.i = ANY(p.in_tree) THEN pr.xi ELSE pr.xj END AS xj
        FROM pairs pr
        WHERE (pr.i = ANY(p.in_tree) AND NOT pr.j = ANY(p.in_tree))
           OR (NOT pr.i = ANY(p.in_tree) AND pr.j = ANY(p.in_tree))
        ORDER BY pr.dist_sq
        LIMIT 1
    ) AS best
    WHERE p.tree_size < (SELECT n FROM num_points)
)

SELECT 'Part 1' AS part,
       (SELECT size FROM part1_top3 OFFSET 0 LIMIT 1) *
       (SELECT size FROM part1_top3 OFFSET 1 LIMIT 1) *
       (SELECT size FROM part1_top3 OFFSET 2 LIMIT 1) AS answer
UNION ALL
SELECT 'Part 2' AS part,
       (SELECT last_xi::BIGINT * last_xj FROM prim
        WHERE tree_size = (SELECT n FROM num_points)) AS answer;
