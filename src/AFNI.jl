module AFNI

# Info
export isafni,AFNIExtension,NIfTIExtension,dset_info

# Utils
export isnifti,isafni,isdset
export prefix,suffix

# Decon
export deconvolve

include("utils.jl")
include("info.jl")
include("decon.jl")

end
