"""
    find_longest_path(graph_result::BioGraph.GraphResult, optimizer_factory; is_weighted::Bool, source_node::Int64, sink_node::Int64, has_path::String)

Find longest path in graph. Input:

- `GraphResult`
- JuMP optimizer_factory such as `CPLEX.Optimizer`
- `has_path`: optional string that indicates the path must have in longest path.
- `is_weighted`: if `true` find shortest path which is weighted
- `source_node`, `sink_node`: find longest path which has source and sink nodes.
"""
function find_longest_path(graph_result::GraphResult, optimizer_factory; 
    #has_cycle::Bool=false, 
    is_weighted::Bool=true, source_node::Int64=0, sink_node::Int64=0, has_path::String="")
    g = copy(graph_result.g)

    start_nodes = []
    end_nodes = []

    add_vertices!(g, 1)

    source_nodes::Array{Int64} = []
    for node in graph_result.source_node
        push!(source_nodes, node.node)
    end

    sink_nodes::Array{Int64} = []
    for node in graph_result.sink_node
        push!(sink_nodes, node.node)
    end

    println("Making graph")
    if sink_node > 0
        add_edge!(g, sink_node, nv(g))
    else
        for i in 1:nv(g)
            if i in sink_nodes
                add_edge!(g, i, nv(g))
            end
        end
    end

    array_e = []
    dict_e = Dict()
    dict_e_contraint = Dict()
    iter = 1
    for e in edges(g)
        push!(array_e, e)
        e_name = string(e.src) * "::" * string(e.dst)
        dict_e[e_name] = iter
        dict_e_contraint[iter] = 0
        iter += 1
    end

    w_dict = _weight_array_to_dict(graph_result.weight)

    weight_e = []
    for e in array_e
        if is_weighted
            push!(weight_e, w_dict[e.src])
        else
            push!(weight_e, 1)
        end
    end
    
    println("Add constraint")
    first_node_constraint = []
    if source_node > 0 
        for i in 1:length(array_e)
            if array_e[i].src == source_node
                push!(first_node_constraint, i)
            end
        end
    else
        for i in 1:length(array_e)
            if array_e[i].src in source_nodes
                push!(first_node_constraint, i)
            end
        end
    end
    
    end_node_constraint = []
    for i in 1:length(array_e)
        if array_e[i].dst == nv(g)
            push!(end_node_constraint, i)
        end
    end

    in_dict = Dict()
    out_dict = Dict()

    for i in 1:nv(g) - 1
        in_dict[i] = []
        out_dict[i] = []
    end

    for j in 1:length(array_e)
        if !(array_e[j].dst in source_nodes) && array_e[j].dst < nv(g)
            push!(in_dict[array_e[j].dst], j)
        end
        if !(array_e[j].src in source_nodes) && array_e[j].src < nv(g)
            push!(out_dict[array_e[j].src], j)
        end
    end
    
    cycle_constraint = []
    cycle_length_constraint = []

    path_constraint = []
    
    if has_path != ""
        dict_g = Dict()
        for i in 1:nv(g)
            dict_g[i] = 0
        end
        for p_dummy in graph_result.path
            if has_path == p_dummy.name
                p_arr = p_dummy.path
                for i in 1:(length(p_arr)-1)
                    e_name = string(p_arr[i]) * "::" * string(p_arr[i+1])
                    push!(path_constraint, dict_e[e_name])
                    dict_e_contraint[dict_e[e_name]] += 1
                    dict_g[p_arr[i+1]] += 1
                end
            end
        end
    end

    g_opt = SimpleDiGraph(nv(g))

    obj = nv(g)

    println("Solving")
    i = 1
    if has_path == ""
        while true
            model = Model();
            set_optimizer(model, optimizer_factory);
            set_silent(model)
            @variable(model, x[1:ne(g)], binary = true);
            @objective(model, Max, sum(x[i] * weight_e[i] for i = 1:ne(g)));
            @constraint(model, sum(x[i] for i in first_node_constraint) == 1);
            @constraint(model, sum(x[i] for i in end_node_constraint) == 1);
            for i in 1:nv(g) - 1
                @constraint(model, sum(x[j] for j in in_dict[i]) <= 1);
                @constraint(model, sum(x[j] for j in in_dict[i]) - sum(x[j] for j in out_dict[i]) == 0);
            end
            for i in 1:length(cycle_constraint)
                @constraint(model, sum(x[j] for j in cycle_constraint[i]) <= cycle_length_constraint[i] - 1);
            end
            optimize!(model);
            g_opt = SimpleDiGraph(nv(g))
            for i in 1:ne(g)
                if value(x[i]) >= 0.5
                    add_edge!(g_opt, array_e[i].src, array_e[i].dst)
                end
            end
            obj = objective_value(model)
            println("inter: ", i, ", objective: ", obj, ", num new cycle: ", length(simplecycles(g_opt)))
            i += 1
            for cycle in simplecycles_iter(g_opt, 100)
                cycle_dump = []
                push!(cycle_length_constraint, length(cycle))
                for j in 1:length(array_e)
                    if array_e[j].src in cycle && array_e[j].dst in cycle
                        push!(cycle_dump, j)
                    end
                end
                push!(cycle_constraint, cycle_dump)
            end
            length(simplecycles(g_opt)) > 0 || break
        end
    else
        while true
            model = Model();
            set_optimizer(model, optimizer_factory);
            set_silent(model)
            @variable(model, x[1:ne(g)], integer = true, lower_bound=0);
            @objective(model, Max, sum(x[i] * weight_e[i] for i = 1:ne(g)));
            @constraint(model, sum(x[i] for i in first_node_constraint) == 1);
            @constraint(model, sum(x[i] for i in end_node_constraint) == 1);
            for i in 1:ne(g)
                if dict_e_contraint[i] == 0
                    @constraint(model, x[i]  <= 1);
                else
                    @constraint(model, x[i]  == dict_e_contraint[i]);
                end
            end
            for i in 1:nv(g) - 1
                if dict_g[i] == 0
                    @constraint(model, sum(x[j] for j in in_dict[i]) <= 1);
                else
                    @constraint(model, sum(x[j] for j in in_dict[i]) == dict_g[i]);
                end
                @constraint(model, sum(x[j] for j in in_dict[i]) - sum(x[j] for j in out_dict[i]) == 0);
            end
            for i in 1:length(cycle_constraint)
                @constraint(model, sum(x[j] for j in cycle_constraint[i]) <= cycle_length_constraint[i] - 1);
            end
            optimize!(model);
            g_opt = SimpleDiGraph(nv(g))
            for i in 1:ne(g)
                if value(x[i]) >= 0.8
                    add_edge!(g_opt, array_e[i].src, array_e[i].dst)
                end
            end
            obj = objective_value(model)
            g_opt_com = weakly_connected_components(g_opt)
            lone_nodes = 0
            for com in g_opt_com
                if length(com) > 1
                    sg_source = collect(intersect(Set(source_nodes), Set(com)))
                    if length(sg_source) == 0
                        cycle_dump = []
                        push!(cycle_length_constraint, length(com));
                        for j in 1:length(array_e)
                            if array_e[j].src in com && array_e[j].dst in com
                                push!(cycle_dump, j)
                            end
                        end
                        if cycle_dump != []
                            push!(cycle_constraint, cycle_dump)
                        end
                    end
                else
                    lone_nodes+=1
                end
            end
            println("objective: ", obj, ", num of lone cycle: ", length(g_opt_com)-lone_nodes - 1)
            length(g_opt_com)-lone_nodes > 1 || break
        end
    end
    

    path = _g_opt_to_path(g_opt, source_nodes)
    label_path = _label_path(graph_result, path)
    return LongestPath(graph_result, g_opt, path, label_path, obj)
end

"""
    get_gfa(g_result::BioGraph.LongestPath; outfile::String)

Get GFA output of `LongestPath`.
"""
function get_gfa(longest_path::LongestPath; outfile::String)
    g_result = longest_path.graph
    lp_result = longest_path.label_path
    e_o_dict, e_i_dict = _edge_label_array_to_dict(g_result.edge_label)
    open(outfile, "w") do io
        write(io, "H\tVN:Z:1.0" * "\n")
        for node in g_result.node_label
            s_dummy = split(node.label, "\t")
            write(io, "S\t" * s_dummy[1] * "\t" * node.sequence * "\t" * node.info * "\n")
        end
        for edge in g_result.edge_label
            write(io, "L\t" * edge.src * "\t" * edge.dst * "\t" * edge.overlap * "\t" * edge.info * "\n")
        end
        PathName = "LongestPath"
        SegmentNames = ""
        for i in 1:length(lp_result)
            lp_dummy = split(lp_result[i], "\t")
            if i < length(lp_result)
                SegmentNames = SegmentNames * lp_dummy[1] * lp_dummy[2] * ","
            else
                SegmentNames = SegmentNames * lp_dummy[1] * lp_dummy[2]
            end
        end
        Overlaps = ""
        for i in 1:length(lp_result) - 1
            e_name = lp_result[i] * "::" * lp_result[i + 1]
            if i < length(lp_result) - 1
                Overlaps = Overlaps * e_o_dict[e_name] * ","
            else
                Overlaps = Overlaps * e_o_dict[e_name]
            end
        end
        write(io, "P\t" * PathName * "\t" * SegmentNames * "\t" * Overlaps)
    end
end

"""
    get_fasta(g_result::BioGraph.LongestPath; outfile::String)

Get FastA output of `LongestPath`.
"""
function get_fasta(longest_path::LongestPath; outfile::String="")
    g_result = longest_path.graph
    lp_result = longest_path.label_path
    l_dict, l_s_dict, l_i_dict = _label_map_array_to_dict(g_result.node_label)
    lp_dict = Dict()
    
    for i in 1:length(l_dict)
        lp_dummy = split(l_dict[i], "\t")
        if lp_dummy[2] == "-"
            lp_dict[l_dict[i]] = string(reverse_complement(LongDNASeq(l_s_dict[i])))
        else
            lp_dict[l_dict[i]] = l_s_dict[i]
        end
    end
    fasta_output = ""
    for label in lp_result
        fasta_output = fasta_output*lp_dict[label]
    end
    if outfile != ""
        open(outfile, "w") do io
            write(io, ">linear_path\n")
            write(io, fasta_output)
        end
    end
    return fasta_output
end