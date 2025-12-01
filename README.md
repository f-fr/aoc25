# Advent of Code 2025

My solution, this time in [zig][zig]. My personal goal is to keep the running
time for each day well below 0.1s (on my Raspberry Pi 2).

## Creating templates for new days

There is a helper tool to create empty files for each day:

    ./zig-out/bin/newday XX
    
where XX is a number 1, 2, ... creates a new unit `DayXX` (in file
`src/dayXX.pas`) along with empty test inputs
`input/XX/test_part1.txt` and `input/XX/test_part2.txt`. Furthermore,
the script downloads the instance file from the
[Advent-of-Code-website][aoc]. However, this works only if there is a
`.session` file in the root directory of the project (not contained in
the repository) that contains a valid session-key.

The script also registers the new file in [Jujutsu][jj] (sorry, I
don't use git directly).

## Compiling

Just run

    zig build

## Running the days

For each day there is single executable, e.g.

   ./zig-out/bin/01
   
Alternatively, each day can be run directly via the zig build script

    zig build run01
    
## Running the tests

All tests can be run using

    zig build test --summary all
    
## Running all times tests

All solutions for all days can be run using

    zig build times --release=fast

[aoc]: https://adventofcode.com
[zig]: https://ziglang.org
[jj]: https://www.jj-vcs.dev


<!-- Local Variables: -->
<!-- jinx-languages: "en_US" -->
<!-- End: -->
