facts("Images") do
  context("type creation") do
    pic = image("this"; volume="/a", volume="/b")
    @fact pic.base.name => "ubuntu:14.04"
    @fact pic.volumes => ["/a", "/b"]

    for name in names(RudeOil.BuildImage)
      if name ∉ [:name, :base, :volumes, :ppas]
        @fact getfield(pic, name) => RudeOil.DEFAULT_IMAGE[name]
      end
    end
  end

  context("dockerfile creation") do
    context("empty") do
      pic = RudeOil.BuildImage("that")
      @fact dockerfile(pic) => ismatch("FROM\\s+$(pic.base.name)")
      @fact dockerfile(pic) => ismatch("RUN\\s+pip") |> not
      @fact dockerfile(pic) => ismatch("RUN\\s+apt-get install") |> not
      @fact dockerfile(pic) => ismatch("RUN\\s+mkdir") |> not
    end
    context("packages") do
      pic = image("that", packages=["pack", "age"])
      match = "RUN\\s+apt-get\\s+install\\s+-y\\s+pack\\s+age"
      @fact dockerfile(pic) => ismatch(match)
    end
    context("pips") do
      pic = image("that", pips=["pack", "age"])
      @fact dockerfile(pic) => ismatch("RUN pip install pack age")
    end
    context("volumes") do
      pic = image("that", volume="/a", volume="/b")
      @fact dockerfile(pic) => ismatch("RUN mkdir -p /a /b")
      @fact dockerfile(pic) => ismatch("VOLUME /a /b")
    end
  end

  context("docker image creation") do
    first = image("mynewimage"; workdir="/myvol", volume="/myvol", packages=["julia"])
    context("single image") do
      activate(machine) do vm
        vm |> first |> run
        images = split(readchomp(RudeOil.command(vm, "images", first.name)), '\n')[2:end]
        images = [split(u, ' ')[1] for u in images]
        @fact images => contains(first.name)
      end
    end
    context("chained image") do
      second = image("mysecondimage"; packages=["python"])
      activate(machine) do vm
        vm |> first |> second |> run
        images = split(readchomp(RudeOil.command(vm, "images", "")), '\n')[2:end]
        images = [split(u, ' ')[1] for u in images]
        @fact images => contains(first.name)
        @fact images => contains(second.name)
      end
    end
  end

  context("Upstream docker image") do
    pic = image("ubuntu:14.04")
    @fact names(pic) => [:name]
  end
end
