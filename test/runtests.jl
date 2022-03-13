module TestBioGraph
using Test
using BioGraph
using BioGraph:
    Weight,
    NodeLabel,
    EdgeLabel
using Graphs
using Suppressor
using Cbc

include("test_gfa.jl")
include("test_graph_component.jl")
include("test_longest_path.jl")

end