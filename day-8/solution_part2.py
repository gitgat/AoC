#!/usr/bin/env python3
"""
Day 8: Playground - Part 2

Continue connecting until all junction boxes are in one circuit.
Return product of X coordinates of the last pair connected.
"""

from itertools import combinations

def solve(input_path):
    with open(input_path) as f:
        lines = f.read().strip().split('\n')

    # Parse coordinates
    points = []
    for line in lines:
        if line:
            x, y, z = map(int, line.split(','))
            points.append((x, y, z))

    n = len(points)

    # Calculate all pairwise distances
    pairs = []
    for i, j in combinations(range(n), 2):
        p1, p2 = points[i], points[j]
        dist_sq = (p1[0]-p2[0])**2 + (p1[1]-p2[1])**2 + (p1[2]-p2[2])**2
        pairs.append((dist_sq, i, j))

    # Sort by distance
    pairs.sort()

    # Union-Find
    parent = list(range(n))
    rank = [0] * n

    def find(x):
        if parent[x] != x:
            parent[x] = find(parent[x])
        return parent[x]

    def union(x, y):
        px, py = find(x), find(y)
        if px == py:
            return False  # Already connected
        if rank[px] < rank[py]:
            px, py = py, px
        parent[py] = px
        if rank[px] == rank[py]:
            rank[px] += 1
        return True

    # Connect pairs until all in one circuit (n-1 successful unions needed)
    unions_done = 0
    last_pair = None

    for dist_sq, i, j in pairs:
        if union(i, j):
            unions_done += 1
            last_pair = (i, j)
            if unions_done == n - 1:
                break

    # Return product of X coordinates
    i, j = last_pair
    return points[i][0] * points[j][0]

if __name__ == "__main__":
    print(solve("input"))
