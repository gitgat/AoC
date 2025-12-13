#!/usr/bin/env python3
"""
Day 11: Reactor

Part 1: Count all paths from 'you' to 'out' in a directed graph.
Part 2: Count paths from 'svr' to 'out' that visit both 'dac' and 'fft'.
"""

from collections import defaultdict
from functools import lru_cache


def parse_input(input_path):
    """Parse input into a graph (adjacency list)."""
    graph = defaultdict(list)

    with open(input_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            # Format: "node: neighbor1 neighbor2 ..."
            parts = line.split(': ')
            node = parts[0]
            neighbors = parts[1].split() if len(parts) > 1 else []
            graph[node] = neighbors

    return graph


def count_paths(graph, start, end):
    """Count all paths from start to end using memoized DFS."""
    memo = {}

    def dfs(node):
        if node == end:
            return 1

        if node in memo:
            return memo[node]

        if node not in graph:
            return 0

        total = 0
        for neighbor in graph[node]:
            total += dfs(neighbor)

        memo[node] = total
        return total

    return dfs(start)


def solve(input_path):
    graph = parse_input(input_path)

    part1 = count_paths(graph, 'you', 'out')

    # Part 2: paths from svr to out visiting both dac and fft
    # Two cases:
    # 1. svr -> dac -> fft -> out
    # 2. svr -> fft -> dac -> out

    svr_to_dac = count_paths(graph, 'svr', 'dac')
    dac_to_fft = count_paths(graph, 'dac', 'fft')
    fft_to_out = count_paths(graph, 'fft', 'out')

    svr_to_fft = count_paths(graph, 'svr', 'fft')
    fft_to_dac = count_paths(graph, 'fft', 'dac')
    dac_to_out = count_paths(graph, 'dac', 'out')

    part2 = (svr_to_dac * dac_to_fft * fft_to_out +
             svr_to_fft * fft_to_dac * dac_to_out)

    return part1, part2


if __name__ == "__main__":
    p1, p2 = solve("input")
    print(f"Part 1: {p1}")
    print(f"Part 2: {p2}")
