function _weight_array_to_dict(w::Array{Weight}=Weight[])
    w_dict = Dict()
    for w_dummy::Weight in w
        w_dict[w_dummy.node] = w_dummy.weight
    end
    return w_dict
end

function _label_map_array_to_dict(l::Array{NodeLabel}=NodeLabel[])
    l_dict = Dict()
    for l_dummy::NodeLabel in l
        l_dict[l_dummy.node] = l_dummy.label
    end
    return l_dict
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