export Machine, exists, start_machine, remove!

abstract AbstractMachine

type VirtualBoxMachine <: AbstractMachine
  name::String
  memory::Integer
  disk::Integer
  cpucount::Integer
end

const docker_machine = "docker-machine"
const docker = "docker"

# Creates a virtual machine within which to run docker containers
# Parameters
#    name: the name of the machine...
#    vm: Only virtual box for now. Defaults to "VirtualBox"
#    start: Whether to start the marchine or not. Defaults to true. Disabled if docreate is false.
#    docreate: Whether to create the marchine or not. Defaults to true.
#    memory: In megabytes. Defaults to 0, which defaults to whatever docker wants.
#    disk: In megabytes. Defaults to 0, which defaults to whatever docker wants.
#    cpucount: Defaults to 1.
function Machine(name, vm::String="VirtualBox";
    start=true, docreate=true, memory::Int=0, disk::Int=0, cpucount::Int=1)
  if vm != "VirtualBox"
    error("I only know of VirtualBox for now")
  end
  result = VirtualBoxMachine(name, memory, disk, cpucount)
  const does_exist = exists(result)
  if docreate && !does_exist
    run(create(result))
  elseif start && does_exist
    run(`$docker_machine start $name`)
  end
  result
end

function create(machine::VirtualBoxMachine)
  result = `$docker_machine create -d virtualbox`
  if machine.memory > 0; result = `$result --virtualbox-memory $(machine.memory)` end
  if machine.disk > 0; result = `$result --virtualbox-disk-size $(machine.disk)` end
  if machine.cpucount > 1; result = `$result --virtualbox-cpu-count $(machine.cpucount)` end
  `$result $(machine.name)`
end

function exists(machine::AbstractMachine)
    open(`$docker_machine ls`) do stdout
      readline(stdout)
      for line in readlines(stdout)
        if split(chomp(line))[1] == machine.name return true end
      end
      false
    end
end

function start_machine(machine::AbstractMachine)
  if exists(machine)
    run(`$docker_machine start $(machine.name)`)
  else
    run(create(machine))
  end
  activate_impl(machine)
end

activate_impl(machine::AbstractMachine)= run(`$docker_machine start $(machine.name)`)

function remove!(machine::AbstractMachine)
  if exists(machine)
    run(`$docker_machine rm $(machine.name)`)
  end
end

function config(machine::AbstractMachine)
  if !exists(machine)
    error("machine $(machine.name) does not exist")
  end
  activate_impl(machine)
  readchomp(`$docker_machine config $(machine.name)`)
end
