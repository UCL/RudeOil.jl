export activate

abstract AbstractMachineEnv
type MachineEnv <: AbstractMachineEnv
  machine::AbstractMachine
  config::String
end

function command(machine::MachineEnv, command::String, args::String="")
  activate_impl(machine.machine)
  `$docker $(split(machine.config)) $command $(split(args))`
end

function activate(func::Function, machine::AbstractMachine; delete=false, halt=false)
  vm = activate(machine)
  result = func(vm)
  if delete
    remove!(machine)
  end
  if halt
    run(`$docker_machine stop $(machine.name)`)
  end
  result
end

activate(machine::AbstractMachine) = MachineEnv(machine, config(machine))
