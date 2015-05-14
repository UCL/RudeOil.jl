export Image, dockerfile

abstract AbstractImage
type Image <: AbstractImage
  name::String
  base::String

  volumes::Vector{String}
  workdir::String
  env::Dict{Symbol, String}
  packages::Vector{String}
  pips::Vector{String}
  args::Vector{String}
  rm::Bool
end

const DEFAULT_IMAGE = convert(Dict{Symbol, Any}, {
  :volumes => String[],
  :workdir => "",
  :env => Dict{Symbol, String}(),
  :packages => String[],
  :pips => String[],
  :args => String[],
  :rm => true
})

function Image(name::String, base::String="ubuntu:14.04"; kwargs...)
  if length(base) == ""
    error("Base cannot be empty")
  end

  # Treat volume separately
  volumes = Util.getarg(:volumes, kwargs, DEFAULT_IMAGE)
  for (vol, path) in filter(x -> x[1] == :volume, kwargs)
    push!(volumes, string(path))
  end
  filter!(x -> x[1] != :volume, kwargs)

  # Remove special keyword arg volumes
  if length(kwargs) !=(map(x->x[1], kwargs) |> unique |> length)
    error("Keyword arguments, other than volume should be unique")
  end

  Image(
    name, base, unique(volumes),
    map(x -> Util.getarg(x, kwargs, DEFAULT_IMAGE), names(Image)[4:end])...
  )
end

function dockerfile(image::Image)
    result = "FROM $(image.base)\n" * "RUN apt-get update\n"
    if length(image.packages) > 0
        let packages = [match(r"[^\( ]+", u).match for u in image.packages]
          result = result *"RUN apt-get install -y $(join(packages, " "))\n"
        end
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

|> (machine::MachineEnv, image::Image) = (machine, image)
function impl_run(func::Function, machine::MachineEnv, image::Image)
  rmargs = if image.rm "--rm=true" else "" end
  name = if length(image.name) > 0 "--tag=\"$(image.name)\"" else "" end
  # File needs to be in context... there is no good way to get a temp file in a specific dir yet, it
  # seems.
  imagefile = abspath("." * basename(tempname()))
  try
    open(imagefile, "w") do file
      write(file, dockerfile(image))
    end
    filename = "--file=\"$(basename(imagefile))\""
    path = dirname(imagefile)
    return command(machine, "build", "$rmargs  $name $filename $path") |> func
  finally
    (!isfile(imagefile)) || rm(imagefile)
  end
end
run(inputs::(MachineEnv, Image)) = run(inputs[1], inputs[2])
run(machine::MachineEnv, image::Image) = impl_run(run, machine, image)
readchomp(inputs::(MachineEnv, Image)) = readchomp(inputs[1], inputs[2])
readchomp(machine::MachineEnv, image::Image) = impl_run(readchomp, machine, image)
readall(inputs::(MachineEnv, Image)) = readall(inputs[1], inputs[2])
readall(machine::MachineEnv, image::Image) = impl_run(readall, machine, image)
