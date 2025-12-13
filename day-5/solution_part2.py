def solve(input_path):
    with open(input_path) as f:
        content = f.read()

    # Split into ranges section and ingredients section (ignore ingredients)
    parts = content.strip().split('\n\n')
    range_lines = parts[0].strip().split('\n')

    # Parse ranges
    ranges = []
    for line in range_lines:
        start, end = map(int, line.split('-'))
        ranges.append((start, end))

    # Sort by start value
    ranges.sort()

    # Merge overlapping ranges
    merged = []
    for start, end in ranges:
        if merged and start <= merged[-1][1] + 1:
            # Overlaps or adjacent - extend the previous range
            merged[-1] = (merged[-1][0], max(merged[-1][1], end))
        else:
            # New separate range
            merged.append((start, end))

    # Count total IDs in merged ranges
    total = sum(end - start + 1 for start, end in merged)

    return total


if __name__ == "__main__":
    result = solve("input")
    print(f"Part 2 Answer: {result}")
