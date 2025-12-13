def solve(input_path):
    with open(input_path) as f:
        grid = [line.rstrip('\n') for line in f if line.strip()]

    rows = len(grid)
    cols = len(grid[0]) if rows > 0 else 0

    # 8 directions: up, down, left, right, and 4 diagonals
    directions = [(-1, -1), (-1, 0), (-1, 1),
                  (0, -1),           (0, 1),
                  (1, -1),  (1, 0),  (1, 1)]

    accessible = 0

    for r in range(rows):
        for c in range(cols):
            if grid[r][c] != '@':
                continue

            # Count adjacent rolls
            neighbors = 0
            for dr, dc in directions:
                nr, nc = r + dr, c + dc
                if 0 <= nr < rows and 0 <= nc < cols and grid[nr][nc] == '@':
                    neighbors += 1

            # Accessible if fewer than 4 neighbors
            if neighbors < 4:
                accessible += 1

    return accessible


if __name__ == "__main__":
    result = solve("input")
    print(f"Answer: {result}")
