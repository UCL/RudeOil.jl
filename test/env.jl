facts("Create MachineEnv structures") do
  env = RudeOil.MachineEnv(RudeOilTests.machine)
  @fact length(env.config) => greater_than(0)
  @fact env.config => x -> ismatch(r"--tls", x)
end
