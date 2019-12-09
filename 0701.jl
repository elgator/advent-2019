using DelimitedFiles
filename = "./data/input07.txt"

function load_prog(name)
    prog = Int
    open(name) do file
        prog = readdlm(file, ',', Int)
    end
    return prog
end

mutable struct ProgStream
    words::Array{Int}
    instr_addr::Int
    input::Vector{Int}
    output::Vector{Int}
    state::Symbol # :wait, :halt, :run
end

ProgStream(words::Array{Int}, instr_addr::Int) = ProgStream(words::Array{Int}, instr_addr::Int, [], [], :run)

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
    # print("comm: ",progS.instr_addr-1,":", comm, " ", op1Mode, op2Mode, op3Mode, "\n")

    if comm == 99

        return -1

    elseif comm == 1 || comm == 2 # ADD | MULT
        op1 = readOperand(progS, op1Mode)
        op2 = readOperand(progS, op2Mode)
        addr_new = readWord(progS) + 1

        res = if comm == 1
            # print("$op1 + $op2 @ $addr_new\n")
            op1 + op2
        else
            # print("$op1 * $op2 @ $addr_new\n")
            op1 * op2
        end
        progS.words[addr_new] = res
        return addr_new

    elseif comm == 3 # READ
        addr_new = readWord(progS) + 1
        if length(progS.input) == 0
            error("Read attempt from an empty input")
        else
            op1 = popfirst!(progS.input)
        end
        # print("read $op1 @ $addr_new\n")
        progS.words[addr_new] = op1
        return addr_new

    elseif comm == 4 # PRINT
        op1 = readOperand(progS, op1Mode)
        # print("read $op1 @ $op1_addr\n")
        # println("PRINT $op1")
        push!(progS.output, op1)
        return 0

    elseif comm == 5 # JIT
        op1 = readOperand(progS, op1Mode)
        addr = readOperand(progS, op2Mode) + 1
        op1 != 0 && jumpTo(progS, addr)
        return 0

    elseif comm == 6 # JIF
        op1 = readOperand(progS, op1Mode)
        addr = readOperand(progS, op2Mode) + 1
        op1 == 0 && jumpTo(progS, addr)
        return 0

    elseif comm == 7 # LESS THAN
        op1 = readOperand(progS, op1Mode)
        op2 = readOperand(progS, op2Mode)
        addr_new = readWord(progS) + 1

        res = if op1 < op2 1 else 0 end
        progS.words[addr_new] = res
        return addr_new

    elseif comm == 8 # EQUALS
        op1 = readOperand(progS, op1Mode)
        op2 = readOperand(progS, op2Mode)
        addr_new = readWord(progS) + 1

        res = if op1 == op2 1 else 0 end
        progS.words[addr_new] = res
        return addr_new

    else
        error("unknown command as input: $comm")
    end
end

writeToComp(progS::ProgStream, input) = push!(progS.input, input)
readFromComp(progS::ProgStream) = popfirst!(progS.output)


function run(progS)
    while true
        exitCode = get_command(progS)
        #println(addr)
        exitCode == -1 && break
    end
    #println(p)
    return progS
end

function assembly(input)
    input = copy(input)
    p = load_prog(filename)
    println("===============================")
    # test cases

    # p = [3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0]
    # p = [3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0]
    # p = [3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0]
    # set up
    computers = [progS = ProgStream(copy(p), 1) for x in 1:5]
    for comp in computers # write phases
        writeToComp(comp, popfirst!(input))
    end
    signal = 0
    # calculations
    for comp in computers
        writeToComp(comp, signal) #assuming signal is a single value
        run(comp)
        signal = readFromComp(comp)
        println("signal $signal")
    end
    println(signal)
    return signal
end

function checkPhases()
    maxPower = 0
    phases = Set([0, 1, 2, 3, 4])
    bestPhases = [0, 0, 0, 0, 0]
    for i in phases
        for j in setdiff(phases, i)
            for k in setdiff(phases, [i, j])
                for l in setdiff(phases, [i, j, k])
                    phaseSet = [i, j, k, l, pop!(setdiff(phases, [i, j, k, l]))]
                    power = assembly(phaseSet)
                    if power > maxPower
                        maxPower = power
                        bestPhases = phaseSet
                    end
                end
            end
        end
    end
    println("Best energy $maxPower at phases $bestPhases")
end

println("\n\nHello")
checkPhases()
println("Bye")
