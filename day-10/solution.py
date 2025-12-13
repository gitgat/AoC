#!/usr/bin/env python3
"""
Day 10: Factory

Part 1: Find minimum button presses to configure indicator lights (XOR/toggle).
Part 2: Find minimum button presses to reach joltage targets (additive).
"""

import re
from itertools import combinations, product


def parse_line(line):
    """Parse a machine line into target pattern, buttons, and joltage."""
    # Extract target pattern in brackets
    target_match = re.search(r'\[([.#]+)\]', line)
    target = target_match.group(1)

    # Extract buttons in parentheses
    buttons = re.findall(r'\(([0-9,]+)\)', line)
    buttons = [list(map(int, b.split(','))) for b in buttons]

    # Extract joltage requirements in braces
    joltage_match = re.search(r'\{([0-9,]+)\}', line)
    joltage = list(map(int, joltage_match.group(1).split(',')))

    return target, buttons, joltage


def solve_machine_part1(target, buttons):
    """Find minimum button presses to reach target state (XOR/toggle)."""
    # Convert target to bitmask
    target_bits = sum(1 << i for i, c in enumerate(target) if c == '#')

    # Convert each button to a bitmask of which lights it toggles
    button_masks = []
    for btn in buttons:
        mask = 0
        for pos in btn:
            mask |= (1 << pos)
        button_masks.append(mask)

    n_buttons = len(button_masks)

    # Try all subsets in order of increasing size
    for size in range(n_buttons + 1):
        for subset in combinations(range(n_buttons), size):
            result = 0
            for i in subset:
                result ^= button_masks[i]
            if result == target_bits:
                return size

    return float('inf')


def solve_machine_part2(buttons, joltage):
    """Find minimum button presses to reach joltage targets (additive).

    Uses Gaussian elimination to find the solution space, then optimizes.
    """
    from fractions import Fraction

    n_counters = len(joltage)
    n_buttons = len(buttons)

    # Build matrix A where A[j][i] = 1 if button i affects counter j
    A = [[0] * n_buttons for _ in range(n_counters)]
    for i, btn in enumerate(buttons):
        for pos in btn:
            if pos < n_counters:
                A[pos][i] = 1

    b = joltage[:]

    # Convert to fractions for exact arithmetic
    A = [[Fraction(x) for x in row] for row in A]
    b = [Fraction(x) for x in b]

    # Augmented matrix [A | b]
    aug = [row + [b[i]] for i, row in enumerate(A)]

    # Gaussian elimination with partial pivoting
    pivot_cols = []
    row = 0
    for col in range(n_buttons):
        # Find pivot
        pivot_row = None
        for r in range(row, n_counters):
            if aug[r][col] != 0:
                pivot_row = r
                break
        if pivot_row is None:
            continue

        pivot_cols.append(col)

        # Swap rows
        aug[row], aug[pivot_row] = aug[pivot_row], aug[row]

        # Scale pivot row
        scale = aug[row][col]
        aug[row] = [x / scale for x in aug[row]]

        # Eliminate other rows
        for r in range(n_counters):
            if r != row and aug[r][col] != 0:
                factor = aug[r][col]
                aug[r] = [aug[r][i] - factor * aug[row][i] for i in range(n_buttons + 1)]

        row += 1
        if row >= n_counters:
            break

    # Free variables are columns not in pivot_cols
    free_cols = [c for c in range(n_buttons) if c not in pivot_cols]

    # If there are no free variables, we have a unique solution (if it exists)
    if not free_cols:
        # Solution is in the last column
        solution = [Fraction(0)] * n_buttons
        for i, col in enumerate(pivot_cols):
            solution[col] = aug[i][n_buttons]

        # Check if solution is non-negative integer
        total = 0
        for x in solution:
            if x < 0 or x.denominator != 1:
                return float('inf')  # No valid solution
            total += int(x)
        return total

    # With free variables, we need to search for minimum sum solution
    # The free variables can take any non-negative integer value
    # Pivot variables are determined by free variables

    # For each pivot row i with pivot column pivot_cols[i]:
    # x[pivot_cols[i]] = aug[i][n_buttons] - sum(aug[i][j] * x[j] for j in free_cols)

    # We want to minimize sum(x) subject to all x >= 0

    # Try searching over reasonable ranges of free variables
    n_free = len(free_cols)
    n_pivot = len(pivot_cols)

    # Estimate upper bound for free variables
    max_free = max(joltage) + 1

    best = float('inf')

    # For small number of free variables, enumerate
    if n_free <= 4:
        from itertools import product
        for free_vals in product(range(max_free + 1), repeat=n_free):
            solution = [Fraction(0)] * n_buttons

            # Set free variables
            for i, col in enumerate(free_cols):
                solution[col] = Fraction(free_vals[i])

            # Compute pivot variables
            valid = True
            for i, pcol in enumerate(pivot_cols):
                val = aug[i][n_buttons]
                for j, fcol in enumerate(free_cols):
                    val -= aug[i][fcol] * free_vals[j]
                if val < 0 or val.denominator != 1:
                    valid = False
                    break
                solution[pcol] = val

            if valid:
                total = sum(int(x) for x in solution)
                best = min(best, total)

        return best if best != float('inf') else float('inf')

    # For more free variables, use branch and bound
    def search(free_idx, free_vals, current_sum):
        nonlocal best

        if current_sum >= best:
            return

        if free_idx == n_free:
            # Compute pivot variables
            solution = [Fraction(0)] * n_buttons
            for i, col in enumerate(free_cols):
                solution[col] = Fraction(free_vals[i])

            for i, pcol in enumerate(pivot_cols):
                val = aug[i][n_buttons]
                for j, fcol in enumerate(free_cols):
                    val -= aug[i][fcol] * free_vals[j]
                if val < 0 or val.denominator != 1:
                    return
                solution[pcol] = val

            total = sum(int(x) for x in solution)
            best = min(best, total)
            return

        # Try values for this free variable
        fcol = free_cols[free_idx]
        for v in range(max_free + 1):
            if current_sum + v >= best:
                break
            search(free_idx + 1, free_vals + [v], current_sum + v)

    search(0, [], 0)
    return best if best != float('inf') else float('inf')


def solve(input_path):
    with open(input_path) as f:
        lines = f.read().strip().split('\n')

    total_part1 = 0
    total_part2 = 0

    for line in lines:
        target, buttons, joltage = parse_line(line)
        total_part1 += solve_machine_part1(target, buttons)
        total_part2 += solve_machine_part2(buttons, joltage)

    return total_part1, total_part2


if __name__ == "__main__":
    p1, p2 = solve("input")
    print(f"Part 1: {p1}")
    print(f"Part 2: {p2}")
