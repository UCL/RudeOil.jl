facts("Containers") do
  context("incorrect type creation") do
    @fact_throws Exception Container("this"; volume="/a")
  end

  context("type creation") do
    container = Container("this"; volume=("/this", "/a"), volume=("/that", "/b"))
    context("standard") do
      @fact container.image.name => "this"
      @fact length(container.volumes) => 2
      @fact container.volumes => x -> haskey(x, "/a")
      @fact container.volumes => x -> haskey(x, "/b")
      @fact container.volumes["/a"] => "/this"
      @fact container.volumes["/b"] => "/that"

      for name in names(RudeOil.Container)
        if name != :image && name != :volumes
          @fact getfield(container, name) => RudeOil.DEFAULT_CONTAINER[name]
        end
      end

      @fact Container().image.name => RudeOil.DEFAULT_CONTAINER[:image].name
    end


    context("copy creation") do
      copy = Container(container; volume=("/t", "/a"), interactive=true)

      @fact copy.image.name => "this"
      @fact copy.interactive => true
      @fact length(copy.volumes) => 2
      @fact copy.volumes => x -> haskey(x, "/a")
      @fact copy.volumes => x -> haskey(x, "/b")
      @fact copy.volumes["/a"] => "/t"
      @fact copy.volumes["/b"] => "/that"

      for name in names(RudeOil.Container)
        if name ∉ (:image, :volumes, :interactive)
          @fact getfield(copy, name) => RudeOil.DEFAULT_CONTAINER[name]
        end
      end
    end
  end

  context("Run container") do
    vm = activate(machine)

    context("Hello World") do
      result = vm |> Container() |> `echo "Hello World"` |> readchomp
      @fact result => "Hello World"
      result = vm |> `echo "Hello World"` |> readchomp
      @fact result => "Hello World"
    end

    context("With Image") do
      python = image("python", packages=["python"])
      result = vm |> python |> `python -c "print('Hello World')"` |> readchomp
      @fact result => "Hello World"
    end

    context("With volumes") do
      volume = image("volume", volume="/a")
      dirname = RudeOil.Util.heretempfile()
      try
        mkdir(dirname)
        vm |> volume |> Container(volume=(dirname, "/a"), workdir="/a") |> `touch hello` |> run
        @fact joinpath(dirname, "hello") => isfile
      finally
        rm(joinpath(dirname, "hello"))
        rm(dirname)
      end
    end

    context("With array of commands") do
      volume = image("volume", volume="/a")
      dirname = RudeOil.Util.heretempfile()
      try
        mkdir(dirname)
        vm |> volume |> Container(volume=(dirname, "/a"), workdir="/a") |> [
          `touch hello`,
          `mkdir small`,
          setenv(`touch world`, dir="small"),
        ] |> run
        @fact joinpath(dirname, "hello") => isfile
        @fact joinpath(dirname, "small", "world") => isfile
      finally
        rm(dirname, recursive=true)
      end
    end
  end
end
