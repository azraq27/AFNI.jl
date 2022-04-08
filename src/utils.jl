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

"""subbrick(dset::String,label::String;suff=:coef)

    makes an AFNI-compatible dset string (e.g., "dset[3]") from the dset and label
    names. If `suff` == `:coef` (the default), will add "_#0Coef" to the label. Also
    accepts `:tstat` and `:fstat`""" 
function subbrick(dset::AbstractString,label::AbstractString;suff::Union{T,Symbol,Nothing}=:coef,num::Int=0) where T<:AbstractString
    info = dset_info(dset)
    if label != "" && label != nothing
        if lowercase(String(suff)) != "fstat"
            label = "$label#$(num)_$(titlecase(String(suff)))"
        else
            label = "$(label)_Fstat"
        end
    end
    i = findfirst(isequal(label),info["BRICK_LABS"])
    i==nothing && return nothing
    return "$dset[$i]"
end
