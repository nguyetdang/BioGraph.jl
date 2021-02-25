"""
    find_graph_component(gfa_result::BioGraph.GFAResult)

Return graph components of `GFAResult`:

- Simple Graphs
- Lone Cycles
- Lone Nodes
"""
function find_graph_component(gfa_result::GFAResult)
    source_nodes::Array{Int64} = Int64[]
    sink_nodes::Array{Int64} = Int64[]
    start_nodes::Array{Int64} = Int64[]
    end_nodes::Array{Int64} = Int64[]

    g = gfa_result.g
    w = gfa_result.w
    l = gfa_result.l
    e = gfa_result.e
    p = gfa_result.p

    l_dict, l_s_dict, l_i_dict = _label_map_array_to_dict(l)
    w_dict = _weight_array_to_dict(w)
    e_o_dict, e_i_dict = _edge_label_array_to_dict(e)
    
    for e::AbstractEdge in edges(g)
        push!(start_nodes, e.src) 
        push!(end_nodes, e.dst)   
    end

    sink_nodes = collect(intersect(setdiff!(Set(1:nv(g)), Set(start_nodes)), Set(end_nodes)))
    source_nodes = collect(intersect(setdiff!(Set(1:nv(g)), Set(end_nodes)), Set(start_nodes)))

    g_com = weakly_connected_components(g)
    
    graphs = GraphComponent()
    graphs.lone_node = []
    graphs.lone_cycle = []
    graphs.graph = []
    for com in g_com
        if length(com) == 1
            g_dummy = GraphResult()
            sg, vmap = induced_subgraph(g, com)
            g_dummy.edge_label = []
            g_dummy.g = sg
            g_dummy.path = []
            if l == []
                g_dummy.node_label = [NodeLabel(1, string(vmap[1]), "", "")]
                g_dummy.source_node = [NodeLabel(1, string(vmap[1]), "", "")]
                g_dummy.sink_node = [NodeLabel(1, string(vmap[1]), "", "")]
            else
                g_dummy.node_label = [NodeLabel(1, l_dict[vmap[1]], l_s_dict[vmap[1]], l_i_dict[vmap[1]])]
                g_dummy.source_node = [NodeLabel(1, l_dict[vmap[1]], l_s_dict[vmap[1]], l_i_dict[vmap[1]])]
                g_dummy.sink_node = [NodeLabel(1, l_dict[vmap[1]], l_s_dict[vmap[1]], l_i_dict[vmap[1]])]
            end
            if w == []
                g_dummy.weight = [Weight(1, 1)]
            else
                g_dummy.weight = [Weight(1, w_dict[vmap[1]])]
            end
            g_dummy.sg_map = [SubGraphMap(1, vmap[1])]
            push!(graphs.lone_node, g_dummy)
        else
            sg_source = collect(intersect(Set(source_nodes), Set(com)))
            sg_sink = collect(intersect(Set(sink_nodes), Set(com)))
            g_dummy = GraphResult()
            sg, vmap = induced_subgraph(g, com)
            g_dummy.g = sg
            g_dummy.sg_map = []
            for i in 1:nv(sg)
                push!(g_dummy.sg_map, SubGraphMap(i, vmap[i]))
            end
            sg_dict = _sg_map_array_to_dict(g_dummy.sg_map)
            reverse_sg_dict = Dict(value => key for (key, value) in sg_dict)


            g_dummy.node_label = []
            g_dummy.source_node = []
            g_dummy.sink_node = []
            g_dummy.weight = []
            g_dummy.edge_label = []
            g_dummy.path = []

            if p != []
                for p_dummy in p
                    if p_dummy.path[1] in vmap
                        p_arr = []
                        for p_index in p_dummy.path
                            push!(p_arr, reverse_sg_dict[p_index])
                        end
                        push!(g_dummy.path, Path(p_dummy.name,p_arr))
                    end
                end
            end

            if l == []
                for i in 1:nv(sg)
                    push!(g_dummy.node_label, NodeLabel(i, string(vmap[i]), "", ""))
                end
                for source_node in sg_source
                    push!(g_dummy.source_node, NodeLabel(reverse_sg_dict[source_node], string(vmap[reverse_sg_dict[source_node]]), "", ""))
                end
                for sink_node in sg_sink
                    push!(g_dummy.sink_node, NodeLabel(reverse_sg_dict[sink_node], string(vmap[reverse_sg_dict[sink_node]]), "", ""))
                end
            else
                for i in 1:nv(sg)
                    push!(g_dummy.node_label, NodeLabel(i, l_dict[vmap[i]], l_s_dict[vmap[i]], l_i_dict[vmap[i]]))
                end
                for source_node in sg_source
                    push!(g_dummy.source_node, NodeLabel(reverse_sg_dict[source_node], l_dict[vmap[reverse_sg_dict[source_node]]], l_s_dict[vmap[reverse_sg_dict[source_node]]], l_i_dict[vmap[reverse_sg_dict[source_node]]]))
                end
                for sink_node in sg_sink
                    push!(g_dummy.sink_node, NodeLabel(reverse_sg_dict[sink_node], l_dict[vmap[reverse_sg_dict[sink_node]]], l_s_dict[vmap[reverse_sg_dict[sink_node]]], l_i_dict[vmap[reverse_sg_dict[sink_node]]]))
                end
            end
            if w == []
                for i in 1:nv(sg)
                    push!(g_dummy.weight, Weight(i, 1))
                end
            else
                for i in 1:nv(sg)
                    push!(g_dummy.weight, Weight(i, w_dict[vmap[i]]))
                end
            end
            if e == []
                for edge in edges(sg)
                    push!(g_dummy.edge_label, EdgeLabel(string(sg_dict[edge.src]), string(sg_dict[edge.dst]), "", ""))
                end
            else
                for edge in edges(sg)
                    e_name = l_dict[sg_dict[edge.src]] * "::" * l_dict[sg_dict[edge.dst]]
                    push!(g_dummy.edge_label, EdgeLabel(l_dict[sg_dict[edge.src]], l_dict[sg_dict[edge.dst]], e_o_dict[e_name], e_i_dict[e_name]))
                end
            end
            if sg_sink == [] || sg_source == []
                push!(graphs.lone_cycle, g_dummy)
            else
                push!(graphs.graph, g_dummy)
            end
        end
    end

    return graphs
end

"""
    get_summary(g_coms::BioGraph.GraphComponent)

Summary of `GraphComponent`.
"""
function get_summary(g_coms::GraphComponent)
    println("No of simple graphs: " * string(length(g_coms.graph)))
    println("No of lone cycles: " * string(length(g_coms.lone_cycle)))
    println("No of lone nodes: " * string(length(g_coms.lone_node)))
end

"""
    get_summary(g_coms::BioGraph.GraphResult)

Summary of `GraphResult`:

- No of vertices
- No of edges
- No of source nodes
- No of end nodes
- No of path
"""
function get_summary(g_result::GraphResult)
    println("No of vertices: " * string(nv(g_result.g)))
    println("No of edges: " * string(ne(g_result.g)))
    println("No of source_node: " * string(length(g_result.source_node)))
    println("No of sink_node: " * string(length(g_result.sink_node)))
    println("No of path: " * string(length(g_result.path)))
end

"""
    get_terminus(g_result::BioGraph.GraphResult; outfile::String)

Get all source and sink nodes of `GraphResult`. Write to CSV, including data from GFA.
"""
function get_terminus(g_result::GraphResult; outfile::String="")
    if outfile != ""
        sink_name = outfile * "_sink_node.csv"
        source_name = outfile * "_source_node.csv"
        open(sink_name, "w") do io
            write(io, "Label,Direction,Sequence,Information" * "\n")
            for node in g_result.sink_node
                s_dummy = split(node.label, "\t")
                write(io, s_dummy[1] * "," * s_dummy[2] * "," * node.sequence * "," * node.info * "\n")
            end
        end
        open(source_name, "w") do io
            write(io, "Label,Direction,Sequence,Information" * "\n")
            for node in g_result.source_node
                s_dummy = split(node.label, "\t")
                write(io, s_dummy[1] * "," * s_dummy[2] * "," * node.sequence * "," * node.info * "\n")
            end
        end
    end

    println("Source node: ")
    for node in g_result.source_node
        println("Node: " * string(node.node) * "\tLabel: " * node.label)
    end
    println("Sink node: ")
    for node in g_result.sink_node
        println("Node: " * string(node.node) * "\tLabel: " * node.label)
    end
    return g_result.source_node, g_result.sink_node
end

"""
    get_gfa(g_result::BioGraph.GraphResult; outfile::String)

Get GFA output of `GraphResult`.
"""
function get_gfa(g_result::GraphResult; outfile::String)
    open(outfile, "w") do io
        write(io, "H\tVN:Z:1.0" * "\n")
        for node in g_result.node_label
            s_dummy = split(node.label, "\t")
            write(io, "S\t" * s_dummy[1] * "\t" * node.sequence * "\t" * node.info * "\n")
        end
        for edge in g_result.edge_label
            write(io, "L\t" * edge.src * "\t" * edge.dst * "\t" * edge.overlap * "\t" * edge.info * "\n")
        end
    end
end