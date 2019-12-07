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


function readWord(progS::ProgStream)
    word = progS.words[progS.instr_addr]
    progS.instr_addr += 1
    #println("read word $word")
    return word
end

function jumpTo(progS::ProgStream, addr) # no checks
    progS.instr_addr = addr
    return 0
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

function readOperand(progS, opMode)
    addr = readWord(progS)
    if opMode == 0
        return progS.words[addr + 1] # indirect
    else
        return addr # immediate
    end
end

function get_command(progS)
    comm = readWord(progS)
    comm, op1Mode, op2Mode, op3Mode = parseCommand(comm)
    #print(p, "\n")
    print("comm: ",progS.instr_addr-1,":", comm, " ", op1Mode, op2Mode, op3Mode, "\n")

    if comm == 99
        return 0, -1

    elseif comm == 1 || comm == 2 # ADD | MULT
        op1 = readOperand(progS, op1Mode)
        op2 = readOperand(progS, op2Mode)
        addr_new = readWord(progS) + 1

        if comm == 1
            # print("$op1 + $op2 @ $addr_new\n")
            return op1 + op2, addr_new
        else
            # print("$op1 * $op2 @ $addr_new\n")
            return op1 * op2, addr_new
        end

    elseif comm == 3 # READ
        addr_new = readWord(progS) + 1
        print("Enter a value: ")
        op1 = parse(Int64, chomp(readline())) # check for out of bounds is needed
        # print("read $op1 @ $addr_new\n")
        return op1, addr_new

    elseif comm == 4 # PRINT
        op1 = readOperand(progS, op1Mode)
        # print("read $op1 @ $op1_addr\n")
        println("PRINT $op1")
        return 0, 0

    elseif comm == 5 # JIT
        op1 = readOperand(progS, op1Mode)
        addr = readOperand(progS, op2Mode) + 1
        op1 != 0 && jumpTo(progS, addr)
        return 0, 0

    elseif comm == 6 # JIF
        op1 = readOperand(progS, op1Mode)
        addr = readOperand(progS, op2Mode) + 1
        op1 == 0 && jumpTo(progS, addr)
        return 0, 0

    elseif comm == 7 # LESS THAN
        op1 = readOperand(progS, op1Mode)
        op2 = readOperand(progS, op2Mode)
        addr_new = readWord(progS) + 1

        res = if op1 < op2 1 else 0 end
        return res, addr_new

    elseif comm == 8 # LESS THAN
        op1 = readOperand(progS, op1Mode)
        op2 = readOperand(progS, op2Mode)
        addr_new = readWord(progS) + 1

        res = if op1 == op2 1 else 0 end
        return res, addr_new

    else
        error("unknown command as input: $comm")
    end
end


function setup_program()
    p = load_prog(filename)
    #println("===============================")
    # test cass
    # p = [3,9,8,9,10,9,4,9,99,-1,8] # prints 1 if input == 8 or 0 otherwise
    # p = [3,9,7,9,10,9,4,9,99,-1,8] # prints 1 if input < 8 or 0 otherwise
    # p = [3,3,1108,-1,8,3,4,3,99] # prints 1 if input == 8 or 0 otherwise
    # p = [3,3,1107,-1,8,3,4,3,99] # prints 1 if input < 8 or 0 otherwise
    # p = [3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9] # tests input == 0 and prints 0 if true
    # p = [3,3,1105,-1,9,1101,0,0,12,4,12,99,1] # tests input == 0 and prints 0 if true
    # p = [3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99]
    # outputs 999 if the input value is below 8, outputs 1000 if the input value is equal to 8, or outputs 1001 if the input value is greater than 8.
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
    return
end


result = setup_program()
