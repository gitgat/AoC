#!/usr/bin/env python3
"""
Day 9: Movie Theater

Part 1: Find largest rectangle using two red tiles as opposite corners.
Part 2: Rectangle must be entirely within the polygon (red+green tiles only).
"""

from itertools import combinations

def solve_part1(vertices):
    max_area = 0
    for (x1, y1), (x2, y2) in combinations(vertices, 2):
        area = (abs(x2 - x1) + 1) * (abs(y2 - y1) + 1)
        max_area = max(max_area, area)
    return max_area

def solve_part2(vertices):
    n = len(vertices)

    # Build edge data structures for fast lookup
    # Horizontal edges: for boundary checking
    # Vertical edges: for ray casting
    horiz_edges = []  # (y, x_min, x_max)
    vert_edges = []   # (x, y_min, y_max)

    for i in range(n):
        x1, y1 = vertices[i]
        x2, y2 = vertices[(i + 1) % n]
        if y1 == y2:  # horizontal
            horiz_edges.append((y1, min(x1, x2), max(x1, x2)))
        else:  # vertical
            vert_edges.append((x1, min(y1, y2), max(y1, y2)))

    # Sort edges for binary search
    horiz_edges.sort()
    vert_edges.sort()

    # Get critical coordinates
    xs = sorted(set(x for x, y in vertices))
    ys = sorted(set(y for x, y in vertices))

    # Create index maps for binary search
    import bisect

    def is_point_on_boundary(px, py):
        """Check if point is on polygon boundary."""
        # Check horizontal edges at py
        lo = bisect.bisect_left(horiz_edges, (py, -float('inf'), -float('inf')))
        hi = bisect.bisect_right(horiz_edges, (py, float('inf'), float('inf')))
        for i in range(lo, hi):
            y, x_min, x_max = horiz_edges[i]
            if x_min <= px <= x_max:
                return True

        # Check vertical edges at px
        lo = bisect.bisect_left(vert_edges, (px, -float('inf'), -float('inf')))
        hi = bisect.bisect_right(vert_edges, (px, float('inf'), float('inf')))
        for i in range(lo, hi):
            x, y_min, y_max = vert_edges[i]
            if y_min <= py <= y_max:
                return True
        return False

    def is_point_inside(px, py):
        """Check if point is strictly inside polygon using ray casting."""
        # Count vertical edges to the right of px that span py
        crossings = 0
        lo = bisect.bisect_right(vert_edges, (px, float('inf'), float('inf')))
        for i in range(lo, len(vert_edges)):
            x, y_min, y_max = vert_edges[i]
            # Use (y_min, y_max] half-open interval
            if y_min < py <= y_max:
                crossings += 1
        return crossings % 2 == 1

    # Cache for point validity
    point_cache = {}

    def is_point_valid(px, py):
        """Check if point is inside or on boundary."""
        key = (px, py)
        if key not in point_cache:
            point_cache[key] = is_point_on_boundary(px, py) or is_point_inside(px, py)
        return point_cache[key]

    def is_rect_valid(xa, ya, xb, yb):
        """Check if rectangle is entirely within the polygon."""
        x_min, x_max = min(xa, xb), max(xa, xb)
        y_min, y_max = min(ya, yb), max(ya, yb)

        # Get critical points in rectangle using binary search
        x_lo = bisect.bisect_left(xs, x_min)
        x_hi = bisect.bisect_right(xs, x_max)
        y_lo = bisect.bisect_left(ys, y_min)
        y_hi = bisect.bisect_right(ys, y_max)

        # Check all critical points
        for xi in range(x_lo, x_hi):
            for yi in range(y_lo, y_hi):
                if not is_point_valid(xs[xi], ys[yi]):
                    return False
        return True

    # Check all pairs of red tiles, sorted by area descending for better pruning
    pairs = []
    for i in range(n):
        for j in range(i + 1, n):
            xa, ya = vertices[i]
            xb, yb = vertices[j]
            area = (abs(xb - xa) + 1) * (abs(yb - ya) + 1)
            pairs.append((area, i, j))

    pairs.sort(reverse=True)

    max_area = 0
    for area, i, j in pairs:
        if area <= max_area:
            break  # All remaining pairs have smaller or equal area

        xa, ya = vertices[i]
        xb, yb = vertices[j]
        if is_rect_valid(xa, ya, xb, yb):
            max_area = area
            break  # Found the largest valid rectangle

    return max_area

def solve(input_path):
    with open(input_path) as f:
        lines = f.read().strip().split('\n')

    vertices = []
    for line in lines:
        x, y = map(int, line.split(','))
        vertices.append((x, y))

    part1 = solve_part1(vertices)
    part2 = solve_part2(vertices)

    return part1, part2

if __name__ == "__main__":
    p1, p2 = solve("input")
    print(f"Part 1: {p1}")
    print(f"Part 2: {p2}")
