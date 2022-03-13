# BioGraph Function

## Read GFA

```@docs
read_from_gfa
```

## Graph Component

```@docs
find_graph_component
get_summary(g_coms::BioGraph.GraphComponent)
get_summary(g_coms::BioGraph.GraphResult)
get_terminus(g_result::BioGraph.GraphResult; outfile::String)
get_gfa(g_result::BioGraph.GraphResult; outfile::String)
```

## Longest Path

```@docs
find_longest_path
get_gfa(g_result::BioGraph.LongestPath; outfile::String)
get_fasta(g_result::BioGraph.LongestPath; header::String="linear_path", outdir::String="")
```