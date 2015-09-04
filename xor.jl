include("tests.jl")
include("scorelang.jl")

export fixed_length_xor

function fixed_length_xor (bytes_A::Array{Uint8,1}, bytes_B::Array{Uint8,1})
  @assert sizeof(bytes_A) == sizeof(bytes_B)
  i = 1
  while (i <= sizeof(bytes_A))
    bytes_B[i] = bytes_A[i] $ bytes_B[i]
    i += 1
  end
  return bytes_B
end

function repeating_xor (bytes_input::ByteString, bytes_key::Array{Uint8,1})
  @assert sizeof(bytes_input) % sizeof(bytes_key) == 0
  bytes_output = Array(Uint8, sizeof(bytes_input))
  i = one(Int32)
  while (i <= sizeof(bytes_input))
    j = one(Int32)
    while (j <= sizeof(bytes_key))
      bytes_output[i] = bytes_input[i] $ bytes_key[j]
      i += 1
      j += 1
    end
  end
  return ASCIIString(bytes_output)
end

function decrypt_repeating_xor(cipher_text::ASCIIString, keys::Vector)
  cleartext = ""
  score = float32(0.0)
  for key in keys
    candidate_text = repeating_xor(cipher_text, key)
    candidate_score = character_frequency_score(candidate_text, english)
    print(char(key), ": ", round(candidate_score, 2), ", ", candidate_text, "\n")
    if candidate_score > score
      cleartext = candidate_text
      score = candidate_score
    end
  end
  return cleartext
end

function test_fixed_xor()
  input_a = "1c0111001f010100061a024b53535009181c"
  input_a = hex2bytes(input_a)
  input_b = "686974207468652062756c6c277320657965"
  input_b = hex2bytes(input_b)
  output = fixed_length_xor(input_a, input_b)
  return output == hex2bytes("746865206b696420646f6e277420706c6179")
end

function decrypt_xor_cipher()
  test_str = hex2bytes("1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736")
  test_str = ascii(test_str)
  decryption_keys = Array{Uint8,1}[]
  for i = keys(english)
    a = Array(Uint8,1)
    a[1] = uint8(i)
    append!(decryption_keys, {a})
  end
  cleartext = decrypt_repeating_xor(test_str, decryption_keys)
  print(cleartext)
end

function test_module()
  run_test(test_fixed_xor)
end

decrypt_xor_cipher()
test_module()

function create_keys()
  keys = Array(Any, 1)
  for i = 0:255
    a = Array(Uint8, 2)
    a[1] = i
    a[2] = i + 1
    append!(keys, a)
  end
  return keys
end

a = create_keys()
