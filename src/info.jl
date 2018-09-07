using NIfTI,EzXML

function read_extensions(fname::AbstractString)
    open(fname) do f
        NIfTI.isgz(f) && (f = NIfTI.gzdopen(f))
        header, swapped = NIfTI.read_header(f)
        NIfTI.read_extensions(f, header)
    end
end

function afni_extensions(e::Vector{NIfTI.NIfTI1Extension})
    afni_es = String[]
    for ee in e
        if ee.ecode==4
            endi = findlast(i->i!=0,ee.edata)
            push!(afni_es,String(ee.edata[1:endi]))
        end
    end
    return afni_es
end

function dset_info(fname::AbstractString)
    e = read_extensions(fname)
    eaf = afni_extensions(e)
    for ee in eaf
        doc = parsexml(ee)
        for el in elements(doc.root)
            if haskey(el,"atr_name")
                @info el["atr_name"]
            end
        end
    end
end
