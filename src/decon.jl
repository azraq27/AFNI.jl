"""deconvolve(input, stimtimes; kawargs...)

    input - either a single string or vector of strings
    stimtimes - either a Dict(label => [times]) or vector of Dicts (one for each input)

This function is really case-specific for how I use 3dDeconvolve. Hopefully over time
I'll add more options to make it more general...
"""
function deconvolve(
        input::Union{String,Vector{String},Tuple{Int,Float64}},
        stimtimes::Union{Dict{String,Vector{Float64}},Dict{String,Vector{Vector{Float64}}}};
        model="GAM",
        nfirst::Int=3,polort="A",jobs=length(Sys.cpu_info()),
        glts::Dict=Dict(),
        cmdonly=false,
        kwargs...)

    cmd = Any["3dDeconvolve"]

    append!(cmd,["-nfirst",nfirst,"-polort",polort,"-jobs",jobs])

    append!(cmd,["-local_times"])
    
    num_runs = if isa(input,Vector)
        append!(cmd,vcat(["-input"],input))
        length(input)
    elseif isa(input,String)
        append!(cmd,["-input",input])
        1
    else
        append!(cmd,["-nodata",input[1],input[2]])
        1
    end

    if num_runs==1
        @assert isa(stimtimes,Dict{String,Vector{Float64}})
    else
        @assert isa(stimtimes,Dict{String,Vector{Vector{Float64}}})
        for v in values(stimtimes)
            @assert length(v)==num_runs
        end
    end

    append!(cmd,["-num_stimts",length(stimtimes)])

    stim_i = 1

    for (k,v) in stimtimes
        isa(v,Vector{Float64}) && (v = [v])
        vs = map(v) do vv
            if length(vv)>0
                join(vv," ")
            else
                "*"
            end
        end
        append!(cmd,["-stim_times",stim_i,"1D: " * join(vs," | "),model,
                     "-stim_label",stim_i,k])
        stim_i += 1
    end

    glt_i = 1
    for (k,v) in glts
        append!(cmd,["-gltsym","SYM: " * join(v," "),"-glt_label",glt_i,k])
        glt_i += 1
    end

    for (k,v) in kwargs
        if v==true
            append!(cmd,["-$k"])
        else
            append!(cmd,["-$k",v])
        end
    end

    cmdonly && return cmd
    ENV["AFNI_USE_ERROR_FILE"] = "NO"
    readlines(`$cmd`)
end
