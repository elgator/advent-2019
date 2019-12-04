using DelimitedFiles
filename = "./data/input0301.txt"

function loadWiresStr(filename)
    wire1 = String[]
    wire2 = String[]
    open(filename) do file
        wires = readdlm(file, ',', String)
        wire1, wire2 = wires[1, :], wires[2, :]
    end
    return wire1, wire2
end

function directionToVector(dirStr)
    # direction string "Xdddd" to vector (x, y)
    length = parse(Int64, dirStr[2:end])
    lead = dirStr[1]
    x = y = Int64(0)
    if lead == 'D' || lead == 'L'
        length *= -1
    end

    if lead == 'U' || lead == 'D'
        y = length
    elseif lead == 'R' || lead == 'L'
        x = length
    else
        error("Unknown direction: $lead")
    end

    return [x y]
end

function vectorsToSegments(vectors)
    segments = zeros(Int64, length(vectors), 5)
    x = y = len = 0
    for i = 1:length(vectors)
        segments[i, 1] = x
        segments[i, 2] = y
        x = segments[i, 3] = x + vectors[i][1]
        y = segments[i, 4] = y + vectors[i][2]
        len = segments[i, 5] = len + abs(vectors[i][1]) + abs(vectors[i][2])
    end
    return segments
end

function intersectSegments(vertSeg, horSeg)
    left = min(horSeg[1], horSeg[3])
    right = max(horSeg[1], horSeg[3])
    top = max(vertSeg[2], vertSeg[4])
    bottom = min(vertSeg[2], vertSeg[4])

    x = vertSeg[1] # x is constant for the vertical segment
    y = horSeg[2] # y

    #calculate excess wire to ends of the segments from the intersection
    excess = 0
    excess += abs(horSeg[3] - x)
    excess += abs(horSeg[4] - y)
    excess += abs(vertSeg[3] - x)
    excess += abs(vertSeg[4] - y)

    if left <= x <= right && bottom <= y <= top && (x != 0 || y != 0)
        print("intersect\n vert $vertSeg\n hor $horSeg\n at $x, $y\n")
        return [x, y, horSeg[5] + vertSeg[5] - excess]
    else
        return nothing
    end
end

function calcManhattanDist(vertice)
    return abs(vertice[1]) + abs(vertice[2])
end

function getLen(vertice)
    return vertice[3]
end

# test set 1 => 40
#wire1 = split("U7,R6,D4,L4", ',')
#wire2 = split("R8,U5,L5,D3", ',')

# test set 2 => 610
#wire1 = split("R75,D30,R83,U83,L12,D49,R71,U7,L72", ',')
#wire2 = split("U62,R66,U55,R34,D71,R55,D58,R83", ',')

# test set 3 => 410
#wire1 = split("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51", ',')
#wire2 = split("U98,R91,D20,R16,D67,R40,U7,R15,U6,R7", ',')


wire1, wire2 = loadWiresStr(filename)
#println(wire1, wire2)

wire1 = map(directionToVector, wire1)
wire2 = map(directionToVector, wire2)
wire1 = vectorsToSegments(wire1)
wire2 = vectorsToSegments(wire2)

#filter horizontal and vertical
wire1_vert = wire1[ wire1[:, 1] .== wire1[:, 3], :]
wire2_vert = wire2[ wire2[:, 1] .== wire2[:, 3], :]
wire1_hor = wire1[ wire1[:, 2] .== wire1[:, 4], :]
wire2_hor = wire2[ wire2[:, 2] .== wire2[:, 4], :]

intersects = []
for hor in eachrow(wire1_hor)
    for vert = eachrow(wire2_vert)
        vertice = intersectSegments(vert, hor)
        vertice == nothing || push!(intersects, vertice)
    end
end
for hor in eachrow(wire2_hor)
    for vert = eachrow(wire1_vert)
        vertice = intersectSegments(vert, hor)
        vertice == nothing || push!(intersects, vertice)
    end
end
println(intersects)
println(minimum(getLen, intersects))
