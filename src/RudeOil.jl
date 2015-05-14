module RudeOil

import Base: run, readall, readchomp
function run(tuple::(Cmd, String, Base.AsyncStream))
    open(tuple[1], "w", tuple[3]) do stream
        write(stream, tuple[2])
    end
end
function run(cmds::Vector)
  for cmd in cmds
    run(cmd)
  end
end

include("util.jl")
include("machine.jl")
include("env.jl")
include("image.jl")

end # module
