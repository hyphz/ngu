
import Base.==
import Base.isless
import Test



map1 = ["        ..          ",
        "        ...    .    ",
        "       . ..   ..... ",
        "       ..... ...... ",
        "        ..  ....... ",
        "   .... ..   . . .. ",
        "   ........ ........",
        "   ........ .  .    ",
        "   ..........  .    ",
        "   ..........  .    ",
        "      .. .......... ",
        "             ...  . ",
        "             ...... ",
        "  .    ...   ...... ",
        "  ..   ...          ",
        "       ...          ",
        "                    "]


"""
    Map

Represents a game map.

- `beacons::Array{UInt8,2}`: 2D array of beacon placements on the map.
  Each is 0 (no beacon), 255 (blocked square) or an index into the beacons
  array.
- `scores::Array{UInt16,2}`: 2D array of theoretical scores for each square.
  This is the score each square provides **if it did not have a beacon**. It
  is still set for squares with beacons (to allow easy removal) so **can not**
  be simply summed to give a score.
- `score::UInt16`: the total score of this map.
"""
mutable struct Map
    beacons::Array{UInt8,2}
    scores::Array{UInt16,2}
    score::UInt16
end

"""
    Beacon

Represents a beacon.

- `repr::Char`: character to use to represent the beacon.
- `score::UInt8`: the % bonus the beacon gives.
- `offsets::Array{Tuple{Int8,Int8},1}`: the list of offsets from the beacon's
  location to the squares it affects.
"""
struct Beacon
    repr::Char
    score::UInt8
    offsets::Array{Tuple{Int8,Int8},1}
end


struct Config
    lastBeacon::UInt8
    beamWidth::UInt16
    chaosWidth::UInt16
    initialChaos::UInt16
    shakeupChaos::UInt16
    terrain::Map
end


const beacons = [
 Beacon('*',30,[(-1,-1),(0,-1),(1,-1),(-1,0),(1,0),(-1,1),(0,1),(1,1)]),
 Beacon('k',35,[(-1,-2),(-2,-1),(-2,1),(-1,2),(1,-2),(2,-1),(2,1),(1,2)]),
 Beacon('^',22,[(0,-1),(0,-2),(0,-3),(0,-4),(0,-5),(-1,-3),(-2,-3),(1,-3),
                (2,-3),(-1,-4),(1,-4)]),
 Beacon('v',22,[(0,1),(0,2),(0,3),(0,4),(0,5),(-1,3),(-2,3),(1,3),
                (2,3),(-1,4),(1,4)]),
 Beacon('>',22,[(1,0),(2,0),(3,0),(4,0),(5,0),(3,-1),(3,-2),(3,1),(3,2),
                   (4,1),(4,-1)]),
 Beacon('<',22,[(-1,0),(-2,0),(-3,0),(-4,0),(-5,0),(-3,-1),(-3,-2),(-3,1),
                  (-3,2),(-4,1),(-4,-1)]),
 Beacon('-',27,[(-1,0),(-2,0),(-3,0),(-4,0),(-5,0),(-6,0),(1,0),(2,0),(3,0),
                  (4,0),(5,0),(6,0)]),
 Beacon('|',27,[(0,-1),(0,-2),(0,-3),(0,-4),(0,-5),(0,-6),(0,1),(0,2),(0,3),
                  (0,4),(0,5),(0,6)]),
 Beacon('o',26,[(-2,-2),(-1,-2),(0,-2),(1,-2),(2,-2),(-2,-1),(2,-1),(-2,0),(2,0),
                  (-2,1),(2,1),(-2,2),(-1,2),(0,2),(1,2),(2,2)])]


# Walls
#  (8,27,[(-1,0),(-2,0),(-3,0),(-4,0),(-5,0),(-6,0),(1,0),(2,0),(3,0),(4,0),
#          (5,0),(6,0)]),
#  (9,27,[(0,-1),(0,-2),(0,-3),(0,-4),(0,-5),(0,-6),(0,1),(0,2),(0,3),(0,4),
#          (0,5),(0,6)]),

#  (10,26,[(-2,-2),(-1,-2),(0,-2),(1,-2),(2,-2),(-2,-1),(2,-1),(-2,0),(2,0),
#          (-2,1),(2,1),(-2,2),(-1,2),(0,2),(1,2),(2,2)])

Base.copy(m::Map) = Map(copy(m.beacons), copy(m.scores), m.score)


function Base.hash(m::Map)
    return hash(m.beacons)
end

function ==(a::Map, b::Map)
    if hash(a) != hash(b)
        return false
    end
    (a.beacons == b.beacons)
end

isless(a::Map, b::Map) = a.score < b.score
Base.isequal(a::Map, b::Map) = a == b

"Returns a blank map (with no available squares)."
blankMap() = Map(fill(255,20,17), zeros(20, 17), 0)

"Returns a plain (map with all squares available)."
plainMap() = Map(zeros(20, 17), fill(100, 20, 17), 34000)

"Adds beacon `b` to map `m` at location `x,y` in place, and updates scores.
 This location must be empty and available."
function addBeacon!(m::Map, x, y, b)
    @assert m.beacons[x,y] == 0
    m.beacons[x,y] = b
    m.score -= m.scores[x,y]
    for (xo,yo) in beacons[b].offsets
        xd = x + xo
        yd = y + yo
        if (0 < xd < 21) && (0 < yd < 18) && (m.beacons[xd,yd] < 255)
            m.scores[xd,yd] += beacons[b].score
            if m.beacons[xd,yd] == 0
                m.score += beacons[b].score
            end
        end
    end
end

"Removes beacon from map `m` at location `x,y` in place, and updates scores.
 THere must be a beacon at that location."
function removeBeacon!(m::Map, x, y)
    @assert 0 < m.beacons[x,y] < 255
    oldBeacon = m.beacons[x,y]
    m.beacons[x,y] = 0
    m.score += m.scores[x,y]
    for (xo, yo) in beacons[oldBeacon].offsets
        xd = x + xo
        yd = y + yo
        if (0 < xd < 21) && (0 < yd < 18) && (m.beacons[xd,yd] < 255)
            m.scores[xd,yd] -= beacons[oldBeacon].score
            if m.beacons[xd,yd] == 0
                m.score -= beacons[oldBeacon].score
            end
        end
    end
end


"Calculates the score for a map. This usually doesn't need to be used because
 the add and remove operations maintain the score."
function score(m::Map)::UInt16
    s = 0
    for y in 1:17
        for x in 1:20
            if m.beacons[x,y] == 0
                s += m.scores[x,y]
            end
        end
    end
    s
end


@Test.testset "Map operations" begin
    m = plainMap()
    base = copy(m)
    for y in 1:17
        for x in 1:20
            for b in 1:length(beacons)
                addBeacon!(m, x, y, b)
                @Test.test m.score == score(m)
                removeBeacon!(m, x, y)
                @Test.test m.score == score(m)
                @Test.test m == base
            end
            addBeacon!(m, x, y, 1)
            base = copy(m)
        end
    end
end


"Like addBeacon!, but creates a copy of the map and returns it."
function addBeacon(m::Map, x, y, b)
    nm = copy(m)
    addBeacon!(nm, x, y, b)
    nm
end

"Like removeBeacon!, but creates a copy of the map and returns it."
function removeBeacon(m::Map, x, y)
    nm = copy(m)
    removeBeacon!(nm, x, y)
    nm
end

"Draws an ASCII representation of the map."
function draw(m::Map)
    for y in 1:17
        for x in 1:20
            if m.beacons[x,y] == 0
                print(".")
            elseif m.beacons[x,y] == 255
                print(" ")
            else
                print(beacons[m.beacons[x,y]].repr)
            end
        end
        println()
    end
end

"Creates a new map from an array of strings, paying attention only to
 terrain (not existing beacons)."
function terrainToMap(s::Array{String,1})
    m = blankMap()
    for y in 1:17
        for x in 1:20
            if s[y][x] == ' '
                m.beacons[x,y] = 255
                m.scores[x,y] = 0
            else
                m.beacons[x,y] = 0
                m.scores[x,y] = 100
                m.score += 100
            end
        end
    end
    m
end

"Checks if map `x` is in set `seen`. If it is not, adds map `x` to `b`, an
 array of maps sorted by score in descending order, and limits its length to
 `limit`."
function beamUpdate!(b::Vector{Map}, x::Map, seen::Set{UInt64}, limit)
    h = hash(x)
    in(seen,h) && return
    push!(seen,h)
    if (!isempty(b)) && (x.score < b[end].score)
        return
    end
    loc = searchsortedfirst(b, x, by=x -> x.score, rev=true)
    insert!(b,loc,x)
    length(b) > limit && resize!(b, limit)
end

"Updates the beacon on map `m` at location `x,y` to `b` in place. If `b` is 0,
 the beacon there is removed."
function setbeacon!(m::Map, x, y, b)
    m.beacons[x,y] == b && return
    m.beacons[x,y] != 0 && removeBeacon!(m, x, y)
    b > 0 && addBeacon!(m, x, y, b)
end

"Like setbeacon!, but copies the map and returns the new copy."
function setbeacon(m::Map, x, y, b)
    nm = copy(m)
    setbeacon!(nm, x, y, b)
    nm
end

"Construct a terrain validity map for the given map's terrain. The validity map is a
3D array `[x,y,b]` which indicates if placing beacon b at location x,y has
any possibility of increasing the map's score. If false, the placement can
never be useful on that terrain, no matter what other beacons exist."
function validitymap(m::Map)
    vmap = fill(false,20,17,length(beacons))
    for y in 1:17
        for x in 1:20
            m.beacons[x,y] == 255 && continue
            for b in 1:length(beacons)
                test = copy(m)
                addBeacon!(test, x, y, b)
                vmap[x, y, b] = (test.score > m.score)
            end
        end
    end
    vmap
end

"Perform beam search on all maps in `s` and return a list of the `limit` best
maps found. `vmap` must be the terrain validity map for all maps in `s`."
function beam(s::Vector{Map}, limit, maxb, vmap)
    beam = Vector{Map}()
    seen = Set{UInt64}()
    sizehint!(beam, limit)
    l = 0
    cl = length(beam)
    for m in s
        for y in 1:17
            for x in 1:20
                m.beacons[x,y] == 255 && continue
                for b in 0:maxb
                    if (b == 0) || vmap[x,y,b]
                        mx = setbeacon(m, x, y, b)
                        beamUpdate!(beam, mx, seen, limit)
                    end
                end
            end
        end
    end
    beam
end

"Make `level` random changes to `m` in place. `vmap` must be the terrain
validity map for `m`."
function applychaos!(m::Map, level, maxb, vmap)
    for i in 0:level
        ok = false
        x = 0
        y = 0
        b = 0
        while !ok
            x = rand(1:20)
            y = rand(1:17)
            b = rand(0:maxb)
            ok = (m.beacons[x,y] != 255) && (m.beacons[x,y] != b) &&
                 ((b == 0) || vmap[x,y,b])
        end
        setbeacon!(m, x, y, b)
    end
end


"Generate a list of `size` different random variations on `base`, each by
making `level` random changes. `vmap` must be the terrain validity map for
`base`."
function genchaoslist(base::Map, level, size, maxb, vmap)
    x = Vector{Map}()
    sizehint!(x,size)
    seen = Set{UInt64}()
    hits = 0
    while hits < size
        nm = copy(base)
        applychaos!(nm, level, maxb, vmap)
        h = hash(nm)
        if !in(seen,h)
            push!(seen,h)
            push!(x,nm)
            hits += 1
        end
    end
    sort!(x, by=x->x.score, rev=true)
    x
end


"Main function."
function go(c:: Config)
    base = c.terrain
    vmap = validitymap(base)
    x = genchaoslist(base, c.initialChaos, c.chaosWidth, c.lastBeacon, vmap)
    best = copy(x[1])
    worst = 0
    bestbest = copy(x[1])
    while true
        x = beam(x, c.beamWidth, c.lastBeacon, vmap)
        if x[1].score > best.score
            best = copy(x[1])
            println(best.score)
        else
            if x[end].score > worst
                worst = x[end].score
                println("Improving low results ",worst)
            else
                print("Emergency reseed")
                if (best.score > bestbest.score)
                    bestbest = copy(best)
                end
                draw(bestbest)
                println(bestbest.score)
                empty(x)
                x = genchaoslist(bestbest, c.shakeupChaos, c.chaosWidth, c.lastBeacon, vmap)
                best = copy(x[1])
                worst = 0
            end
        end
    end
end

function test1()
    go(Config(9,1000,1000,100,100,terrainToMap(map1)))
end

function rebraneStyle()
    go(Config(9,50,1,200,200,terrainToMap(map1)))
end
