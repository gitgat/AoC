def max_joltage_k(bank, k):
    """Find max k-digit number from selecting k digits in order (greedy)."""
    n = len(bank)
    if n < k:
        return 0

    result = []
    start = 0

    for remaining in range(k, 0, -1):
        # Need to pick 'remaining' more digits
        # Can pick from positions start to n - remaining (inclusive)
        end = n - remaining

        # Find max digit in range [start, end], pick leftmost max
        best_val = -1
        best_pos = start
        for i in range(start, end + 1):
            if int(bank[i]) > best_val:
                best_val = int(bank[i])
                best_pos = i

        result.append(bank[best_pos])
        start = best_pos + 1

    return int(''.join(result))


def solve(input_path):
    with open(input_path) as f:
        lines = [line.strip() for line in f if line.strip()]

    # Filter to only digit characters
    banks = [''.join(c for c in line if c.isdigit()) for line in lines]
    banks = [b for b in banks if b]

    total = sum(max_joltage_k(bank, 12) for bank in banks)
    return total


if __name__ == "__main__":
    result = solve("input")
    print(f"Part 2 Answer: {result}")
