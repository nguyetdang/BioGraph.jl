function find_longest_path(graph_result::GraphResult, optimizer_factory; has_cycle::Bool=false, is_weighted::Bool=true, source_node::Int64=0, sink_node::Int64=0)
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
    for e in edges(g)
        push!(array_e, e)
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

    g_opt = g

    obj = nv(g)

    println("Solving")
    i = 1
    if has_cycle == false
        while true
            for cycle in simplecycles_iter(g_opt, 100)
                cycle_dump = []
                for i in 1:length(cycle) - 1
                    for j in 1:length(array_e)
                        if array_e[j].src == cycle[i] && array_e[j].dst == cycle[i + 1]
                            push!(cycle_dump, j)
                        end
                    end
                end
                for j in 1:length(array_e)
                    if array_e[j].src == cycle[length(cycle)] && array_e[j].dst == cycle[1]
                        push!(cycle_dump, j)
                    end
                end
                push!(cycle_constraint, cycle_dump)
            end
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
                @constraint(model, sum(x[j] for j in cycle_constraint[i]) <= length(cycle_constraint[i]) - 1);
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
            length(simplecycles(g_opt)) > 0 || break
        end
    else
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
        optimize!(model);
        g_opt = SimpleDiGraph(nv(g))
        for i in 1:ne(g)
            if value(x[i]) >= 0.5
                add_edge!(g_opt, array_e[i].src, array_e[i].dst)
            end
        end
        obj = objective_value(model)
        println("objective: ", obj, ", num of cycle: ", length(simplecycles(g_opt)))
    end
    

    path = _g_opt_to_path(g_opt, source_nodes)
    label_path = _label_path(graph_result, path)
    return LongestPath(graph_result, g_opt, path, label_path, obj)
end

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