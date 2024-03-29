
import Base.==
import Base.isless
import Test
import Base.copyto!
import Printf.@printf



map1 = [
    "        ..          ",
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
    "                    ",
]


map2 = [
    "        .     ......",
    ".... .....     ...  ",
    ".......  ..  ...... ",
    ".  ............ ..  ",
    ".    .............  ",
    ".    ...............",
    ".  .................",
    "................ ...",
    "........    ....... ",
    " ......      ...... ",
    "... . .      .....  ",
    "... . .      ....   ",
    "... . .      ...... ",
    "... . ..    ......  ",
    "... . ..........    ",
    "............ ..     ",
    " .............      ",
]


map3 = [
    ". ...  .............",
    "  ... ..... ...  .. ",
    "....... .......  ...",
    "...  ....... .......",
    "...  ....... .......",
    "....... . .. .... ..",
    "... ..   ....... ...",
    "  ........  ........",
    ".....  . ...........",
    ".... ..  ......  ...",
    "......... . ...   ..",
    "      ... .....    .",
    ".. ..  .   ..     ..",
    ".. .. ... ..... ... ",
    "       ....   .... .",
    ".. .. ....  . ... ..",
    ".. ..   ... .... ...",
]

map4 = [
    "....     ... ..  ...",
    ".....           ....",
    "....  ...   ........",
    "..     .  .  .....  ",
    "..  .   .   ...... .",
    "..  ...... ......   ",
    "...  .. .. ...... ..",
    "....  .... .........",
    ". ...  ... ...   ...",
    ".  ...   . ... .   .",
    "..  ....         . .",
    "...  ..  ..... ... .",
    ".... ....  ..      .",
    "......  . ... ......",
    " .....  ..... .  ...",
    "  ........... .. ...",
    "   ..........    ..."
]

tiscore = [
    "        kv          ",
    "        oo.    .    ",
    "       . ..   ..... ",
    "       ..... --.... ",
    "        oo  ooooooo ",
    "   .... oo   . . o. ",
    "   .-...... -.......",
    "   ooo..o.. o  |    ",
    "   .oo.ooo.oo  |    ",
    "   .....o-...  .    ",
    "      .. ...--..... ",
    "             o..  < ",
    "             o..oo< ",
    "  .    ...   -..^.. ",
    "  ..   .*.          ",
    "       ...          ",
    "                    "
]

ipotest = [
    "        **          ",
    "        **.    .    ",
    "       . ..   ..... ",
    "       ..... --.... ",
    "        **  ******* ",
    "   .... **   . . *. ",
    "   .*...... *.......",
    "   ***..*.. *  *    ",
    "   .**.***.**  *    ",
    "   .....**...  .    ",
    "      .. ...**..... ",
    "             *..  * ",
    "             *..*** ",
    "  .    ...   *..*.. ",
    "  ..   .*.          ",
    "       ...          ",
    "                    "
]


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

const VMap = Array{Bool,3}

struct Config
    lastBeacon::UInt8
    beamWidth::UInt16
    chaosWidth::UInt16
    initialChaos::UInt16
    shakeupChaos::UInt16
    terrain::Map
end

# Production
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

# Speed
const spdBeacons = [
    Beacon(
        '*',
        40,
        [(-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1)],
    ),
    Beacon(
        'k',
        35,
        [
            (-1, -2),
            (-2, -1),
            (-2, 1),
            (-1, 2),
            (1, -2),
            (2, -1),
            (2, 1),
            (1, 2),
        ],
    ),
    Beacon(
        '^',
        26,
        [
            (0, -1),
            (0, -2),
            (0, -3),
            (0, -4),
            (0, -5),
            (-1, -3),
            (-2, -3),
            (1, -3),
            (2, -3),
            (-1, -4),
            (1, -4),
        ],
    ),
    Beacon(
        'v',
        26,
        [
            (0, 1),
            (0, 2),
            (0, 3),
            (0, 4),
            (0, 5),
            (-1, 3),
            (-2, 3),
            (1, 3),
            (2, 3),
            (-1, 4),
            (1, 4),
        ],
    ),
    Beacon(
        '>',
        26,
        [
            (1, 0),
            (2, 0),
            (3, 0),
            (4, 0),
            (5, 0),
            (3, -1),
            (3, -2),
            (3, 1),
            (3, 2),
            (4, 1),
            (4, -1),
        ],
    ),
    Beacon(
        '<',
        26,
        [
            (-1, 0),
            (-2, 0),
            (-3, 0),
            (-4, 0),
            (-5, 0),
            (-3, -1),
            (-3, -2),
            (-3, 1),
            (-3, 2),
            (-4, 1),
            (-4, -1),
        ],
    ),
    Beacon(
        '-',
        27,
        [
            (-1, 0),
            (-2, 0),
            (-3, 0),
            (-4, 0),
            (-5, 0),
            (-6, 0),
            (1, 0),
            (2, 0),
            (3, 0),
            (4, 0),
            (5, 0),
            (6, 0),
        ],
    ),
    Beacon(
        '|',
        27,
        [
            (0, -1),
            (0, -2),
            (0, -3),
            (0, -4),
            (0, -5),
            (0, -6),
            (0, 1),
            (0, 2),
            (0, 3),
            (0, 4),
            (0, 5),
            (0, 6),
        ],
    ),
    Beacon(
        'o',
        23,
        [
            (-2, -2),
            (-1, -2),
            (0, -2),
            (1, -2),
            (2, -2),
            (-2, -1),
            (2, -1),
            (-2, 0),
            (2, 0),
            (-2, 1),
            (2, 1),
            (-2, 2),
            (-1, 2),
            (0, 2),
            (1, 2),
            (2, 2),
        ],
    ),
]



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
blankMap() = Map(fill(255, 20, 17), zeros(20, 17), 0)

"Returns a plain (map with all squares available)."
plainMap() = Map(zeros(20, 17), fill(100, 20, 17), 34000)


function copyto!(a::Map, b::Map)
    copyto!(a.beacons, b.beacons)
    copyto!(a.scores, b.scores)
    a.score = b.score
end


"Adds beacon `b` to map `m` at location `x,y` in place, and updates scores.
 This location must be empty and available."
function addBeacon!(m::Map, x::UInt8, y::UInt8, b::UInt8)
    @assert m.beacons[x, y] == 0
    m.beacons[x, y] = b
    m.score -= m.scores[x, y]
    for (xo, yo) in beacons[b].offsets
        xd = x + xo
        yd = y + yo
        if (0 < xd < 21) && (0 < yd < 18) && (m.beacons[xd, yd] < 255)
            @inbounds m.scores[xd, yd] += beacons[b].score
            if @inbounds m.beacons[xd, yd] == 0
                m.score += @inbounds beacons[b].score
            end
        end
    end
end

"Removes beacon from map `m` at location `x,y` in place, and updates scores.
 THere must be a beacon at that location."
function removeBeacon!(m::Map, x::UInt8, y::UInt8)
    @assert 0 < m.beacons[x, y] < 255
    oldBeacon = m.beacons[x, y]
    m.beacons[x, y] = 0
    m.score += m.scores[x, y]
    for (xo, yo) in beacons[oldBeacon].offsets
        xd = x + xo
        yd = y + yo
        if (0 < xd < 21) && (0 < yd < 18) && (m.beacons[xd, yd] < 255)
            @inbounds m.scores[xd, yd] -= beacons[oldBeacon].score
            if @inbounds m.beacons[xd, yd] == 0
                m.score -= @inbounds beacons[oldBeacon].score
            end
        end
    end
end


"Calculates the score for a map. This usually doesn't need to be used because
 the add and remove operations maintain the score."
function score(m::Map)::UInt16
    s = 0
    for y = 1:17
        for x = 1:20
            if m.beacons[x, y] == 0
                s += m.scores[x, y]
            end
        end
    end
    s
end


Test.@testset "Map operations" begin
    m = plainMap()
    base = copy(m)
    for y::UInt8 = 1:17
        for x::UInt8 = 1:20
            for b::UInt8 = 1:length(beacons)
                addBeacon!(m, x, y, b)
                Test.@test m.score == score(m)
                removeBeacon!(m, x, y)
                Test.@test m.score == score(m)
                Test.@test m == base
                Test.@test m.score == base.score
            end
            addBeacon!(m, x, y, UInt8(1))
            base = copy(m)
        end
    end
end



"Like addBeacon!, but creates a copy of the map and returns it."
function addBeacon(m::Map, x::UInt8, y::UInt8, b::UInt8)::Map
    nm = copy(m)
    addBeacon!(nm, x, y, b)
    nm
end

"Like removeBeacon!, but creates a copy of the map and returns it."
function removeBeacon(m::Map, x::UInt8, y::UInt8)::Map
    nm = copy(m)
    removeBeacon!(nm, x, y)
    nm
end

"Draws an ASCII representation of the map."
function draw(m::Map)
    for y = 1:17
        for x = 1:20
            if m.beacons[x, y] == 0
                print(".")
            elseif m.beacons[x, y] == 255
                print(" ")
            else
                print(beacons[m.beacons[x, y]].repr)
            end
        end
        println()
    end
end

"Draws an ASCII representation of the map including the
 score for each square."
function fulldraw(m::Map)
    score = 0
    for y = 1:17
        rowScore = 0
        for x = 1:20
            if m.beacons[x, y] == 0
                @printf "%3u " m.scores[x,y]
                rowScore += m.scores[x,y]
                score += m.scores[x,y]
            elseif m.beacons[x, y] == 255
                print("    ")
            else
                print(" ", beacons[m.beacons[x, y]].repr, "  ")
            end
        end
        println(":: ",rowScore)
    end
    print(score)
end

"Creates a new map from an array of strings, paying attention only to
 terrain (not existing beacons). Existing beacons are treated as .s,
 so this function can strip beacons from an example map."
function terrainToMap(s::Array{String,1})::Map
    m = blankMap()
    for y = 1:17
        for x = 1:20
            if s[y][x] == ' '
                m.beacons[x, y] = 255
                m.scores[x, y] = 0
            else
                m.beacons[x, y] = 0
                m.scores[x, y] = 100
                m.score += 100
            end
        end
    end
    m
end

"Creates a new map from an array of strings, paying attention to
 terrain and existing beacons."
function premapToMap(s::Array{String,1})::Map
    m = terrainToMap(s)
    for y::UInt8 = 1:17
        for x::UInt8 = 1:20
            if (s[y][x] != ' ') && (s[y][x] != '.')
                ok = false
                for (bi::UInt8, b) in enumerate(beacons)
                    if b.repr == s[y][x]
                        addBeacon!(m, x, y, bi)
                        ok = true
                        break
                    end
                end
                ok || println("Unknown character ",s[y][x]," in map")
            end
        end
    end
    m
end


"Checks if map `x` is in set `seen`. If it is not, adds map `x` to `b`, an
 array of maps sorted by score in descending order, and limits its length to
 `limit`."
function beamUpdate!(b::Vector{Map}, x::Map, seen::Set{UInt64}, limit::UInt16)
    h = hash(x)
    in(seen, h) && return
    push!(seen, h)
    if (!isempty(b)) && (x.score < b[end].score)
        return
    end
    loc = searchsortedfirst(b, x, by = x -> x.score, rev = true)
    insert!(b, loc, copy(x))
    length(b) > limit && resize!(b, limit)
end

"Updates the beacon on map `m` at location `x,y` to `b` in place. If `b` is 0,
 the beacon there is removed."
function setbeacon!(m::Map, x::UInt8, y::UInt8, b::UInt8)
    m.beacons[x, y] == b && return
    m.beacons[x, y] != 0 && removeBeacon!(m, x, y)
    b > 0 && addBeacon!(m, x, y, b)
end

"Like setbeacon!, but copies the map and returns the new copy."
function setbeacon(m::Map, x::UInt8, y::UInt8, b::UInt8)
    nm = copy(m)
    setbeacon!(nm, x, y, b)
    nm
end

Test.@testset "Bare scores" begin
    m = plainMap()
    base = copy(m)
    for b::UInt8 = 1:length(beacons)
        setbeacon!(m, UInt8(10), UInt8(8), b)
        Test.@test m.score == (base.score - 100) + (beacons[b].score * length(beacons[b].offsets))
        setbeacon!(m, UInt8(10), UInt8(8), UInt8(0))
        Test.@test m.score == base.score
    end
end


"Construct a terrain validity map for the given map's terrain. The validity map is a
3D array `[x,y,b]` which indicates if placing beacon b at location x,y has
any possibility of increasing the map's score. If false, the placement can
never be useful on that terrain, no matter what other beacons exist."
function validitymap(m::Map)::VMap
    vmap = fill(false, 20, 17, length(beacons))
    for y::UInt8 = 1:17
        for x::UInt8 = 1:20
            m.beacons[x, y] == 255 && continue
            for b::UInt8 = 1:length(beacons)
                test = copy(m)
                addBeacon!(test, x, y, b)
                vmap[x, y, b] = (test.score > m.score)
            end
        end
    end
    vmap
end

"Optimize beacon types in place. Per wiki page, there is only one optimal
 set of beacon types per beacon range and set of occupied squares."
function inplaceopt!(m::Map, maxb::UInt8, vmap::VMap)
    for y::UInt8 = 1:17
        for x::UInt8 = 1:20
            m.beacons[x,y] == 0 && continue
            m.beacons[x,y] == 255 && continue
            bestScore = m.score
            bestBeacon = m.beacons[x,y]
            for b::UInt8 = 1:maxb
                vmap[x, y, b] || continue
                setbeacon!(m, x, y, b)
                if m.score > bestScore
                    bestScore = m.score
                    bestBeacon = b
                end
            end
            setbeacon!(m, x, y, bestBeacon)
        end
    end
end


"Beam search based on optimization theorem."
function beambests(s::Vector{Map}, limit::UInt16, maxb::UInt8, vmap::VMap)::Vector{Map}
    beam = Vector{Map}()
    seen = Set{UInt64}()
    sizehint!(beam, limit)
    workMap = blankMap()   # Save on memory reallocations by reusing this space
                           # and only copying it if it's accepted into the beam
    l = 0
    cl = length(beam)
    for m in s
        beamUpdate!(beam, m, seen, limit) # Just in case the unchanged map is competitive
        for y::UInt8 = 1:17
            for x::UInt8 = 1:20
                m.beacons[x, y] == 255 && continue
                bestScore = m.score
                bestBeacon = 0
                # Because of IPO, we only need to consider presence or absence of beacon
                copyto!(workMap, m)
                if m.beacons[x, y] > 0
                    removeBeacon!(workMap, x, y)
                else
                    addBeacon!(workMap, x, y, UInt8(1))
                end
                inplaceopt!(workMap, maxb, vmap)
                beamUpdate!(beam, workMap, seen, limit)
            end
        end
    end
    beam
end



"Make `level` random changes to `m` in place. `vmap` must be the terrain
validity map for `m`."
function applychaos!(m::Map, level::UInt16, maxb::UInt8, vmap::VMap)
    for i = 0:level
        ok = false
        x = UInt8(0)
        y = UInt8(0)
        b = UInt8(0)
        while !ok
            x::UInt8 = rand(1:20)
            y::UInt8 = rand(1:17)
            h::UInt8 = rand(1:100)
            if h < 50
                b = UInt8(0)
            else
                b::UInt8 = rand(1:maxb)
            end
            ok =
                (m.beacons[x, y] != 255) &&
                (m.beacons[x, y] != b) &&
                ((b == 0) || vmap[x, y, b])
        end
        setbeacon!(m, x, y, b)
    end
end

"Make `level` random changes to `m` in place as applychaos! does, but
IPO the map afterwards."
function applybinchaos!(m::Map, level::UInt16, maxb::UInt8, vmap::VMap)
    for i = 0:level
        ok = false
        x = UInt8(0)
        y = UInt8(0)
        while !ok
            x::UInt8 = rand(1:20)
            y::UInt8 = rand(1:17)
            ok = (m.beacons[x, y] != 255)
        end
        if m.beacons[x,y] > 0
            setbeacon!(m, x, y, UInt8(0))
        else
            setbeacon!(m, x, y, UInt8(1))
        end
    end
    inplaceopt!(m, maxb, vmap)
end


"Generate a list of `size` different random variations on `base`, each by
making `level` random changes. `vmap` must be the terrain validity map for
`base`."
function genchaoslist(base::Map, level::UInt16, size::UInt16, maxb::UInt8, vmap::VMap)::Vector{Map}
    x = Vector{Map}()
    sizehint!(x, size)
    seen = Set{UInt64}()
    hits = 0
    while hits < size
        nm = copy(base)
        applychaos!(nm, level, maxb, vmap)
        h = hash(nm)
        if !in(seen, h)
            push!(seen, h)
            push!(x, nm)
            hits += 1
        end
    end
    sort!(x, by = x -> x.score, rev = true)
    x
end



"Late acceptance hill climbing"
function lahc(map, maxb::UInt8, width::UInt32, steps::UInt16, failThreshold::UInt16)
    last = map
    vmap = validitymap(last)
    buffer = fill(last.score, width)
    index = 1
    realFail = failThreshold * width
    fails = 0
    realbest = last.score
    work = blankMap()
    while true
        copyto!(work, last)
        applybinchaos!(work, steps, maxb, vmap)
        if ((work.score >= last.score) || (work.score >= buffer[index]))
            fails = 0
            copyto!(last, work)
            buffer[index] = work.score
            if work.score > realbest
                realbest = work.score
                draw(work)
                println(work.score)
            end
        else
            fails += 1
            if fails > realFail

                fails = 0
                steps += UInt16(1)
                println("Increasing step count to ",steps)
            end
        end

        index += 1
        if index > width
            index = 1
        end
    end
end


function gothreaded(c::Config)
    base = c.terrain
    vmap = validitymap(base)
    xs = [genchaoslist(base, c.initialChaos, c.chaosWidth, c.lastBeacon, vmap)
        for t = 1:Threads.nthreads()]
    best = copy(xs[1][1])
    worst = 0
    bestbest = copy(xs[1][1])
    workspace = [blankMap() for t = 1:c.beamWidth]
    while true
        @Threads.threads for t = 1:Threads.nthreads()
            xs[t] = beambests(xs[t], c.beamWidth, c.lastBeacon, vmap)
        end
        bestthread = 0
        bestThreadScore = 0
        for t = 1:Threads.nthreads()
            print(xs[t][1].score,"-",xs[t][end].score, " ")
            if (xs[t][1].score > bestThreadScore)
                bestthread = t
                bestThreadScore = xs[t][1].score
            end
        end
        println(" -- ",bestThreadScore)
        if bestThreadScore > best.score
            copyto!(best, xs[bestthread][1])
            draw(best)
        end
        indices = [1 for x in 1:Threads.nthreads()]
        copyto!(workspace[1], best)
        for x = 2:c.beamWidth
            bestScore = 0
            bestThread = 0
            for t = 1:Threads.nthreads()
                if indices[t] < length(xs[t])
                    if xs[t][indices[t]].score > bestScore
                        bestScore = xs[t][indices[t]].score
                        bestThread = t
                    end
                end
            end
            copyto!(workspace[x],xs[bestThread][indices[bestThread]])
            indices[bestThread] += 1
        end
        for t = 1:Threads.nthreads()
            xs[t] = [blankMap() for t = 1:c.beamWidth]
            for w = 1:c.beamWidth
                copyto!(xs[t][w],workspace[w])
                t > 1 && applybinchaos!(xs[t][w], c.shakeupChaos, c.lastBeacon, vmap)
            end
        end
    end
end





"Main function."
function go(c::Config)
    base = c.terrain
    vmap = validitymap(base)
    x = genchaoslist(base, c.initialChaos, c.chaosWidth, c.lastBeacon, vmap)
    best = copy(x[1])
    worst = 0
    grace = 0
    bestbest = copy(x[1])
    while true
        x = beambests(x, c.beamWidth, c.lastBeacon, vmap)
        if x[1].score > best.score
            grace = 0
            best = copy(x[1])
            println(best.score,"-",x[end].score)
        else
            if x[end].score > worst
                worst = x[end].score
                grace = 0
                println("Improving low results ", worst)
            else
                if grace < 10
                    grace += 1
                    println("Grace period ",best.score,"-",worst)
                else
                    print("Emergency reseed")
                    if (best.score > bestbest.score)
                        copyto!(bestbest,best)
                    end
                    draw(bestbest)
                    println(bestbest.score)
                    empty(x)
                    x = genchaoslist(
                        bestbest,
                        c.shakeupChaos,
                        c.chaosWidth,
                        c.lastBeacon,
                        vmap,
                    )
                    best = copy(x[1])
                    worst = 0
                    grace = 0
                end

            end
        end
    end
end

function test1()
    gothreaded(Config(9, 100, 100, 100, 5, terrainToMap(map3)))
end

function rebraneStyle()
    go(Config(9, 100, 1, 2000, 2000, terrainToMap(map1)))
end
