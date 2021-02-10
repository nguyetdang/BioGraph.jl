module TestBioGraph
using Test
using BioGraph
using BioGraph:
    Weight,
    NodeLabel,
    EdgeLabel
using LightGraphs
using Suppressor

include("test_gfa.jl")
include("test_graph_component.jl")

end