include("tests.jl")

export hex_string_to_base64

function hex_string_to_base64(str::String)
  str = hex2bytes(str)
  str = base64(str)
  return str
end

function test_hex_string_to_base_64()
  teststr = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d"
  teststr = hex_string_to_base64(teststr)
  return teststr == "SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t"
end

function test_module()
  run_test(test_hex_string_to_base_64)
end

test_module()
