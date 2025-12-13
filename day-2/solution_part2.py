def find_invalid_in_range(start, end):
    """Find all invalid IDs in range [start, end].

    An ID is invalid if it's made of some pattern repeated at least twice.
    e.g., 55 (5×2), 123123 (123×2), 111 (1×3), 1212121212 (12×5)
    """
    result = set()

    min_digits = len(str(start))
    max_digits = len(str(end))

    for total_digits in range(min_digits, max_digits + 1):
        # Find all divisors d of total_digits where total_digits/d >= 2
        for pattern_len in range(1, total_digits // 2 + 1):
            if total_digits % pattern_len != 0:
                continue

            repeats = total_digits // pattern_len
            if repeats < 2:
                continue

            # Generate all pattern_len-digit base patterns
            if pattern_len == 1:
                base_start = 1  # No leading zeros
            else:
                base_start = 10 ** (pattern_len - 1)
            base_end = 10 ** pattern_len - 1

            for base in range(base_start, base_end + 1):
                repeated = int(str(base) * repeats)
                if start <= repeated <= end:
                    result.add(repeated)

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
        invalid_ids = find_invalid_in_range(start, end)
        total += sum(invalid_ids)

    return total


if __name__ == "__main__":
    result = solve("input")
    print(f"Part 2 Answer: {result}")
