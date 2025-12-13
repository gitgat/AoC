#!/usr/bin/env python3
"""
Day 12: Christmas Tree Farm

Part 1: Count how many regions can fit all their required presents (polyominoes).
Uses greedy placement with retry for efficiency on large regions.
"""

import random

def parse_input(input_path):
    """Parse input into shapes and regions."""
    with open(input_path) as f:
        content = f.read()

    parts = content.strip().split('\n\n')

    # Parse shapes
    shapes = []
    for part in parts:
        lines = part.strip().split('\n')
        if ':' in lines[0] and 'x' not in lines[0]:
            shape_lines = lines[1:]
            cells = set()
            for r, line in enumerate(shape_lines):
                for c, ch in enumerate(line):
                    if ch == '#':
                        cells.add((r, c))
            shapes.append(cells)
        else:
            break

    # Find where regions start
    region_start = 0
    for i, part in enumerate(parts):
        lines = part.strip().split('\n')
        if 'x' in lines[0]:
            region_start = i
            break

    # Parse regions
    regions = []
    for part in parts[region_start:]:
        for line in part.strip().split('\n'):
            if 'x' not in line:
                continue
            size_part, counts_part = line.split(': ')
            w, h = map(int, size_part.split('x'))
            counts = list(map(int, counts_part.split()))
            regions.append((w, h, counts))

    return shapes, regions


def get_orientations(shape):
    """Get all unique orientations of a shape."""
    orientations = set()

    def normalize(cells):
        if not cells:
            return frozenset()
        min_r = min(r for r, c in cells)
        min_c = min(c for r, c in cells)
        return frozenset((r - min_r, c - min_c) for r, c in cells)

    def rotate90(cells):
        return {(c, -r) for r, c in cells}

    def flip_h(cells):
        return {(r, -c) for r, c in cells}

    current = shape
    for _ in range(4):
        orientations.add(normalize(current))
        orientations.add(normalize(flip_h(current)))
        current = rotate90(current)

    return [set(o) for o in orientations]


def can_fit_greedy(width, height, counts, shapes, all_orientations, max_retries=10):
    """Try to fit using greedy placement with multiple random orderings."""
    shape_sizes = [len(s) for s in shapes]

    # Build list of pieces
    pieces = []
    total_cells = 0
    for shape_idx, count in enumerate(counts):
        for _ in range(count):
            pieces.append(shape_idx)
        total_cells += count * shape_sizes[shape_idx]

    # Quick area check
    if total_cells > width * height:
        return False

    if not pieces:
        return True

    # Try multiple random orderings
    for attempt in range(max_retries):
        if attempt > 0:
            random.shuffle(pieces)

        grid = [[False] * width for _ in range(height)]

        def find_placement(shape_idx):
            """Find first valid placement for a shape."""
            for orient in all_orientations[shape_idx]:
                max_r = max(r for r, c in orient)
                max_c = max(c for r, c in orient)
                for start_r in range(height - max_r):
                    for start_c in range(width - max_c):
                        valid = True
                        for r, c in orient:
                            if grid[start_r + r][start_c + c]:
                                valid = False
                                break
                        if valid:
                            return orient, start_r, start_c
            return None, None, None

        success = True
        for shape_idx in pieces:
            orient, start_r, start_c = find_placement(shape_idx)
            if orient is None:
                success = False
                break
            for r, c in orient:
                grid[start_r + r][start_c + c] = True

        if success:
            return True

    return False


def solve(input_path):
    shapes, regions = parse_input(input_path)
    all_orientations = [get_orientations(shape) for shape in shapes]

    count = 0
    for i, (w, h, counts) in enumerate(regions):
        if can_fit_greedy(w, h, counts, shapes, all_orientations):
            count += 1
        if (i + 1) % 100 == 0:
            print(f"Processed {i+1}/{len(regions)}, {count} valid...")

    return count


if __name__ == "__main__":
    random.seed(42)
    p1 = solve("input")
    print(f"Part 1: {p1}")
