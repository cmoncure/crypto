export run_test

function run_test(test_func::Function)
  res = test_func()
  if res
    text = string(test_func, ": PASSED\n")
  else
    text = string(test_func, ": FAILED\n")
  end
  print(text)
end

using Gadfly
Pkg.add("PyPlot")
using PyPlot

f(x) = x^2
f1(x) = x^2 / sin(x)
plot(f1, -10, 10)

x = linspace(0,2*pi,1000); y = sin(3*x + 4*cos(2*x))
import PyPlot.plot
plot(x, y, color="red", linewidth=2.0, linestyle="--")
