export image, dockerfile

abstract AbstractImage
type Image <: AbstractImage
  name::String
end

type BuildImage <: AbstractImage
  name::String
  base::AbstractImage

  volumes::Vector{String}
  ppas::Vector
  workdir::String
  env::Dict
  packages::Vector{String}
  pips::Vector{String}
  args::Vector{String}
  rm::Bool
end

const DEFAULT_IMAGE = convert(Dict{Symbol, Any}, {
  :volumes => String[],
  :workdir => "",
  :env => Dict(),
  :packages => String[],
  :pips => String[],
  :args => String[],
  :rm => true
})

function BuildImage(name::String, base::AbstractImage; kwargs...)
  # Treat volume separately
  volumes = Util.getarg(:volumes, kwargs, DEFAULT_IMAGE)
  for (vol, path) in filter(x -> x[1] == :volume, kwargs)
    push!(volumes, string(path))
  end
  filter!(x -> x[1] != :volume, kwargs)

  ppas = [ppa for (key, ppa) in filter(x -> x[1] == :ppa, kwargs)]
  filter!(x -> x[1] != :ppa, kwargs)

  # Remove special keyword arg volumes
  if length(kwargs) !=(map(x->x[1], kwargs) |> unique |> length)
    error("Keyword arguments, other than volume should be unique")
  end

  BuildImage(
    name, base, unique(volumes), ppas,
    map(x -> Util.getarg(x, kwargs, DEFAULT_IMAGE), names(BuildImage)[5:end])...
  )
end

function BuildImage(name::String, base::String="ubuntu:14.04"; kwargs...)
  if length(base) == ""
    error("Base cannot be empty")
  end
  BuildImage(name, Image(base); kwargs...)
end

function image(name::String, args...; kwargs...)
  if length(args) != 0 || length(kwargs) != 0
    BuildImage(name, args...; kwargs...)
  else
    Image(name)
  end
end

function dockerfile(image::BuildImage)
    result = "FROM $(image.base.name)\n"
    result *= "RUN apt-get update\n"
    if length(image.ppas) > 0
      ppas = join(["add-apt-repository ppa:" * n for n in image.ppas], "\\\n    && ")
      packages = "software-properties-common python-software-properties"
      result *= "RUN apt-get install -y $packages \\\n    && $ppas \\\n    && apt-get update\n"
    end
    if length(image.packages) > 0
      packages = ""
      regex = r"([a-z,A-Z,0-9,_,\-,+,\.]*)\s*(?:\(\s*((?:>|<|=)*)\s*([0-9,.,-,+]*)\s*\))?"
      for package in image.packages
        name, constraint, version = match(regex, package).captures
        if is(name, nothing) || length(name) == 0
          error("Could not determine name of package")
        end
        if (!is(version, nothing)) && length(version) > 0
          if is(constraint, nothing)
            packages *= " " * name * "=" * version
          elseif constraint == "==" || constraint == "="
            packages *= " " * name * "=" * version
          else
            packages *= " " * name
          end
        else
          packages *= " " * name
        end
      end
      result = result *"RUN apt-get install -y $packages\n"
    end
    if length(image.pips) > 0
        result = result * "RUN pip install $(join(image.pips, " "))\n"
    end
    if length(image.volumes) > 0
        volumes = join(image.volumes, " ")
        result *= "RUN mkdir -p $volumes \n"
        result *= "VOLUME $volumes\n"
    end
    if length(image.env) > 0
      result *= "ENV " * join(["$(string(k))=\"$(string(v))\"" for (k, v) in image.env], " ")
      result *= "\n"
    end
    if length(image.args) > 0
        result = result * join(["RUN $(chomp(u))" for u in image.args], "\n")
    end
    if length(image.workdir) > 0
        result *= "WORKDIR $(image.workdir)\n"
    end
    result
end

|> (machine::MachineEnv, image::AbstractImage) = (machine, image)
function |> (parent::AbstractImage, child::BuildImage)
  result = deepcopy(child)
  result.base = parent
  result
end
function |> (parents::(MachineEnv, AbstractImage), child::BuildImage)
  parents[1] |> (parents[2] |> child)
end

function command_impl(machine::MachineEnv, image::BuildImage)
  rmargs = if image.rm "--rm=true" else "" end
  name = if length(image.name) > 0 "--tag=\"$(image.name)\"" else "" end
  # File needs to be in context... there is no good way to get a temp file in a specific dir yet, it
  # seems.
  imagefile = Util.heretempfile()
  open(imagefile, "w") do file
    write(file, dockerfile(image))
  end
  filename = "--file=\"$(basename(imagefile))\""
  path = dirname(imagefile)
  cmd = command(machine, "build", "$rmargs  $name $filename $path")
  if isa(image.base, BuildImage)
    cmds, files = command_impl(machine, image.base)
    [cmds..., cmd], [files..., imagefile]
  else
    [cmd], [imagefile]
  end
end

function command_impl(func::Function, machine::MachineEnv, image::BuildImage)
  cmds, files = command_impl(machine, image)
  try
    return cmds |> func
  finally
    for imagefile in files
      (!isfile(imagefile)) || rm(imagefile)
    end
  end
end

run(inputs::(MachineEnv, BuildImage)) = run(inputs[1], inputs[2])
run(machine::MachineEnv, image::BuildImage) = command_impl(run, machine, image)
readchomp(inputs::(MachineEnv, BuildImage)) = readchomp(inputs[1], inputs[2])
readchomp(machine::MachineEnv, image::BuildImage) = command_impl(readchomp, machine, image)
readall(inputs::(MachineEnv, BuildImage)) = readall(inputs[1], inputs[2])
readall(machine::MachineEnv, image::BuildImage) = command_impl(readall, machine, image)
