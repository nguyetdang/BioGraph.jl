# Input Struct

struct Weight
    node::Int64
    weight::Int64
end

struct NodeLabel
    node::Int64
    label::String
    sequence::String
    info::String
end

struct EdgeLabel
    src::String
    dst::String
    overlap::String
    info::String
end

# Graph Component

struct SubGraphMap
    node::Int64
    master_node::Int64
end

mutable struct GraphResult
    g::SimpleDiGraph
    sg_map::Array{SubGraphMap}
    node_label::Array{NodeLabel}
    weight::Array{Weight}
    edge_label::Array{EdgeLabel}
    source_node::Array{NodeLabel}
    sink_node::Array{NodeLabel}
    GraphResult() = new()
end

mutable struct GraphComponent
    graph::Array{GraphResult}
    lone_node::Array{GraphResult}
    lone_cycle::Array{GraphResult}
    GraphComponent() = new()
end

# Longest Path

mutable struct LongestPath
    graph::GraphResult
    g_opt::SimpleDiGraph
    path::Array{Int64}
    label_path::Array{String}
    obj::Int64
end