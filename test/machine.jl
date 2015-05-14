facts("Create and activate a virtual machine") do
  vm = Machine("ThisIsARUDEOILTestMachineThatShouldNotExist2")
  @fact exists(vm) => false
  startoff(vm)
  @fact exists(vm) => true

  config = RudeOil.config(vm)
  println("config $config")
  @fact length(config) => greater_than(0)
  @fact config => x -> ismatch(r"--tls", x)

  remove!(vm)
  @fact exists(vm) => false
end
