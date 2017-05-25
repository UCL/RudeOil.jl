This package is no longer maintained

# RudeOil

Crude package to easily interact with docker and docker-machine. This package is meant to be make
interactions with docker scriptable from Julia.

~~~julia
# Create a vm, create an ubuntu container (implicitly), echo hello world
activate("mymachine") do vm
  result = vm |> `echo "hello world"` |> readchomp
  @assert result == "hello world"
end

# Create an image
activate("mymachine") do vm
  myimage = image("myimage", base="ubuntu:14.04", packages=["python"])
  vm |> myimage |> run
end

# Create an image, instantiate it and run stuff in it
activate("mymachine") do vm
  myimage = image("myimage", base="ubuntu:14.04", packages=["python"])
  vm |> myimage |> `python -c "print('hello world')"`|> run
end

# Create an image, create a container, do stuff
activate("mymachine") do vm
  myimage = image("myimage", volume="/scripts")
  container = Container(volume=("hello", "/scripts"))
  mkdir("hello")

  vm |> myimage |> container |> setenv(`touch world`; dir="/scripts/") |> run
  @assert isfile(joinpath("hello", "world"))
end
~~~

