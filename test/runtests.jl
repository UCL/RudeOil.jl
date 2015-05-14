module RudeOilTests
using RudeOil
using FactCheck: facts, context, @fact, greater_than, not

import Base: ismatch
ismatch(regex::String) = x -> ismatch(Regex(regex), x)
contains(item) = x -> item ∈ x

#= include("machine.jl") =#

const machine = Machine("ThisIsARUDEOILTestMachineThatShouldNotExist")
try
  # Use same machine for all tests.
  # Cos takes time to create
  startoff(machine)

  include("env.jl")
  include("image.jl")


finally
  # remove!(machine)
end
end
