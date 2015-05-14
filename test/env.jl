facts("Create MachineEnv structures") do
  context("Default creation") do
    env = RudeOil.MachineEnv(RudeOilTests.machine)
    @fact length(env.config) => greater_than(0)
    @fact env.config => x -> ismatch(r"--tls", x)

    for name in names(RudeOil.MachineEnv)[3:end]
      @fact getfield(env, name) => RudeOil.DefaultMachine[name]
    end
  end
  context("Add standard argument") do
    env = RudeOil.MachineEnv(RudeOilTests.machine; image="this other", rm=false)
    @fact env.image => "this other"
    @fact env.rm => false
  end
  context("Add volume and volume") do
    env = RudeOil.MachineEnv(RudeOilTests.machine; volume=("a", "b"), volume=("c", "d"))
    @fact length(env.volumes) => 2
    @fact env.volumes => x -> haskey(x, "a")
    @fact env.volumes => x -> haskey(x, "c")
    @fact env.volumes["a"] => "b"
    @fact env.volumes["c"] => "d"
  end
  context("Add volumes and volume") do
    env = RudeOil.MachineEnv(RudeOilTests.machine; volumes={"a" => "b"}, volume=("c", "d"))
    @fact length(env.volumes) => 2
    @fact env.volumes => x -> haskey(x, "a")
    @fact env.volumes => x -> haskey(x, "c")
    @fact env.volumes["a"] => "b"
    @fact env.volumes["c"] => "d"
  end
  context("From other env") do
    env0 = RudeOil.MachineEnv(
      RudeOilTests.machine; volumes={"a" => "b"}, image="this other", rm=false)
    env1 = RudeOil.MachineEnv(env0; volume=("a", "c"), image="that")
    for name in names(RudeOil.MachineEnv)
      if name != :volumes && name != :image && name != :machine
        env0_attr = getfield(env0, name)
        env1_attr = getfield(env1, name)
        @fact env1_attr => env0_attr  "$env1_attr => $env0_attr"
      end
    end
    @fact env1.machine.name => env0.machine.name
    @fact env1.image => "that"
    @fact length(env1.volumes) => 1
    @fact env1.volumes => x -> haskey(x, "a")
    @fact env1.volumes["a"] => "c"
  end
end
