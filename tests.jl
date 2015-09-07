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

