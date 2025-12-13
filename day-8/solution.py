#!/usr/bin/env python3
"""
Day 8: Playground - Junction Boxes

Connect 1000 closest pairs of junction boxes using Union-Find.
Find the product of the 3 largest circuit sizes.
"""

from itertools import combinations
import math

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

    # Union-Find with path compression and union by rank
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

    # Connect 1000 closest pairs
    connections = 0
    for dist_sq, i, j in pairs:
        if connections >= 1000:
            break
        union(i, j)
        connections += 1

    # Count circuit sizes
    sizes = {}
    for i in range(n):
        root = find(i)
        sizes[root] = sizes.get(root, 0) + 1

    # Get top 3 largest
    top3 = sorted(sizes.values(), reverse=True)[:3]
    return top3[0] * top3[1] * top3[2]

if __name__ == "__main__":
    print(solve("input"))
