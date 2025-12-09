# Day 7: Laboratories

## Part 1

You thank the cephalopods for the help and exit the trash compactor, finding yourself in the familiar halls of a North Pole research wing.

Based on the large sign that says "teleporter hub", they seem to be researching teleportation; you can't help but try it for yourself and step onto the large yellow teleporter pad.

Suddenly, you find yourself in an unfamiliar room! The room has no doors; the only way out is the teleporter. Unfortunately, the teleporter seems to be leaking magic smoke.

Since this is a teleporter lab, there are lots of spare parts, manuals, and diagnostic equipment lying around. After connecting one of the diagnostic tools, it helpfully displays error code 0H-N0, which apparently means that there's an issue with one of the tachyon manifolds.

You quickly locate a diagram of the tachyon manifold (your puzzle input). A tachyon beam enters the manifold at the location marked S; tachyon beams always move downward. Tachyon beams pass freely through empty space (.). However, if a tachyon beam encounters a splitter (^), the beam is stopped; instead, a new tachyon beam continues from the immediate left and from the immediate right of the splitter.

For example:

```
.......S.......
...............
.......^.......
...............
......^.^......
...............
.....^.^.^.....
...............
....^.^...^....
...............
...^.^...^.^...
...............
..^...^.....^..
...............
.^.^.^.^.^...^.
...............
```

In this example, the incoming tachyon beam (|) extends downward from S until it reaches the first splitter:

```
.......S.......
.......|.......
.......^.......
```

At that point, the original beam stops, and two new beams are emitted from the splitter:

```
.......|.......
......|^|......
```

Those beams continue downward until they reach more splitters. At one point, two splitters create a total of only three tachyon beams, since they are both dumping tachyons into the same place between them (beams merge when they occupy the same position).

This process continues until all of the tachyon beams reach a splitter or exit the manifold. In this example, a tachyon beam is split a total of 21 times.

Analyze your manifold diagram. How many times will the beam be split?

**Answer: 1633**

## Part 2

With your analysis of the manifold complete, you begin fixing the teleporter. However, as you open the side of the teleporter to replace the broken manifold, you are surprised to discover that it isn't a classical tachyon manifold - it's a quantum tachyon manifold.

With a quantum tachyon manifold, only a single tachyon particle is sent through the manifold. A tachyon particle takes both the left and right path of each splitter encountered.

Since this is impossible, the manual recommends the many-worlds interpretation of quantum tachyon splitting: each time a particle reaches a splitter, it's actually time itself which splits. In one timeline, the particle went left, and in the other timeline, the particle went right.

To fix the manifold, what you really need to know is the number of timelines active after a single particle completes all of its possible journeys through the manifold.

In the example, there are many timelines. For instance:
- The timeline where the particle always went left
- The timeline where the particle alternated going left and right at each splitter
- The timeline where the particle ends up at the same point but takes a totally different path

In the example, the particle ends up on 40 different timelines.

Apply the many-worlds interpretation of quantum tachyon splitting to your manifold diagram. In total, how many different timelines would a single tachyon particle end up on?

**Answer: 34339203133559**
