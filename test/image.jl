facts("Images") do
  context("type creation") do
    image = Image("this"; volume="/a", volume="/b")
    @fact image.base => "ubuntu:14.04"
    @fact image.volumes => ["/a", "/b"]

    for name in names(RudeOil.Image)
      if name != :name && name != :base && name != :volumes
        @fact getfield(image, name) => RudeOil.DEFAULT_IMAGE[name]
      end
    end
  end

  context("dockerfile creation") do
    context("empty") do
      image = Image("that")
      @fact dockerfile(image) => ismatch("FROM\\s+$(image.base)")
      @fact dockerfile(image) => ismatch("RUN\\s+pip") |> not
      @fact dockerfile(image) => ismatch("RUN\\s+apt-get install") |> not
      @fact dockerfile(image) => ismatch("RUN\\s+mkdir") |> not
    end
    context("packages") do
      image = Image("that", packages=["pack", "age"])
      @fact dockerfile(image) => ismatch("RUN apt-get install -y pack age")
    end
    context("pips") do
      image = Image("that", pips=["pack", "age"])
      @fact dockerfile(image) => ismatch("RUN pip install pack age")
    end
    context("volumes") do
      image = Image("that", volume="/a", volume="/b")
      @fact dockerfile(image) => ismatch("RUN mkdir -p /a /b")
      @fact dockerfile(image) => ismatch("VOLUME /a /b")
    end
  end

  context("docker image creation") do
    image = Image("mynewimage"; workdir="/myvol", volume="/myvol", packages=["julia"])
    activate(machine) do vm
      vm |> image |> run
      images = split(readchomp(RudeOil.command(vm, "images", image.name)), '\n')[2:end]
      images = [split(u, ' ')[1] for u in images]
      @fact images => contains(image.name)
    end
  end
end
