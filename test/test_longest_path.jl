@testset "Longest Path" begin
    gfa_result = read_from_gfa("data/gfa_sample_1.gfa");
    res = find_graph_component(gfa_result);
    longest = find_longest_path(res.graph[1], Cbc.Optimizer, is_weighted = true);
    fasta = get_fasta(longest)
    longest_p_test = [7,2,3,4,5,6]
    longest_lp_test = ["4\t-","2\t+","3\t+","4\t+","5\t+","6\t+"]
    fasta_test = "TCACCCTGTATTAACTCCATCTTTGAGAAACATTTAATAATGTAATGTGTTTGTCATACAGGGTGAATACAGATGCAC"
    @test longest.path == longest_p_test
    @test longest.label_path == longest_lp_test
    @test fasta == fasta_test
    gfa_result_2 = read_from_gfa("data/gfa_sample_3.gfa");
    res_2 = find_graph_component(gfa_result_2);
    longest_2 = find_longest_path(res_2.graph[1], Cbc.Optimizer, is_weighted = false);
    fasta_2 = get_fasta(longest_2)
    longest_p_test_2 = [7,1,2,3,4,5,6]
    longest_lp_test_2 = ["4\t-","1\t+","2\t+","3\t+","4\t+","5\t+","6\t+"]
    fasta_test_2 = "TCACCCTGTAATTTAACTCCATCTTTGAGAAACATTTAATAATGTAATGTGTTTGTCATACAGGGTGAATACAGATGCAC"
    @test longest_2.path == longest_p_test_2
    @test longest_2.label_path == longest_lp_test_2
    @test fasta_2 == fasta_test_2
end
