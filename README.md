# ngu
(Another) Beacon optimizer for NGU Industries.

## How to use:

1. Install Julia (and probably Juno, too).
2. Load this code into it.
3. Run `go(Config(a, b, c, d, e, terrainToMap(f)))` where a, b, c, d, e, and f are replaced with values. The meanings of these are explained below.
4. Watch numbers go up (hey, we already know that's your thing..)
5. The current "best" map will be output whenever search plateaus. Leave it as long as you want, and Ctrl+C when you're done.

## What the parameters mean

* a: `lastBeacon`: the index number of the last beacon to consider. `1` for just boxes, `2` for up to knights, `6` for up to arrows, `8` for up to walls, and `9` for up to donuts.
* b: `beamWidth`: how many potential solutions to keep throughout search steps. Setting this higher slows down the program but increases the number of potential solutions it inspects.
* c: `chaosWidth`: how many random variations to seed the search with at the start and whenever it plateaus. Setting this higher gives the algorithm more variety, but also means that configurations that "look worse" at the start will be eliminated rather than being given a chance.
* d: `initialChaos`: how many random moves to apply when randomising start positions.
* e: `shakeUpChaos`: how many random moves to apply when randomising local minima.
* f: `terrain`: the map to work on. This should be an array of strings with a `.` indicating a usable square and a ` ` indicating an unusable one.

## How it works (updated)

1. Start with the given map.
2. Apply `initialChaos` random moves (adding/removing/replacing beacons) to it and store the resulting map.
3. Add the map to the beam. Repeat step 2 until we have `chaosWidth` different random maps in the beam.
4. Take the first map from the beam.
5. Apply **every** possible move to it, where a possible move is either removing an existing beacon or placing a placeholder beacon on a square without one. Then, perform in-place optimization. Store the top `beamWidth` different highest scoring maps in the results.
6. Repeat 5 for all maps in the beam. keeping the results storage for all of them (so it will hold the top `beamWidth` different highest scoring maps generated from any map in the beam)
7. Print the highest score in the results.
8. See if the highest score in the results is higher than the highest score in the old beam.
9. If it isn't, see if the lowest score in the results is higher than the lowest score in the old beam.
10. If either of 7 or 8 is true, use the results as the next beam and go back to 4.
11. Add a "strike". If there have been 10 strikes in a row, continue, else go back to 4.
12. See if the highest score in the beam is higher than the best found so far. If it is, update the best found so far.
13. Print the best map found so far and its score.
14. Apply `shakeupChaos` random moves to the best map found so far and store the resulting map.
15. Use the random map to start a new beam. Repeat step 13 until we have `chaosWidth` new random maps in the beam.
16. Go back to step 4.
17. Repeat until the CPU burns out or you press Ctrl+C. Hopefully the latter will happen sooner.

## Using the multithreaded solver

If you want to use the multithreaded solver, follow the previous instructions but:

* Make sure that Julia is started with permission to make more than one thread. If you're starting it in Juno, it already is, but if you're starting it from the command line or desktop icon you need to add `--threads auto` to allow it to use as many threads as you have cores, or `--threads X` where X is the number you want to use (there is no benefit to using more than the number of cores you have, though)
* Call `gothreaded` instead of `go`.
* The multithreaded solver works better with a lower beam width and a lower `shakeUpChaos`.

How the multithreaded solver works:

* At the start, the system generates a different randomised set of starting maps for each core.
* Each core runs a beam search on their own set.
* Once all are done, the best generated maps from all cores are assembled into a beam.
* Core 1 is given that beam to work on in the next cycle. All remaining cores get a version of that beam with `shakeupChaos` random changes made to each map in the beam.

Be warned that running the multithreaded solver on all your cores will hit your CPU **hard**, as all will be running continuously. On the other hand, it does increase scores scarily fast.

## In-place type optimization and the "IPTO theorem"

The IPTO theorem: for any given set of beacon positions, there is exactly one mapping of beacon types to positions that is optimal, and it can be calculated from that set of positions alone.  

A beacon's contribution to a map's score is determined exactly by three things: its position, its type, and which squares in its affected area are obstructed (by terrain or other beacons).

The important point is that in the above statements, it does not matter **why** (or "by what") another square is obstructed, only that it is obstructed. Thus, the types of **other** beacons - or indeed whether blocked squares are occupied by beacons or walls/water etc - are irrelevant.

Therefore, to calculate the contribution of a given beacon to the map, we need to know that beacon's type, but only the *locations* of other beacons, not their types.

Therefore, the beacon type that will have the highest contribution to the map score on a single square can be calculated by only knowing the **locations** of other beacons, **not** their types. 

Once this is calculated for all squares, it is not possible for the score to be improved by changing the type of any beacon on the map. Changing the type of a beacon will not improve that beacon's score because it was already calculated to the type giving the maximum score improvement. It will not improve any other beacon's score because the only way beacons can affect other beacons is by obstructing them, and a beacon's type does not change its obstruction of other beacons.

Thus, it is **only necessary to search through combinations of beacon positions**. It is not necessary to try every type at every position because the optimal types can be calculated directly from the combination of positions.

