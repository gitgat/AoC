#!/usr/bin/env python3
"""
Day 7: Laboratories - Part 2

Many-worlds interpretation: each split creates two timelines.
Count total timelines at the end.
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

    # Track beam positions with timeline counts
    # beams[col] = number of timelines at that column
    beams = {start_col: 1}

    # Process each row below the start
    for row in range(start_row + 1, len(lines)):
        line = lines[row]
        new_beams = {}

        for col, timeline_count in beams.items():
            if col < 0 or col >= len(line):
                # Beam exits the grid, timelines still count at exit
                new_beams[col] = new_beams.get(col, 0) + timeline_count
                continue

            ch = line[col]
            if ch == '^':
                # Split! Each timeline becomes two (left and right)
                new_beams[col - 1] = new_beams.get(col - 1, 0) + timeline_count
                new_beams[col + 1] = new_beams.get(col + 1, 0) + timeline_count
            else:
                # Beam continues downward, timelines preserved
                new_beams[col] = new_beams.get(col, 0) + timeline_count

        beams = new_beams

        if not beams:
            break

    # Total timelines is the sum of all timeline counts
    return sum(beams.values())

if __name__ == "__main__":
    print(solve("input"))
