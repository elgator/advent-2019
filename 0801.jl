using DataStructures
filename = "./data/input08.txt"

function readImage()
    xsize = 25
    ysize = 6
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
