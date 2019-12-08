using DelimitedFiles
filename = "./data/input06.txt"

function load_orbits(name)
    orbits = []
    open(name) do file
        orbits = readdlm(file, ')', String)
    end
    return orbits
end

mutable struct TreeNode
    parent::String
    children::Vector{String}
    hopsFromRoot::Int
end

struct Tree
    nodes::Dict{String, TreeNode}
end

Tree() = Tree(Dict())
TreeNode() = TreeNode("", [], 0)

function addBranch(tree::Tree, idParent::String, idChild::String)
    haskey(tree.nodes, idParent) || push!(tree.nodes, idParent => TreeNode())
    haskey(tree.nodes, idChild) || push!(tree.nodes, idChild => TreeNode())
    push!(tree.nodes[idParent].children, idChild)
    tree.nodes[idChild].parent = idParent
end

children(tree, id) = tree.nodes[id].children
parent(tree, id) = tree.nodes[id].parent

function findRoot(tree::Tree)
    rootId = ""
    for (k,v) in tree.nodes
        v.parent == "" && (rootId = k; break)
    end
    return rootId
end

orbits = load_orbits(filename)
orbitsTree = Tree()

for (center, orbiter) in eachrow(orbits)
    println("adding $center ) $orbiter")
    addBranch(orbitsTree, center, orbiter)
end
root = findRoot(orbitsTree)
println("The root is: ", root)

function countHops(tree::Tree, nodeId::String, hopsAlready::Int)

    tree.nodes[nodeId].hopsFromRoot = hopsAlready
    hops = hopsAlready
    for childNode in children(tree, nodeId)
        hops += countHops(tree, childNode, hopsAlready + 1)
    end
    return hops
end

println("Total hops: ", countHops(orbitsTree, root, 0))
