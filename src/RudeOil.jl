module RudeOil

import Base: run, readall, readchomp
function run(tuple::(Cmd, String, Base.AsyncStream))
    open(tuple[1], "w", tuple[3]) do stream
        write(stream, tuple[2])
    end
end
function run(cmds::Vector{Cmd})
  for cmd in cmds
    run(cmd)
  end
end
readchomp(cmds::Vector{Cmd}) = chomp(readall(cmds))
function readall(cmds::Vector{Cmd})
  result = ""
  for cmd in cmds
    result = result * readall(cmd)
  end
  result
end

include("util.jl")
include("machine.jl")
include("env.jl")
include("image.jl")
include("container.jl")

end # module
