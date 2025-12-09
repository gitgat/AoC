# Day 9: Movie Theater

## Part 1

You slide down the firepole in the corner of the playground and land in the North Pole base movie theater!

The movie theater has a big tile floor with an interesting pattern. Elves here are redecorating the theater by switching out some of the square tiles in the big grid they form. Some of the tiles are red; the Elves would like to find the largest rectangle that uses red tiles for two of its opposite corners. They even have a list of where the red tiles are located in the grid (your puzzle input).

Each line contains X,Y coordinates of a red tile. You can choose any two red tiles as the opposite corners of your rectangle; your goal is to find the largest rectangle possible.

The area of a rectangle with corners at (x1, y1) and (x2, y2) is (|x2 - x1| + 1) * (|y2 - y1| + 1) since the rectangle includes both corner tiles.

Using two red tiles as opposite corners, what is the largest area of any rectangle you can make?

**Answer: 4748826374**

## Part 2

Some of the tiles are green; specifically, the Elves have placed green tiles on all of the tiles along straight lines between consecutive red tiles (forming the edges of a polygon), as well as all tiles inside the polygon. The red and green tiles together form the shape of a Christmas tree!

For Part 2, the rectangle must be entirely within the polygon - every tile of the rectangle must be either red (a vertex) or green (an edge or interior tile). The rectangle still uses two red tiles as opposite corners.

Using two red tiles as opposite corners, what is the largest area of any rectangle that lies entirely within the polygon?

**Answer: 1554370486**
