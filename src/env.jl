export activate
type MachineEnv
  machine::Machine
  config::String
end

function command(machine::MachineEnv, command::String, args::String="")
  `$docker $(split(machine.config)) $command $(split(args))`
end

function activate(func::Function, machine::Machine; delete=false, halt=false)
  result = func(activate(machine))
  if delete
    remove!(machine)
  end
  if halt
    run(`$docker_machine stop $(machine.name)`)
  end
  result
end

activate(machine::Machine) = MachineEnv(machine, config(machine))
