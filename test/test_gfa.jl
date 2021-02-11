@testset "Read GFA" begin
    g_test = SimpleDiGraph(7)
    add_edge!(g_test, 1, 2)
    add_edge!(g_test, 2, 3)
    add_edge!(g_test, 3, 4)
    add_edge!(g_test, 4, 5)
    add_edge!(g_test, 5, 6)
    add_edge!(g_test, 7, 2)
    w_test = [Weight(7, 10),
    Weight(4, 10),
    Weight(2, 44),
    Weight(3, 2),
    Weight(5, 1),
    Weight(6, 11),
    Weight(1, 2)
    ]
    l_test = [NodeLabel(7, "4\t-", "TACAGGGTGA", ""),
    NodeLabel(4, "4\t+", "TACAGGGTGA", ""),
    NodeLabel(2, "2\t+", "TTAACTCCATCTTTGAGAAACATTTAATAATGTAATGTGTTTGT", ""),
    NodeLabel(3, "3\t+", "CA", ""),
    NodeLabel(5, "5\t+", "A", ""),
    NodeLabel(6, "6\t+", "TACAGATGCAC", ""),
    NodeLabel(1, "1\t+", "AT", "")
    ]
    e_test = [EdgeLabel("2\t+", "3\t+", "0M", ""),
    EdgeLabel("4\t-", "2\t+", "0M", ""),
    EdgeLabel("1\t+", "2\t+", "0M", ""),
    EdgeLabel("5\t+", "6\t+", "0M", ""),
    EdgeLabel("4\t+", "5\t+", "0M", ""),
    EdgeLabel("3\t+", "4\t+", "0M", "")
    ]
    g, l, w, e = read_from_gfa("data/gfa_sample_1.gfa");
    @test g == g_test
    @test w == w_test
    @test e == e_test
    @test l == l_test
end