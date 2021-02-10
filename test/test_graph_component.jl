@testset "Summary" begin
    g, l, w, e = read_from_gfa("data/gfa_sample_2.gfa")
    res = find_graph_component(g, l=l, w=w, e=e)
    result = @capture_out get_summary(res)
    s_test = "No of simple graphs: 2\nNo of lone cycles: 1\nNo of lone nodes: 1\n"
    @test result == s_test
    result_2 = @capture_out get_summary(res.graph[1])
    s_test_2 = "No of vertices: 5\nNo of edges: 4\nNo of source_node: 2\nNo of sink_node: 1\n"
    @test result_2 == s_test_2
    result_3 = @capture_out get_summary(res.lone_cycle[1])
    s_test_3 = "No of vertices: 3\nNo of edges: 3\nNo of source_node: 1\nNo of sink_node: 0\n"
    @test result_3 == s_test_3
    result_4 = @capture_out get_summary(res.lone_node[1])
    s_test_4 = "No of vertices: 1\nNo of edges: 0\nNo of source_node: 1\nNo of sink_node: 1\n"
    @test result_4 == s_test_4
end