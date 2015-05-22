export Container
abstract AbstractContainer

type Container <: AbstractContainer
  image::AbstractImage
  volumes::Dict{String, String}
  workdir::String
  name::String
  interactive::Bool
  rm::Bool
  env::Dict{Symbol, String}
end

const DEFAULT_CONTAINER = convert(Dict{Symbol, Any}, {
  :workdir => "",
  :name => "",
  :image => Image("ubuntu:14.04"),
  :volumes => Dict{String, String}(),
  :interactive => false,
  :rm => true,
  :env => Dict{Symbol, String}()
})

function Container(image::AbstractImage; kwargs...)
  # Treat volume separately
  volumes = Util.getarg(:volumes, kwargs, DEFAULT_CONTAINER)
  for (vol, paths) in filter(x -> x[1] == :volume, kwargs)
    if length(paths) != 2 || isa(paths, String)
      error("volume keyword argument should consist of (vm, container) path tuples")
    end
    volumes[string(paths[2])] = string(paths[1])
  end
  filter!(x -> x[1] != :volume, kwargs)

  # Remove special keyword arg volumes
  if length(kwargs) !=(map(x->x[1], kwargs) |> unique |> length)
    error("Keyword arguments, other than volume should be unique")
  end

  Container(
    image, volumes,
    map(x -> Util.getarg(x, kwargs, DEFAULT_CONTAINER), names(Container)[3:end])...
  )
end
Container(image::String; kwargs...) = Container(Image(image); kwargs...)
Container(; kwargs...) = Container(deepcopy(DEFAULT_CONTAINER[:image]); kwargs...)

function Container(container::Container; kwargs...)
  volumes = map(x -> x[2], filter(x -> x[1] == :volume, kwargs))
  filter!(x -> x[1] != :volume, kwargs)

  result = deepcopy(container)
  for (k, v) in kwargs
    setfield!(result, k, v)
  end
  for paths in volumes
    if length(paths) != 2 || isa(paths, String)
      error("volume keyword argument should consist of (vm, container) path tuples")
    end
    result.volumes[string(paths[2])] = string(paths[1])
  end

  result
end

function command(machine::MachineEnv, container::Container, cmd::Cmd=``)
  volargs = ""
  for (cont, host) in container.volumes
    volargs *= "-v $(chomp(abspath(host))):$(chomp(cont)):rw "
  end
  intargs = if container.interactive; "-i" else "" end
  rmargs = if container.rm "--rm=true" else "" end
  nmargs = if length(container.name) > 0 "--name=\"$(container.name)\"" else "" end

  envs = join(["-e $(string(k))=\"$(string(v))\"" for (k, v) in container.env], " ")
  if !is(cmd.env, nothing)
    envs = envs * " " * join(["-e $u" for u in cmd.env], " ")
  end

  if length(cmd.dir) > 0
    wkd = "--workdir=\"$(cmd.dir)\""
  elseif length(container.workdir) > 0
    wkd = "--workdir=\"$(container.workdir)\""
  else
    wkd = ""
  end
  image = container.image.name
  result = command(machine, "run", "$rmargs $envs $volargs $intargs $nmargs $wkd $image")
  `$result $cmd`
end

|>(machine::MachineEnv, container::AbstractContainer) = (machine, container)
|>(env::(MachineEnv, AbstractContainer), cmd::Union(Cmd, Vector{Cmd})) = (env[1], env[2], cmd)
function |> (image::AbstractImage, container::AbstractContainer)
  result = deepcopy(container)
  result.image = image
  result
end
|> (env::(MachineEnv, AbstractImage), cont::AbstractContainer) = (env[1], env[2] |> cont)
function |>(env::(MachineEnv, AbstractImage), cmd::Union(Cmd, Vector{Cmd}))
  env[1], Container(env[2]), cmd
end
|> (env::MachineEnv, cmd::Union(Cmd, Vector{Cmd})) = (env, Container(), cmd)
|> (m::MachineEnv, c::(Container, Union(Cmd, Vector{Cmd}))) = (m, c[1], c[2])

function command_impl(func::Function, vm::MachineEnv, container::Container, cmd::Cmd)
  if isa(container.image, BuildImage)
    vm |> container.image |> run
  end
  command(vm, container, cmd) |> func
end


for runner in [:run, :readchomp, :readall]
  @eval begin
    $runner(cmd::(MachineEnv, Container, Cmd)) = command_impl($runner, cmd[1], cmd[2], cmd[3])
    $runner(cmd::(MachineEnv, Container)) = command_impl($runner, cmd[1], cmd[2], ``)
    $runner(vm::MachineEnv, cont::Container, cmd::Cmd=``) = command_impl($runner, vm, cont, cmd)
  end
end

function bash(cmd::Cmd)
  result = ""
  # Adds environment variable
  if !is(cmd.env, nothing)
    result *= join(cmd.env, "\n")
  end
  # Move to workdir
  if length(cmd.dir) > 0
    result *= "cd $(cmd.dir)\n"
  end
  # Add command
  result *= "$(`$cmd`)"[2:end-1] * "\n"
  result
end
function run(vm::MachineEnv, container::Container, cmds::Vector{Cmd})
  if isa(container.image, BuildImage)
    vm |> container.image |> run
  end
  container = deepcopy(container)
  container.interactive = true
  open(command(vm, container), "w", STDOUT) do stream
    for cmd in cmds
      write(stream, bash(cmd))
    end
  end
end
run(cmd::(MachineEnv, Container, Vector{Cmd})) = run(cmd[1], cmd[2], cmd[3])
