
[arg] = System.argv()
n = String.to_integer(arg)

prev = System.monotonic_time()
_c = Enum.reduce(Enum.to_list(1..n),0, fn (a , b) -> a + b end)
next = System.monotonic_time()
IO.puts _c
IO.puts "Elixir\t#{n}\t#{System.convert_time_unit(next-prev,:native,:millisecond)}"
