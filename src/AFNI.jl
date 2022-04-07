module AFNI

# Info
export isafni,AFNIExtension,NIfTIExtension,dset_info

# Utils
export isnifti,isafni,isdset
export prefix,suffix

# Decon
export deconvolve

include("info.jl")
include("utils.jl")
include("decon.jl")

end
