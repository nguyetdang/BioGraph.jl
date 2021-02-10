# Input Struct

struct Weight
    node::Int64
    weight::Int64
end

struct NodeLabel
    node::Int64
    label::String
    sequence::String
    info::String
end

struct EdgeLabel
    src::String
    dst::String
    overlap::String
    info::String
end