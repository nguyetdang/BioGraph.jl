"""
    read_from_gfa(filename::String; weight_file::String)

Read graph from GFA file and optional weight_file (contains two column `node` and `weight`) and return `GFAResult` struct which 
has `g` - the graph, `w` - weight array, `l` - node label array, `e` - edge label array and `p` - path array.
"""
function read_from_gfa(filename::String; weight_file::String="")
    u = readlines(filename);
    l_dict = Dict()
    w_dict = Dict()
    l_w_dict = Dict()
    l_s_dict = Dict()
    l_i_dict = Dict()
    links = Tuple[]
    e_o_dict = Dict()
    e_i_dict = Dict()
    p_dict = Dict()
    p::Array{Path} = Path[]

    if weight_file != ""
        w_f_dict = Dict()
        f = CSV.File(weight_file)
        for row in f
            w_f_dict[string(row.node)] = row.weight
        end
    end

    i = 1
    for line in u
        if line[1] == 'S'
            s_dummy = split(line, "\t")
            l_dict[i] = s_dummy[2] * "\t+"
            if weight_file != ""
                w_dict[i] = w_f_dict[s_dummy[2]]
            else
                w_dict[i] = length(s_dummy[3])
            end
            l_w_dict[l_dict[i]] = w_dict[i]
            l_w_dict[s_dummy[2] * "\t-"] = 0
            l_s_dict[l_dict[i]] = s_dummy[3]
            l_i_dict[l_dict[i]] = SubString(line, length(s_dummy[1] * "\t" * s_dummy[2] * "\t" * s_dummy[3] * "\t") + 1)
            i += 1
        elseif line[1] == 'L'
            l_dummy = split(line, "\t")
            k_start = l_dummy[2] * "\t" * l_dummy[3]
            if l_dummy[3] == "-"
                if l_w_dict[l_dummy[2] * "\t" * l_dummy[3]] == 0
                    l_dict[i] = l_dummy[2] * "\t-"
                    w_dict[i] = l_w_dict[l_dummy[2] * "\t+"]
                    l_w_dict[l_dict[i]] = w_dict[i]
                    l_s_dict[l_dict[i]] = l_s_dict[l_dummy[2] * "\t+"]
                    l_i_dict[l_dict[i]] = l_i_dict[l_dummy[2] * "\t+"]
                    i += 1
                end
            end
            k_end = l_dummy[4] * "\t" * l_dummy[5]
            if l_dummy[5] == "-"
                if l_w_dict[l_dummy[4] * "\t" * l_dummy[5]] == 0
                    l_dict[i] = l_dummy[4] * "\t-"
                    w_dict[i] = l_w_dict[l_dummy[4] * "\t+"]
                    l_w_dict[l_dict[i]] = w_dict[i]
                    l_s_dict[l_dict[i]] = l_s_dict[l_dummy[4] * "\t+"]
                    l_i_dict[l_dict[i]] = l_i_dict[l_dummy[4] * "\t+"]
                    i += 1
                end
            end
            e_name = k_start * "::" * k_end
            e_o_dict[e_name] = l_dummy[6]
            e_i_dict[e_name] = SubString(line, length(l_dummy[1] * "\t" * l_dummy[2] * "\t" * l_dummy[3] * "\t" * l_dummy[4] * "\t" * l_dummy[5] * "\t" * l_dummy[6] * "\t") + 1)
            push!(links, (k_start, k_end))
        elseif line[1] == 'P'
            p_dummy = split(line, "\t")
            path_name = p_dummy[2]
            p_extract = split(p_dummy[3], ",")
            p_arr = []
            for i = 1:(length(p_extract))
                last_char = p_extract[i][length(p_extract[i])]
                extracted = chop(p_extract[i])
                extracted = extracted * "\t" * last_char
                push!(p_arr, extracted)
            end
            p_dict[path_name] = p_arr
        end
    end

    w = _weight_from_dict(w_dict)
    l = _label_from_dict(l_dict, l_s_dict, l_i_dict)
    e = _edge_label_from_dict(e_o_dict, e_i_dict)

    g = SimpleDiGraph(length(w))

    reverse_l_dict = Dict(value => key for (key, value) in l_dict)

    for link in links
        add_edge!(g, reverse_l_dict[link[1]], reverse_l_dict[link[2]])
    end

    for (name, p_arr) in p_dict
        path = []
        for i = 1:length(p_arr)
            push!(path, reverse_l_dict[p_arr[i]])
        end
        push!(p, Path(name, path))
    end
    if weight_file != ""
        return GFAResult(g, w, l, e, p, false)
    else
        return GFAResult(g, w, l, e, p, false)
    end
end