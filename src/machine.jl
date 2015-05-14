export Machine, exists, startoff, remove!

type Machine
  name::String
end

const docker_machine = "docker-machine"

function Machine(name; vm="virtualbox", create=true, start=true)
  result = Machine(name)
  if create && !exists(result)
    run(`$docker_machine create -d $vm $name`)
  elseif start
    run(`$docker_machine start $name`)
  end
  result
end

function exists(machine::Machine)
    open(`$docker_machine ls`) do stdout
      readline(stdout)
      for line in readlines(stdout)
        if split(chomp(line))[1] == machine.name return true end
      end
      false
    end
end

function startoff(machine::Machine; vm="virtualbox")
  if exists(machine)
    run(`$docker_machine start $(machine.name)`)
  else
    run(`$docker_machine create -d $vm $(machine.name)`)
  end
  activate(machine)
end

activate(machine::Machine) = run(`$docker_machine active $(machine.name)`)

function remove!(machine::Machine)
  if exists(machine)
    run(`$docker_machine rm $(machine.name)`)
  end
end

function config(machine::Machine)
  if !exists(machine)
    error("machine $(machine.name) does not exist")
  end
  activate(machine)
  readchomp(`$docker_machine config $(machine.name)`)
end
