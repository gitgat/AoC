def max_joltage(bank):
    """Find max two-digit number from selecting two digits in order."""
    n = len(bank)
    if n < 2:
        return 0

    # Precompute suffix maximum (max digit from position i+1 to end)
    suffix_max = [0] * n
    suffix_max[n-1] = int(bank[n-1])
    for i in range(n-2, -1, -1):
        suffix_max[i] = max(int(bank[i]), suffix_max[i+1])

    # For each first position, compute best joltage
    best = 0
    for i in range(n-1):
        first_digit = int(bank[i])
        second_digit = suffix_max[i+1]
        joltage = first_digit * 10 + second_digit
        best = max(best, joltage)

    return best


def solve(input_path):
    with open(input_path) as f:
        lines = [line.strip() for line in f if line.strip()]

    # Filter to only digit characters (input may have escape chars)
    banks = [''.join(c for c in line if c.isdigit()) for line in lines]
    banks = [b for b in banks if b]  # Remove empty lines

    total = sum(max_joltage(bank) for bank in banks)
    return total


if __name__ == "__main__":
    result = solve("input")
    print(f"Answer: {result}")
