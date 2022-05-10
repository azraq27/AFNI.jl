using Distributions

_afni_suffix_regex = r"(\+(orig|tlrc|acpc)(\.(HEAD|(BRIK(.gz|.bz2)?)))?)$"
_nifti_suffix_regex = r"\.nii(\.gz)?$"

isnifti(fname::AbstractString) = occursin(_nifti_suffix_regex,fname)
isafni(fname::AbstractString) = occursin(_afni_suffix_regex,fname)
isdset(fname::AbstractString) = isnifti(fname) || isafni(fname)

prefix(fname::AbstractString) = replace(replace(fname,_nifti_suffix_regex=>""),_afni_suffix_regex=>"")

function suffix(fname::AbstractString,suf::AbstractString)
    fname = split(fname,"/")[end]

    m = match(_nifti_suffix_regex,fname)
    m != nothing && return fname[1:m.offset-1] * suf * m.match

    m = match(_afni_suffix_regex,fname)
    m != nothing && return fname[1:m.offset-1] * suf * m.match

    return fname * suf
end

"""subbrick(dset::String,label::String;suff=:coef,num_only=false)

    makes an AFNI-compatible dset string (e.g., "dset[3]") from the dset and label
    names. If `suff` == `:coef` (the default), will add "_#0Coef" to the label. Also
    accepts `:tstat`, `rstat`, and `:fstat`

    If you just want the index as a number, set `num_only` to `true`"""
function subbrick(dset::AbstractString,label::AbstractString;
    suff::Union{T,Symbol,Nothing}=:coef,num::Int=0,
    num_only::Bool=false
    ) where T<:AbstractString
    info = dset_info(dset)
    if label != "" && label != nothing
        if !(lowercase(String(suff)) in ["fstat","rstat"])
            label = "$label#$(num)_$(titlecase(String(suff)))"
        else
            label = "$(label)_$(titlecase(String(suff)))"
        end
    end
    i = findfirst(isequal(label),info["BRICK_LABS"])
    i==nothing && return nothing
    num_only && return i
    return "$dset[$(i-1)]"
end

"""p_to_value(dset::String,label::String,p::Float64;suff=:tstat)

calculates stat value (based on subbrick) to achieve the given _p_"""
function p_to_value(dset::AbstractString,label::AbstractString,p::Float64;suff=:tstat,tail=:two)
    tail==:two && (p /= 2)
    n = subbrick(dset,label;suff,num_only=true)

    info = dset_info(dset)
    statsym = info["BRICK_STATSYM"][n]
    if (m = match(r"Ttest\(([0-9]+)\)",statsym)) != nothing
        return invlogcdf(TDist(parse(Int,m[1])),log(1 - p))
    end
    if (m = match(r"Ftest\(([0-9]+),([0-9]+)\)",statsym)) != nothing
        return invlogcdf(FDist(parse(Int,m[1]),parse(Int,m[2])),log(1 - p))
    end
    return nothing
end

num_reps(fname::AbstractString) = parse(Int,only(readlines(`3dinfo -nv $fname`)))
