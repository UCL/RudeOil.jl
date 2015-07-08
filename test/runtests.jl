module RudeOilTests
using RudeOil
using FactCheck: facts, context, @fact, greater_than, not, @fact_throws

import Base: ismatch
ismatch(regex::String) = x -> ismatch(Regex(regex), x)
contains(item) = x -> item ∈ x

#= include("machine.jl") =#

const machine = Machine("TemporaryRUDEOILTestMachine")
try
  # Use same machine for all tests.
  # Cos takes time to create
  start_machine(machine)

  include("env.jl")
  include("image.jl")
  include("container.jl")


finally
  remove!(machine)
end
end
