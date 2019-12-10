using DelimitedFiles
filename = "./data/input09.txt"

function load_prog(name)
    prog = Int
    open(name) do file
        prog = readdlm(file, ',', Int)
    end
    prog = vec(prog)
    return prog
end

mutable struct ProgStream
    words::Array{Int}
    instr_addr::Int
    input::Vector{Int}
    output::Vector{Int}
    state::Symbol # :wait, :halt, :run
    rel_base::Int
end

ProgStream(words::Array{Int}, instr_addr::Int) = ProgStream(words::Array{Int}, instr_addr::Int, [], [], :run, 0)

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
    allowed = [0, 1, 2]
    if nums[4] * 10 + nums[5] != 99 && !(nums[3] in allowed) && !(nums[2] in allowed) && !(nums[1] == 1 in allowed)
        error("Wrong mode bit for command $comm")
    end
    return nums[4] * 10 + nums[5], nums[3], nums[2], nums[1]
end

function readOperand(progS, opMode)
    addr = readWord(progS)
    if opMode == 0
        return readFromAddress(progS, addr + 1) # indirect
    elseif opMode == 2
        return readFromAddress(progS, progS.rel_base + addr + 1) # relative
    else
        return addr # immediate
    end
end

function readAddress(progS, opMode)
    addr = readWord(progS)
    if opMode == 0
        return addr # indirect
    elseif opMode == 2
        return progS.rel_base + addr # relative
    else
        return addr # immediate
    end
end


function extendToAddress!(progS::ProgStream, addr::Int)
    addition = zeros(Int, addr - length(progS.words))
    append!(progS.words, addition)
end

function readFromAddress(progS::ProgStream, addr::Int)
    addr > length(progS.words) && extendToAddress!(progS, addr)
    return progS.words[addr]
end

function writeToAddress(progS::ProgStream, addr::Int, op::Int)
    addr > length(progS.words) && extendToAddress!(progS, addr)
    progS.words[addr] = op
    return
end

function get_command(progS)
    if progS.state == :wait
        comm = 3 # waits are always on READ
    else
        comm = readWord(progS)
        comm, op1Mode, op2Mode, op3Mode = parseCommand(comm)
    end
    #print(p, "\n")
    # a = "$(progS.instr_addr-1)"
    # length(a) < 3 && (a = "0"^(3-length(a)) * a) # force address length = 3
    # print("comm: ", a,":", comm, " ", op1Mode, op2Mode, op3Mode, " ", progS.rel_base)
    # print(" 63:$(progS.words[64]):$(progS.words[65])")

    # length(progS.words) > 1000 && print(" 1000:$(progS.words[1001])")
    # for i = 1001:1030
    #     length(progS.words) > i && print(":$(progS.words[i+1])")
    # end

    if comm == 99
        progS.state = :halt
        # println(" HLT")
        return

    elseif comm == 1 || comm == 2 # ADD | MULT
        op1 = readOperand(progS, op1Mode)
        op2 = readOperand(progS, op2Mode)
        addr_new = readAddress(progS, op3Mode) + 1

        res = if comm == 1
            # println(" ADD $op1 $op2 -> $(addr_new-1)")
            op1 + op2
        else
            # println(" MUL $op1 $op2 -> $(addr_new-1)")
            op1 * op2
        end
        writeToAddress(progS, addr_new, res)
        return

    elseif comm == 3 # READ
        if length(progS.input) == 0
            progS.state = :wait
            return
        else
            addr_new = readAddress(progS, op1Mode) + 1
            op1 = popfirst!(progS.input)
            progS.state = :run
            writeToAddress(progS, addr_new, op1)
            # println(" READ $op1 -> $(addr_new-1)")
            return
        end

    elseif comm == 4 # PRINT
        op1 = readOperand(progS, op1Mode)
        push!(progS.output, op1)
        # println(" WRT $op1")
        return

    elseif comm == 5 # JIT
        op1 = readOperand(progS, op1Mode)
        addr = readOperand(progS, op2Mode) + 1
        op1 != 0 && jumpTo(progS, addr)
        # println(" JIT $op1 -> $(addr-1)")
        return

    elseif comm == 6 # JIF
        op1 = readOperand(progS, op1Mode)
        addr = readOperand(progS, op2Mode) + 1
        op1 == 0 && jumpTo(progS, addr)
        # println(" JIF $op1 -> $(addr-1)")
        return

    elseif comm == 7 # LESS THAN
        op1 = readOperand(progS, op1Mode)
        op2 = readOperand(progS, op2Mode)
        addr_new = readAddress(progS, op3Mode) + 1

        res = if op1 < op2 1 else 0 end
        writeToAddress(progS, addr_new, res)
        # println(" LST $op1 $op2 -> $(addr_new-1)")
        return

    elseif comm == 8 # EQUALS
        op1 = readOperand(progS, op1Mode)
        op2 = readOperand(progS, op2Mode)
        addr_new = readAddress(progS, op3Mode) + 1

        res = if op1 == op2 1 else 0 end
        writeToAddress(progS, addr_new, res)
        # println(" EQL $op1 $op2 -> $(addr_new-1)")
        return

    elseif comm == 9 # MODIFY REL
        op1 = readOperand(progS, op1Mode)
        progS.rel_base += op1
        # println(" REL $op1")
        return
    else
        error("unknown command as input: $comm")
    end
end

writeToComp(progS::ProgStream, input) = push!(progS.input, input)
readFromComp(progS::ProgStream) = popfirst!(progS.output)


function run(progS)
    while true
        get_command(progS)
        if progS.state == :halt || progS.state == :wait
            break
        end
    end
    return progS
end

function assembly(input)
    input = copy(input)
    p = load_prog(filename)
    println("===============================")
    # test cases

    # p = [109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99]
    # p = [1102,34915192,34915192,7,4,7,99,0]
    # p = [104,1125899906842624,99]

    # set up
    comp = ProgStream(copy(p), 1)
    writeToComp(comp, input)
    run(comp)
    signal = comp.output
    println("E signal ", signal)
    return signal
end



println("\n\nHello")
assembly(2)
println("Bye")
