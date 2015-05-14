export activate
type MachineEnv
  machine::Machine
  config::String
  function MachineEnv(machine::Machine, conf::String="")
    activate(machine)
    new(machine, if length(conf) == 0; config(machine) else conf end)
  end
end

function command(machine::MachineEnv, command::String, args::String="")
  `$docker $(split(machine.config)) $command $(split(args))`
end

function activate(func::Function, machine::Machine; delete=false, halt=false)
  env = MachineEnv(machine)
  result = func(env)
  if delete
    remove!(machine)
  end
  if halt
    run(`$docker_machine stop $(machine.name)`)
  end
  result
end
