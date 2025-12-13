def find_doubled_in_range(start, end):
    """Find all doubled numbers in range [start, end].

    A doubled number is one where the string is XX (same half repeated).
    e.g., 55, 1212, 123123
    """
    result = []

    # Determine the range of digit lengths we need to consider
    min_digits = len(str(start))
    max_digits = len(str(end))

    for total_digits in range(min_digits, max_digits + 1):
        if total_digits % 2 != 0:
            continue  # Only even digit counts can be doubled

        half_digits = total_digits // 2

        # Base numbers have half_digits digits
        if half_digits == 1:
            base_start = 1  # No leading zeros, so start at 1
        else:
            base_start = 10 ** (half_digits - 1)
        base_end = 10 ** half_digits - 1

        for base in range(base_start, base_end + 1):
            doubled = int(str(base) * 2)
            if start <= doubled <= end:
                result.append(doubled)

    return result


def solve(input_path):
    with open(input_path) as f:
        line = f.read().strip()

    ranges = line.split(',')

    total = 0
    for r in ranges:
        if not r:
            continue
        start, end = map(int, r.split('-'))
        invalid_ids = find_doubled_in_range(start, end)
        total += sum(invalid_ids)

    return total


if __name__ == "__main__":
    result = solve("input")
    print(f"Answer: {result}")
