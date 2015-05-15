facts("Create MachineEnv structures") do
  vm = activate(RudeOilTests.machine)
  @fact length(vm.config) => greater_than(0)
  @fact vm.config => x -> ismatch(r"--tls", x)
end
