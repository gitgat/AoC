#!/usr/bin/env python3
"""
Day 7: Laboratories - Tachyon Manifold

Beam starts at S, moves downward.
When beam hits ^, it splits into two beams going left and right.
Count total number of splits.
"""

def solve(input_path):
    with open(input_path) as f:
        lines = f.read().rstrip('\n').split('\n')

    # Find starting position (S)
    start_col = None
    for row, line in enumerate(lines):
        if 'S' in line:
            start_col = line.index('S')
            start_row = row
            break

    # Track active beam columns as a set (handles merging automatically)
    active_beams = {start_col}
    total_splits = 0

    # Process each row below the start
    for row in range(start_row + 1, len(lines)):
        line = lines[row]
        new_beams = set()

        for col in active_beams:
            if col < 0 or col >= len(line):
                # Beam exits the grid
                continue

            ch = line[col]
            if ch == '^':
                # Split! Count it and spawn left/right beams
                total_splits += 1
                new_beams.add(col - 1)
                new_beams.add(col + 1)
            else:
                # Beam continues downward
                new_beams.add(col)

        active_beams = new_beams

        if not active_beams:
            break

    return total_splits

if __name__ == "__main__":
    print(solve("input"))
