def solve(input_path):
    with open(input_path) as f:
        content = f.read()

    # Split into ranges section and ingredients section
    parts = content.strip().split('\n\n')
    range_lines = parts[0].strip().split('\n')
    ingredient_lines = parts[1].strip().split('\n')

    # Parse ranges
    ranges = []
    for line in range_lines:
        start, end = map(int, line.split('-'))
        ranges.append((start, end))

    # Parse ingredient IDs
    ingredients = [int(line) for line in ingredient_lines]

    # Count fresh ingredients
    fresh_count = 0
    for ing_id in ingredients:
        for start, end in ranges:
            if start <= ing_id <= end:
                fresh_count += 1
                break  # Found in at least one range, no need to check more

    return fresh_count


if __name__ == "__main__":
    result = solve("input")
    print(f"Answer: {result}")
