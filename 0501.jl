using Printf
using DelimitedFiles
filename = "./data/input05.txt"
function load_prog(name)
    prog = Int8[]
    open(name) do file
        prog = readdlm(file, ',', Int64)
    end
    return prog
end

mutable struct ProgStream
    words::Array{Int64}
    instr_addr::Int64
end


function readWord(progS)
    word = progS.words[progS.instr_addr]
    progS.instr_addr += 1
    #println("read word $word")
    return word
end

function parseCommand(comm)
    commStr = "$comm"
    length(commStr) < 5 && (commStr = "0"^(5-length(commStr)) * commStr)  #add leading 0s for short comms
    nums = split(commStr, "")
    nums = map(x->parse(Int64, x), nums)
    #println(nums)
    #two last digits - opcode, other - position / immediate mode for operands
    if nums[4] * 10 + nums[5] != 99 && !(nums[3] == 1 || nums[3] == 0) && !(nums[2] == 1 || nums[2] == 0) && !(nums[1] == 1 || nums[1] == 0)
        error("Wrong mode bit for command $comm")
    end
    return nums[4] * 10 + nums[5], nums[3], nums[2], nums[1]
end


function get_command(progS)
    comm = readWord(progS)
    comm, op1Mode, op2Mode, op3Mode = parseCommand(comm)
    #print(p, "\n")
    print("comm: ",progS.instr_addr-1,":", comm, " ", op1Mode, op2Mode, op3Mode, "\n")

    if comm == 99
        return 0, -1
    elseif comm == 1 || comm == 2
        op1_addr = readWord(progS)
        op2_addr = readWord(progS)
        addr_new = readWord(progS) + 1

        op1 = if op1Mode == 0 progS.words[op1_addr + 1] else op1_addr end
        op2 = if op2Mode == 0 progS.words[op2_addr + 1] else op2_addr end


        if comm == 1
            # print("$op1 + $op2 @ $addr_new\n")
            return op1 + op2, addr_new
        else
            # print("$op1 * $op2 @ $addr_new\n")
            return op1 * op2, addr_new
        end
    elseif comm == 3
        addr_new = readWord(progS) + 1
        print("Enter a value: ")
        op1 = parse(Int64, chomp(readline())) # check for out of bounds is needed
        # print("read $op1 @ $addr_new\n")
        return op1, addr_new
    elseif comm == 4
        op1_addr = readWord(progS)
        op1 = if op1Mode == 0 progS.words[op1_addr + 1] else op1_addr end
        # print("read $op1 @ $op1_addr\n")
        println("PRINT $op1")
        return op1, 0
    else
        error("unknown command as input: $comm")
    end
end


function setup_program()
    p = load_prog(filename)
    #println("===============================")
    progS = ProgStream(p, 1)
    instr_addr = Int64(1)
    res = 0

    while true
        res, addr = get_command(progS)
        #println(addr)
        addr == -1 && break
        addr == 0 || (progS.words[addr] = res; )
    end
    #println(p)
    return p[1]
end


result = setup_program()
println("Result: $result")

# skip_ =  false
# for noun = 0:99
#     for verb = 0:99
#         print("trying $noun $verb ")
#         result = setup_program(noun, verb)
#         println(result)
#         if result == 19690720
#             println("noun $noun verb $verb submit $(noun *100 + verb)")
#             global skip_ = true
#         end
#         skip_ && break
#     end
#     skip_ && break
# end
