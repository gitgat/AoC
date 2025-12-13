#!/usr/bin/env python3
"""
Day 6: Trash Compactor

Numbers stacked vertically in columns, operator at bottom.
Problems separated by full columns of spaces.
"""

def solve(input_path):
    with open(input_path) as f:
        lines = f.read().rstrip('\n').split('\n')

    # Pad all lines to same length
    max_len = max(len(line) for line in lines)
    grid = [line.ljust(max_len) for line in lines]

    # Find the operator row (last non-empty row with * or +)
    op_row = None
    for i in range(len(grid) - 1, -1, -1):
        if '*' in grid[i] or '+' in grid[i]:
            op_row = i
            break

    # Find problem boundaries by looking for all-space columns
    # A separator column is one where ALL rows (except maybe empty ones) have a space
    num_rows = grid[:op_row]  # rows with numbers

    # Identify which columns are separators (all spaces in number rows AND operator row)
    separators = []
    for col in range(max_len):
        is_sep = True
        for row in num_rows + [grid[op_row]]:
            if col < len(row) and row[col] != ' ':
                is_sep = False
                break
        if is_sep:
            separators.append(col)

    # Group consecutive non-separator columns into problems
    problems = []
    current_start = None

    for col in range(max_len):
        if col in separators:
            if current_start is not None:
                problems.append((current_start, col))
                current_start = None
        else:
            if current_start is None:
                current_start = col

    if current_start is not None:
        problems.append((current_start, max_len))

    # Extract numbers and operator for each problem
    total = 0
    for start, end in problems:
        # Get the operator
        op_slice = grid[op_row][start:end].strip()
        if not op_slice:
            continue
        op = '*' if '*' in op_slice else '+'

        # Get numbers from each row
        numbers = []
        for row in num_rows:
            num_str = row[start:end].strip()
            if num_str and num_str.isdigit():
                numbers.append(int(num_str))

        if not numbers:
            continue

        # Calculate result
        if op == '+':
            result = sum(numbers)
        else:
            result = 1
            for n in numbers:
                result *= n

        total += result

    return total

if __name__ == "__main__":
    print(solve("input"))
