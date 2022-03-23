# BioGraph.jl
[![Latest Release](https://img.shields.io/github/v/release/nguyetdang/BioGraph.jl)](https://github.com/nguyetdang/BioGraph.jl/releases/latest)
[![Build Status](https://img.shields.io/github/workflow/status/nguyetdang/BioGraph.jl/ci_test/main)](https://github.com/nguyetdang/BioGraph.jl/actions?query=workflow%3Aci_test+branch%3Amain)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://nguyetdang.github.io/BioGraph.jl/stable)
[![MIT license](https://img.shields.io/github/license/nguyetdang/BioGraph.jl)](https://github.com/nguyetdang/BioGraph.jl/blob/main/LICENSE)

## Description

BioGraph is a Julia package for handle genome graph in the GFA format. It reads information from GFA input, extract simple bidirected graphs and find the longest linear path in those graphs.

[Complete documentation is available here](https://nguyetdang.github.io/BioGraph.jl/stable)

## Installation instruction
BioGraph.jl works at Julia LTS release v1.6.5 that can be downloaded at [https://julialang.org/downloads/](https://julialang.org/downloads/). It works also on Julia v1.7 but has not been extensively tested on it.

To install BioGraph.jl the latest stable versions of BioGraph.jl, type in Julia

```julia
] add https://github.com/nguyetdang/BioGraph.jl
```

To install optimizers that help accelerate BioGraph.jl, please follow the corresponding installation instruction and add the optimizer in Julia. You can choose one of the following optimizers:
* [CPLEX Optimizer (available for academic use)](https://www.ibm.com/products/ilog-cplex-optimization-studio)
* [Gurobi Optimization (available for academic use)](https://www.gurobi.com/downloads/end-user-license-agreement-academic/)
* [Cbc Optimizer (open-source)](https://github.com/coin-or/Cbc)

To add these optimizers, type in Julia corresponding lines:
```julia
] add CPLEX
] add Gurobi
] add Cbc
```

To use BioGraph with Jupyter Notebook, please install [IJulia.jl](https://github.com/JuliaLang/IJulia.jl)
```julia
] add IJulia
] build IJulia
```
A jupyter book is provided in this github to test BioGraph.jl

## How to use BioGraph.jl

First, load the packages (Cbc Optimizer will be use in this example)
```julia
using BioGraph, Cbc
```

Then, read the gfa input with or without weight value
```julia
gfa = BioGraph.read_from_gfa("gfa_sample_1.gfa", weight_file="weight.csv")
```

Find the different graph components (output may be long)
```julia
graph_component = find_graph_component(gfa)
```

The length of graph_components indicates how many single graphs are availalbe in a GFA file. To find the longest path of a single graph, please indicate the index corresponding to that graph.
E.g. to obtain the longest path of the graph 1, type:
```julia
longest_path_1 = find_longest_path(graph_component.graph[1], Cbc.Optimizer, is_weighted = true)
```

To output the longest path in FASTA and BED formats at current folder. Otherwise, provide the path to output directory:
```julia
get_fasta(longest_path_1, header="Graph1", outdir="./")
```
