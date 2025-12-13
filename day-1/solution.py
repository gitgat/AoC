def solve(input_path):
    with open(input_path) as f:
        rotations = [line.strip() for line in f if line.strip()]

    position = 50
    zero_count = 0

    for rotation in rotations:
        direction = rotation[0]
        distance = int(rotation[1:])

        if direction == 'L':
            position = (position - distance) % 100
        else:  # R
            position = (position + distance) % 100

        if position == 0:
            zero_count += 1

    return zero_count


def count_zero_crossings(position, direction, distance):
    """Count how many times dial passes through 0 during rotation."""
    if direction == 'L':
        if position == 0:
            return distance // 100
        elif distance >= position:
            return (distance - position) // 100 + 1
        else:
            return 0
    else:  # R
        if position == 0:
            return distance // 100
        elif distance >= (100 - position):
            return (distance - (100 - position)) // 100 + 1
        else:
            return 0


def solve_part2(input_path):
    with open(input_path) as f:
        rotations = [line.strip() for line in f if line.strip()]

    position = 50
    zero_count = 0

    for rotation in rotations:
        direction = rotation[0]
        distance = int(rotation[1:])

        zero_count += count_zero_crossings(position, direction, distance)

        if direction == 'L':
            position = (position - distance) % 100
        else:  # R
            position = (position + distance) % 100

    return zero_count


if __name__ == "__main__":
    result = solve("../input")
    print(f"Part 1: {result}")
    result2 = solve_part2("../input")
    print(f"Part 2: {result2}")
