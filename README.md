

# Advent of Code 2025

My solution, this time in [Zig](https://ziglang.org). My personal goal is to keep the running
time for each day well below 0.1s (on my Raspberry Pi 2).


## Creating templates for new days

There is a helper tool to create empty files for each day:

    ./zig-out/bin/newday XX

where XX is a number 1, 2, &#x2026; creates a new unit `DayXX` (in file
`src/dayXX.pas`) along with empty test inputs
`input/XX/test_part1.txt` and `input/XX/test_part2.txt`. Furthermore,
the script downloads the instance file from the
[Advent-of-Code](https://adventofcode.com)-website. However, this works only if there is a
`.session` file in the root directory of the project (not contained in
the repository) that contains a valid session-key.

The script also registers the new file in [Jujutsu](https://www.jj-vcs.dev) (sorry, I
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


## Running all timing tests

All solutions for all days can be run using

    zig build times --release=fast


## Results

<table id="orgcd65c3c" border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">
<caption class="t-above"><span class="table-number">Table 1:</span> AMD Ryzen 5 Pro 7530U</caption>

<colgroup>
<col  class="org-right" />

<col  class="org-left" />

<col  class="org-right" />

<col  class="org-right" />

<col  class="org-right" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-right">day</th>
<th scope="col" class="org-left">version</th>
<th scope="col" class="org-right">part1</th>
<th scope="col" class="org-right">part2</th>
<th scope="col" class="org-right">time</th>
</tr>
</thead>
<tbody>
<tr>
<td class="org-right">1</td>
<td class="org-left">&#xa0;</td>
<td class="org-right">1092</td>
<td class="org-right">6616</td>
<td class="org-right">0.00</td>
</tr>
</tbody>
</table>

Total time (best versions): 0.002

