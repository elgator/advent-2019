using DataStructures
filename = "./data/input08.txt"
xsize = 25
ysize = 6

function readImage()
    imageBytes=0
    open(filename) do file
            imageBytes = map(x->parse(Int, x), split(readline(file), ""))
    end
    layers = Int(length(imageBytes) / xsize / ysize)
    image = reshape(imageBytes, (xsize, ysize, layers))

    return image
end

img = readImage()
# df = DataFrame(transpose(i))
counts = [counter(layer) for layer in eachslice(img, dims=3)]

minidx = argmin(map(x->x[0], counts))
println(counts[minidx][1] * counts[minidx][2])

function digPixel(img, x, y)
    color = nothing
    for z in 1:100
        if img[x, y, z] != 2
            c = img[x, y, z]
            color = (c == 0) ? "█" : " "
            break
        end
    end
    return color
end

function digAllPixels(img)
    processed = Array{String}(undef, xsize, ysize)
    for x = 1:xsize
        for y = 1:ysize
            processed[x, y] = digPixel(img, x, y)
        end
    end
    return processed
end

println("\n\n\nHi\n\n")
for row in eachcol(digAllPixels(img))
    for c in row
        print(c)
    end
    println()
end
println("\n\n\n")
