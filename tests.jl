include("base64.jl")
include("xor.jl")

function test_base64()
  teststr = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d"
  teststr = hex_string_to_base64(teststr)
  return teststr == hex2bytes("SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t")
end

function test_fixed_xor()
  input_a = "1c0111001f010100061a024b53535009181c"
  input_a = hex2bytes(input_a)
  input_b = "686974207468652062756c6c277320657965"
  input_b = hex2bytes(input_b)
  output = fixed_length_xor(input_a, input_b)
  return output == hex2bytes("746865206b696420646f6e277420706c6179")
end

test_fixed_xor()