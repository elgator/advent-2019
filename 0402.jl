input = "109165-576723"

limitMin, limitMax = map(x->parse(Int64, x), split(input, '-'))
nums = [x for x = limitMin:limitMax]
function splitToDigits(x)
    mult = 100_000
    digits = Int64[]
    for i = 1:6
        d = x ÷ mult
        push!(digits, d)
        x = x - d * mult
        mult /= 10
    end
    return digits
end
nums = [splitToDigits(x) for x in nums]

adj(x) = (x[1] == x[2]) || (x[2] == x[3]) || (x[3] == x[4]) || (x[4] == x[5]) || (x[5] == x[6])
filter!(adj, nums)

inc(x) = (x[1] <= x[2]) && (x[2] <= x[3]) && (x[3] <= x[4]) && (x[4] <= x[5]) && (x[5] <= x[6])
filter!(inc, nums)

long(x) = ((x[1] == x[2] != x[3]) || (x[1] != x[2] == x[3] != x[4]) || (x[2] != x[3] == x[4] != x[5]) || (x[3] != x[4] == x[5] != x[6]) || (x[4] != x[5] == x[6]))
filter!(long, nums)

println(length(nums))
