type MachineEnv
  machine::Machine
  config::String
  volumes::Dict{String, String}

  image::String
  interactive::Bool
  rm::Bool
  workdir::String
  user::String
  env::Dict{Symbol, String}
end

const DefaultMachine = convert(Dict{Symbol, Any}, {
  :image => "ubuntu:14.04",
  :volumes => Dict{String, String}(),
  :interactive => false,
  :rm => true,
  :workdir => "",
  :user => "",
  :env => Dict{Symbol, String}()
})

function MachineEnv(machine::Machine; kwargs...)
  # Define helper functions
  hasarg(s::Symbol) = length(filter((x -> x[1] == s), kwargs)) > 0
  function getarg(s::Symbol)
    for (k, v) in kwargs
      if k == s; return v end
    end
    if !haskey(DefaultMachine, s); error("Unknown keyword argument"); end
    DefaultMachine[s]
  end

  # Treat volume separately
  volumes = getarg(:volumes)
  for (vol, (k, v)) in filter(x -> x[1] == :volume, kwargs)
    volumes[string(k)] = string(v)
  end
  filter!(x -> x[1] != :volume, kwargs)

  # Remove special keyword arg volumes
  if length(kwargs) !=(map(x->x[1], kwargs) |> unique |> length)
    error("Keyword arguments, other than volume should be unique")
  end

  conf = if hasarg(:config) getarg(:config) else config(machine) end

  maps = map(getarg, names(MachineEnv)[4:end])
  MachineEnv(
    machine, conf, volumes,
    map(getarg, names(MachineEnv)[4:end])...
  )
end

function MachineEnv(env::MachineEnv; kwargs...)
  volumes = map(x -> x[2], filter(x -> x[1] == :volume, kwargs))
  filter!(x -> x[1] != :volume, kwargs)

  result = deepcopy(env)
  for (k, v) in kwargs
    setfield!(result, k, v)
  end
  for (a, b) in volumes
    result.volumes[string(a)] = string(b)
  end

  result
end
