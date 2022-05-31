trapezoidal = Dict(
    "code" => "function (yi, h, index, args...)
  return yi + h / 2 * (args[1] + args[2])\nend",
    "len" => 2,
    "start" => 1
)

