_afni_suffix_regex = r"(\+(orig|tlrc|acpc)(\.(HEAD|(BRIK(.gz|.bz2)?)))?)$"
_nifti_suffix_regex = r"\.nii(\.gz)?$"

isnifti(fname::AbstractString) = occursin(_nifti_suffix_regex,fname)
isafni(fname::AbstractString) = occursin(_afni_suffix_regex,fname)
isdset(fname::AbstractString) = isnifti(fname) || isafni(fname)

prefix(fname::AbstractString) = replace(replace(fname,_nifti_suffix_regex=>""),_afni_suffix_regex=>"")

function suffix(fname::AbstractString,suf::AbstractString)
    m = match(_nifti_suffix_regex,fname)
    m != nothing && return fname[1:m.offset-1] * suf * m.match

    m = match(_afni_suffix_regex,fname)
    m != nothing && return fname[1:m.offset-1] * suf * m.match

    return fname * suf
end
