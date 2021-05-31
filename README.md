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

## How it works

1. Start with the given map.
2. Apply `initialChaos` random moves (adding/removing/replacing beacons) to it and store the resulting map.
3. Add the map to the beam. Repeat step 2 until we have `chaosWidth` different random maps in the beam.
4. Take the first map from the beam.
5. Apply **every** possible move to it. Store the top `beamWidth` different highest scoring maps in the results.
6. Repeat 5 for all maps in the beam. keeping the results storage for all of them (so it will hold the top `beamWidth` different highest scoring maps generated from any map in the beam)
7. Print the highest score in the results.
8. See if the highest score in the results is higher than the highest score in the old beam.
9. If it isn't, see if the lowest score in the results is higher than the lowest score in the old beam.
10. If either of 7 or 8 is true, use the results as the next beam and go back to 4.
11. See if the highest score in the beam is higher than the best found so far. If it is, update the best found so far.
12. Print the best map found so far and its score.
13. Apply `shakeupChaos` random moves to the best map found so far and store the resulting map.
14. Use the random map to start a new beam. Repeat step 13 until we have `chaosWidth` new random maps in the beam.
15. Go back to step 4.
16. Repeat until the CPU burns out or you press Ctrl+C. Hopefully the latter will happen sooner.



