function _weight_array_to_dict(w::Array{Weight}=Weight[])
    w_dict = Dict()
    for w_dummy::Weight in w
        w_dict[w_dummy.node] = w_dummy.weight
    end
    return w_dict
end

function _label_map_array_to_dict(l::Array{NodeLabel}=NodeLabel[])
    l_dict = Dict()
    l_s_dict = Dict()
    l_i_dict = Dict()
    for l_dummy::NodeLabel in l
        l_dict[l_dummy.node] = l_dummy.label
        l_s_dict[l_dummy.node] = l_dummy.sequence
        l_i_dict[l_dummy.node] = l_dummy.info
    end
    return l_dict, l_s_dict, l_i_dict
end

function _weight_from_dict(w_dict::Dict)
    w::Array{Weight} = Weight[]
    for (k, v) in w_dict
        push!(w, Weight(k, v))
    end
    return w
end

function _label_from_dict(l_dict::Dict, l_s_dict::Dict, l_i_dict::Dict)
    l::Array{NodeLabel} = NodeLabel[]
    for (k, v) in l_dict
        s = l_s_dict[v]
        i = l_i_dict[v]
        push!(l, NodeLabel(k, v, s, i))
    end
    return l
end

function _edge_label_from_dict(e_o_dict::Dict, e_i_dict::Dict)
    e::Array{EdgeLabel} = EdgeLabel[]
    for (k, v) in e_o_dict
        e_dummy = split(k, "::")
        s = e_dummy[1]
        d = e_dummy[2]
        o = v
        i = e_i_dict[k]
        push!(e, EdgeLabel(s, d, o, i))
    end
    return e
end

function _edge_label_array_to_dict(e::Array{EdgeLabel}=EdgeLabel[])
    e_o_dict = Dict() 
    e_i_dict = Dict()
    for e_dummy::EdgeLabel in e
        e_name = e_dummy.src * "::" * e_dummy.dst
        e_o_dict[e_name] = e_dummy.overlap
        e_i_dict[e_name] = e_dummy.info
    end
    return e_o_dict, e_i_dict
end

function _sg_map_array_to_dict(sg::Array{SubGraphMap}=SubGraphMap[])
    sg_dict = Dict()
    for sg_dummy::SubGraphMap in sg
        sg_dict[sg_dummy.node] = sg_dummy.master_node
    end
    return sg_dict
end

function _g_opt_to_path(g_opt::SimpleDiGraph, source_nodes::Array{Int64})
    dis_arr = []
    edges_arr = []
    for node in source_nodes
        edges = a_star(g_opt, node, nv(g_opt))
        push!(edges_arr, edges)
        push!(dis_arr, length(edges))
    end
    max_edges = edges_arr[findmax(dis_arr)[2]]
    path = Int64[]
    for e in max_edges
        push!(path, e.src)
    end
    return path
end

function _label_path(graph_result::GraphResult, path::Array{Int64})
    l_dict, l_s_dict, l_i_dict = _label_map_array_to_dict(graph_result.node_label)
    label_path = String[]
    for node in path
        push!(label_path, l_dict[node])
    end
    return label_path
end