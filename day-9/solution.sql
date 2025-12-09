-- Day 9: Movie Theater
--
-- Part 1: Find largest rectangle using two red tiles as opposite corners.
-- Part 2: Rectangle must be entirely within the polygon (red+green tiles).

WITH RECURSIVE

-- Parse red tile coordinates (vertices of polygon)
vertices AS (
    SELECT
        line_num AS id,
        SPLIT_PART(line, ',', 1)::BIGINT AS x,
        SPLIT_PART(line, ',', 2)::BIGINT AS y
    FROM day9_input
    WHERE line != ''
),

n_vertices AS (SELECT COUNT(*) AS n FROM vertices),

-- Build edges: connect consecutive vertices (wrapping around)
edges AS (
    SELECT
        v1.id AS edge_id,
        v1.x AS x1, v1.y AS y1,
        v2.x AS x2, v2.y AS y2,
        CASE WHEN v1.y = v2.y THEN 'H' ELSE 'V' END AS edge_type
    FROM vertices v1
    JOIN vertices v2 ON v2.id = CASE
        WHEN v1.id = (SELECT n FROM n_vertices) THEN 1
        ELSE v1.id + 1
    END
),

-- Vertical edges for ray casting (x, y_min, y_max)
vert_edges AS (
    SELECT x1 AS x,
           LEAST(y1, y2) AS y_min,
           GREATEST(y1, y2) AS y_max
    FROM edges
    WHERE edge_type = 'V'
),

-- Horizontal edges for boundary check (y, x_min, x_max)
horiz_edges AS (
    SELECT y1 AS y,
           LEAST(x1, x2) AS x_min,
           GREATEST(x1, x2) AS x_max
    FROM edges
    WHERE edge_type = 'H'
),

-- Critical coordinates
critical_x AS (SELECT DISTINCT x FROM vertices),
critical_y AS (SELECT DISTINCT y FROM vertices),

-- All critical points
critical_points AS (
    SELECT cx.x, cy.y
    FROM critical_x cx
    CROSS JOIN critical_y cy
),

-- Check if each critical point is on boundary
on_boundary AS (
    SELECT DISTINCT cp.x, cp.y
    FROM critical_points cp
    WHERE EXISTS (
        SELECT 1 FROM horiz_edges h
        WHERE cp.y = h.y AND cp.x >= h.x_min AND cp.x <= h.x_max
    )
    OR EXISTS (
        SELECT 1 FROM vert_edges v
        WHERE cp.x = v.x AND cp.y >= v.y_min AND cp.y <= v.y_max
    )
),

-- Count ray crossings for each critical point (vertical edges to the right)
ray_crossings AS (
    SELECT cp.x, cp.y,
           COUNT(*) FILTER (WHERE ve.y_min < cp.y AND cp.y <= ve.y_max) AS crossings
    FROM critical_points cp
    LEFT JOIN vert_edges ve ON ve.x > cp.x
    GROUP BY cp.x, cp.y
),

-- Points that are strictly inside (odd crossings)
inside_points AS (
    SELECT x, y
    FROM ray_crossings
    WHERE crossings % 2 = 1
),

-- Valid points: on boundary OR inside
valid_points AS (
    SELECT x, y FROM on_boundary
    UNION
    SELECT x, y FROM inside_points
),

-- All pairs of vertices with their areas
vertex_pairs AS (
    SELECT
        v1.id AS id1, v2.id AS id2,
        v1.x AS x1, v1.y AS y1,
        v2.x AS x2, v2.y AS y2,
        LEAST(v1.x, v2.x) AS x_min,
        GREATEST(v1.x, v2.x) AS x_max,
        LEAST(v1.y, v2.y) AS y_min,
        GREATEST(v1.y, v2.y) AS y_max,
        (ABS(v2.x - v1.x) + 1) * (ABS(v2.y - v1.y) + 1) AS area
    FROM vertices v1
    JOIN vertices v2 ON v1.id < v2.id
),

-- Count critical points in each rectangle
rect_critical_counts AS (
    SELECT
        vp.id1, vp.id2, vp.area,
        COUNT(cp.*) AS total_critical,
        COUNT(valid.*) AS valid_critical
    FROM vertex_pairs vp
    LEFT JOIN critical_points cp ON
        cp.x >= vp.x_min AND cp.x <= vp.x_max AND
        cp.y >= vp.y_min AND cp.y <= vp.y_max
    LEFT JOIN valid_points valid ON
        valid.x = cp.x AND valid.y = cp.y
    GROUP BY vp.id1, vp.id2, vp.area
),

-- Valid rectangles: all critical points inside are valid
valid_rects AS (
    SELECT id1, id2, area
    FROM rect_critical_counts
    WHERE total_critical = valid_critical
),

part1 AS (
    SELECT MAX(area) AS answer
    FROM vertex_pairs
),

part2 AS (
    SELECT MAX(area) AS answer
    FROM valid_rects
)

SELECT 'Part 1' AS part, answer FROM part1
UNION ALL
SELECT 'Part 2' AS part, answer FROM part2;
