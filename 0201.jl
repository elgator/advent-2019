using Printf
using DelimitedFiles
filename = "./data/input0201.txt"
function load_prog(name)
    prog = Int8[]
    open(name) do file
        prog = readdlm(file, ',', Int64)
    end
    return prog
end

function get_command(prog, addr::Int64)
    comm = prog[addr]
    print(p, "\n")
    print("comm: ", comm,"@", addr, "\n")

    if comm == 99
        return -1, -1
    elseif comm == 1 || comm == 2
        op1_addr = prog[addr+1] + 1
        op2_addr = prog[addr+2] + 1
        addr_new = prog[addr+3] + 1
        op1 = prog[op1_addr]
        op2 = prog[op2_addr]
        print("$op1 + $op2 @ $addr_new\n")

        if comm == 1
            return op1 + op2, addr_new
        else
            return op1 * op2, addr_new
        end
    else
        error("unknown command as input: $comm")
    end
end

p = load_prog(filename)
#p = Int64[1,1,1,4,99,5,6,0,99]
println("===============================")
prog_addr = Int64(1)
res = 0
p[2]=12
p[3]=2
while prog_addr <= length(p)
    res, addr = get_command(p, prog_addr)
    addr > 0 || break
    global p[addr] = res

    global prog_addr += 4
end
print(p)
