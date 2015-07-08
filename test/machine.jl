facts("Create and activate a virtual machine") do
  vm = Machine("ThisIsARUDEOILTestMachineThatShouldNotExist2"; docreate=false)
  try
    @fact exists(vm) => false
    start_machine(vm)
    @fact exists(vm) => true

    config = RudeOil.config(vm)
    @fact length(config) => greater_than(0)
    @fact config => x -> ismatch(r"--tls", x)

    remove!(vm)
    @fact exists(vm) => false
  finally
    if exists(vm)
      remove!(vm)
    end
  end
end
