module Util
  hasarg(s::Symbol, kwargs) = length(filter((x -> x[1] == s), kwargs)) > 0
  function getarg(s::Symbol, kwargs, defaults)
    for (k, v) in kwargs
      if k == s; return v end
    end
    if !haskey(defaults, s); error("Unknown keyword argument $s"); end
    deepcopy(defaults[s])
  end

  function heretempfile(prefix::String="")
    newname() = abspath(joinpath(prefix, basename(tempname())))
    filename = newname()
    while ispath(filename)
      filename = newname()
    end
    filename
  end
end
using .Util
