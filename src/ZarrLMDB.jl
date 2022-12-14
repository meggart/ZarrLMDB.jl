module ZarrLMDB

using LMDB: LMDB
using Zarr: AbstractStore, Zarr

struct LMDBStore <: AbstractStore
    d::LMDB.LMDBDict{String,Vector{UInt8}}
end
function LMDBStore(p::String; create = false, kwargs...)
    if create
        ispath(p) && throw(ArgumentError("Path at $p already exists"))
        mkpath(p)
    end
    LMDBStore(LMDB.LMDBDict{String,Vector{UInt8}}(p; kwargs...))
end
Base.show(io::IO,d::LMDBStore) = print(io,"LMDB Database at $(d.d.env.path)")

Base.getindex(d::LMDBStore, i::AbstractString) = get(d.d,i,nothing)
Base.setindex!(d::LMDBStore, v, i) = setindex!(d.d,v,i)
Base.delete!(d::LMDBStore,i) = delete!(d.d,i)
Zarr.storagesize(d::LMDBStore, p) = Int(LMDB.valuesize(d.d,prefix=p) - LMDB.valuesize(d.d,prefix=p*"/.zarray") - LMDB.valuesize(d.d,prefix=p*"/.zattrs"))
Zarr.isinitialized(d::LMDBStore, p) = haskey(d.d,p)
function listwholefolder(d::LMDBStore, p)
    if !isempty(p) && !endswith(p,'/')
        p = string(p,'/')
    end
    LMDB.list_dirs(d.d, prefix = p, sep='/')
end
function Zarr.subdirs(d::LMDBStore, p)
    rstrip.(filter(endswith('/'), listwholefolder(d,p)),'/')
end
function Zarr.subkeys(d::LMDBStore, p)
    filter(!endswith('/'), listwholefolder(d,p))
end
function Zarr.storefromstring(::Type{<:LMDBStore}, s, create)
    LMDBStore(s; create=create),""
end
Base.close(s::LMDBStore) = Base.close(s.d)

push!(Zarr.storageregexlist,r".lmdb/$"=>LMDBStore)
push!(Zarr.storageregexlist,r".lmdb$"=>LMDBStore)


end
