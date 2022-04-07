using NIfTI,LightXML

"""isafni(e::NIfTI.NIfTIExtension)

Is this an AFNI Extension?"""
isafni(e::NIfTI.NIfTIExtension) = e.ecode==4

"""parse_quotedstrings(a::AbstractString)

A simple function to parse apart the strings in AFNI NIfTI Extensions"""
function parse_quotedstrings(a::AbstractString)
    strings = SubString[]
    stringstart = 0
    stringend = 0

    i = 1
    while i<=length(a)
        a[i] == '\\' && (i += 2; continue)

        if a[i]=='"'
            if stringstart==0
                stringstart = i+1
                stringend = 0
            elseif stringend==0
                push!(strings,SubString(a,stringstart,i-1))
                stringstart = 0
            end
        end
        i += 1
    end
    strings
end

"""AFNIExtension(e::NIfTI.NIfTIExtension)

Parse the raw NIfTI extension info AFNI metadata

    ecode::Int32             => should be 4 if this is an AFNI header
    edata::Vector{UInt8}     => raw data

    raw_xml::String          => parsed XML
    header::Dict{String,Any} => XML parsed into a Dict
"""
mutable struct AFNIExtension
    ecode::Int32
    edata::Vector{UInt8}

    raw_xml::String
    header::Dict{String,Any}
end

function AFNIExtension(e::NIfTI.NIfTIExtension)
    isafni(e) || error("Trying to convert an unknown NIfTIExtension to AFNIExtension")

    edata = copy(e.edata)
    raw_xml = String(edata)

    xdoc = parse_string(raw_xml)
    xroot = root(xdoc)

    header_dict = Dict{String,Any}()

    for atr in xroot["AFNI_atr"]
        t = attribute(atr,"ni_type")
        n = attribute(atr,"atr_name")

        if t=="String"
            header_dict[n] = parse_quotedstrings(content(atr))
        elseif t=="int"
            header_dict[n] = parse.(Int,split(content(atr)))
        elseif t=="float"
            header_dict[n] = parse.(Float64,split(content(atr)))
        end

        isa(header_dict[n],AbstractArray) && length(header_dict[n])==1 && (header_dict[n] = only(header_dict[n]))
        if n == "BRICK_LABS"
            isa(header_dict[n],AbstractArray) && (header_dict[n] = join(header_dict[n]))
            header_dict[n] = split(header_dict[n],"~")
        end
        if n == "BRICK_STATSYM"
            isa(header_dict[n],AbstractArray) && (header_dict[n] = join(header_dict[n]))
            header_dict[n] = split(header_dict[n],";")
        end
    end

    free(xdoc)
    AFNIExtension(e.ecode,e.edata,raw_xml,header_dict)
end

NIfTIExtension(a::AFNIExtension) = NIfTI.NIfTIExtension(a.ecode,a.edata)

"""copied straight from NIfTI.jl - just to avoid reading the whole file"""
function read_extensions(fname::AbstractString)
    open(fname) do f
        f = NIfTI.niopen(f)   # Let NIfTI.jl handle the GZip stuff
        header, swapped = NIfTI.read_header(f)
        NIfTI.read_extensions(f, header.vox_offset - 352) # Yeah. Don't know. Just copied it.
    end
end

"""dset_info(fname::AbstractString)

Simple helper function to read the file `fname` and return a `Dict` from the header
"""
function dset_info(fname::AbstractString)
    e = read_extensions(fname)
    d = Dict{String,Any}()
    for ee in e
        if isafni(ee)
            merge!(d,AFNIExtension(ee).header)
        end
    end

    return d
end
