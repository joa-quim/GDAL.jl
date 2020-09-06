module GDAL

using MozillaCACerts_jll
using CEnum

const Ctm = Base.Libc.TmStruct

# Fish the binary dependency via GMT lib (except on Windows where we know it in advance)
const gmtlib = Ref{String}()
try
	gmtlib[] = haskey(ENV,"GMT_LIBRARY") ?
		ENV["GMT_LIBRARY"] : string(chop(read(`gmt --show-library`, String)))
catch
	error("This package can only be installed in systems that have GMT")
end
@static Sys.iswindows() ?
	(Sys.WORD_SIZE == 64 ? (const libgdal = "gdal_w64") : (const libgdal = "gdal_w32")) : 
	(
		Sys.isapple() ? (const libgdal = split(readlines(pipeline(`otool -L $gmtlib`, `grep libgdal`))[1])[1]) :
		(
		    Sys.isunix() ? (const libgdal = split(readlines(pipeline(`ldd $gmtlib`, `grep libgdal`))[1])[3]) :
			error("Don't know how to install this package in this OS.")
		)
	)

include("common.jl")

include("gdal_h.jl")
include("gdal_alg.jl")
include("gdal_vrt.jl")
include("gdal_utils.jl")
include("gdalwarper.jl")

include("ogr_api.jl")
include("ogr_srs_api.jl")
include("ogr_core.jl")

include("cpl_error.jl")
include("cpl_conv.jl")
include("cpl_minixml.jl")
include("cpl_progress.jl")
include("cpl_virtualmem.jl")
include("cpl_vsi.jl")

include("error.jl")

const GDALVERSION = Ref{VersionNumber}()
const GDAL_DATA = Ref{String}()
const PROJ_LIB = Ref{String}()

function __init__()
    # register custom error handler
    funcptr = @cfunction(gdaljl_errorhandler, Ptr{Cvoid}, (CPLErr, Cint, Cstring))
    cplseterrorhandler(funcptr)

    # get GDAL version number
    versionstring = gdalversioninfo("RELEASE_NAME")
    GDALVERSION[] = VersionNumber(versionstring)

    # set GDAL_DATA location, this overrides setting the environment variable
    #GDAL_DATA[] = joinpath(GDAL_jll.artifact_dir, "share", "gdal")
    #cplsetconfigoption("GDAL_DATA", GDAL_DATA[])

    # set path to CA certificates
    cplsetconfigoption("CURL_CA_BUNDLE", cacert)

    # set PROJ_LIB location, this overrides setting the environment variable
    #PROJ_LIB[] = joinpath(PROJ_jll.artifact_dir, "share", "proj")
    #osrsetprojsearchpaths([PROJ_LIB[]])
end

end # module
