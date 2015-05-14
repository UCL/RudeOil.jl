module RudeOilTests
using RudeOil
using FactCheck: facts, context, @fact, greater_than

#= include("machine.jl") =#


const machine = Machine("ThisIsARUDEOILTestMachineThatShouldNotExist")
try
  # Use same machine for all tests.
  # Cos takes time to create
  startoff(machine)

  include("env.jl")


finally
  # remove!(machine)
end
end
