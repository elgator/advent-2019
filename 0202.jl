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
    #print(p, "\n")
    #print("comm: ", comm,"@", addr, "\n")

    if comm == 99
        return -1, -1
    elseif comm == 1 || comm == 2
        op1_addr = prog[addr+1] + 1
        op2_addr = prog[addr+2] + 1
        addr_new = prog[addr+3] + 1
        op1 = prog[op1_addr]
        op2 = prog[op2_addr]
        #print("$op1 + $op2 @ $addr_new\n")

        if comm == 1
            return op1 + op2, addr_new
        else
            return op1 * op2, addr_new
        end
    else
        error("unknown command as input: $comm")
    end
end

function setup_program(noun::Int64, verb::Int64)
    p = load_prog(filename)
    #println("===============================")
    prog_addr = Int64(1)
    res = 0
    p[2] = noun
    p[3] = verb
    while prog_addr <= length(p)
        res, addr = get_command(p, prog_addr)
        addr > 0 || break
        p[addr] = res
        prog_addr += 4
    end
    #println(p)
    return p[1]
end
skip_ =  false
for noun = 0:99
    for verb = 0:99
        print("trying $noun $verb ")
        result = setup_program(noun, verb)
        println(result)
        if result == 19690720
            println("noun $noun verb $verb submit $(noun *100 + verb)")
            global skip_ = true
        end
        skip_ && break
    end
    skip_ && break
end
