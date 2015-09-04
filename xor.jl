include("tests.jl")
include("scorelang.jl")

export fixed_length_xor

function fixed_length_xor (bytes_A::Array{Uint8}, bytes_B::Array{Uint8})
  @assert sizeof(bytes_A) == sizeof(bytes_B)
  i = 1
  while (i <= sizeof(bytes_A))
    bytes_B[i] = bytes_A[i] $ bytes_B[i]
    i += 1
  end
  return bytes_B
end

function repeating_xor (bytes_input::Array{Uint8}, bytes_key::Array{Uint8, 1})
  i = one(Int32)
  input_len = sizeof(bytes_input)
  key_len = sizeof(bytes_key)
  bytes_output = Array(Uint8, input_len)
  while (i <= input_len)
    bytes_output[i] = bytes_input[i] $ bytes_key[(i % key_len) + 1]  # +1 julia
    i += 1
  end
  return bytes_output
end

function find_repeating_xor_decryption_key(cipher_text::Array{Uint8}, keys::Vector)
  score = float32(0.0)
  for key in keys
    clear_text = repeating_xor(cipher_text, key)
    candidate_score = score_candidate_language(candidate_text, "english")
    if candidate_score > score
      score = candidate_score
      candidate_key = key
    end
  end
  return candidate_key
end

function rank_repeating_xor_decryption_keys(cipher_text::Array{Uint8}, keys::Vector, threshold::Int = 50)
  results = Array((Array{Uint8}, Float32, ASCIIString), 0)
  for key in keys
    clear_text = ascii(ascii_filter(repeating_xor(cipher_text, key)))
    score = score_candidate_language(clear_text, "english")
    if score >= threshold
      push!(results, (key, round(score, 2), clear_text))
    end
  end
  return sort(results, by=x -> x[2], rev=true)
end

function detect_xor_encryption(cipher_text::Array{Uint8}, keys::Vector, threshold::Int = 50)
  clear_text = ""
  for key = keys
#    try
      clear_text = ascii(ascii_filter(repeating_xor(cipher_text, key)))
#    catch
#      continue
#    end
    s = score_candidate_language(clear_text, "english")
    if s > threshold
      return true
    end
  end
  return false
end

function create_keys()
  k = Array(Any, 0)
  for i = 0:
    a = Array(Uint8, 0)
    push!(a, (i))
    push!(k, a)
  end
  return k
end

function test_fixed_xor()
  input_a = "1c0111001f010100061a024b53535009181c"
  input_a = hex2bytes(input_a)
  input_b = "686974207468652062756c6c277320657965"
  input_b = hex2bytes(input_b)
  output = fixed_length_xor(input_a, input_b)
  return output == hex2bytes("746865206b696420646f6e277420706c6179")
end

function test_repeating_xor()
  input = "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736"
  output = repeating_xor(hex2bytes(input), [uint8('X')])
  return ascii(output) == "Cooking MC's like a pound of bacon"
end

function test_detect_xor_encryption()
  in_file = open("find_xor.txt", "r")
  contents = map(chomp, readlines(in_file))
  contents = join(contents)
  close(in_file)
  k = create_keys()
  i = 1
  stride = 60
  while i + stride < length(contents)
    s = contents[(i):(stride + (i + 1))]
    s = hex2bytes(s)
    i += stride
    if detect_xor_encryption(s, k, 50)
      r = rank_repeating_xor_decryption_keys(s, k, 50)
      println("Possible XOR encrypted string detected at byte: ", i - 1)
      println("ciphertext: ", ascii(ascii_filter(s)))
      for t in r
        println("Key: ", t[1], " rank: ", t[2], " cleartext: ", t[3])
      end
    end
  end
end

function test_module()
  run_test(test_fixed_xor)
  run_test(test_repeating_xor)
end

test_module()

k = create_keys()
c = hex2bytes("1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736")

function ascii_filter(s::Array{Uint8})
  if is_valid_ascii(s)
    return s
  end
  filter!(x -> is_valid_ascii([x]), s)
  @assert is_valid_ascii(s)
  return s
end

detect_xor_encryption(c, k)
d = Uint8[14,54,71,232,89,45,53,81,74,8,18,67,88,37,54,237,61,230,115,64,89,0,30,63,83,92,230,39,16,50,51,75,4,29,225,36,247,60,24,1,26,80,230,8,9,122,195,8,236,238,80,19,55,236,62,16,8,84,32,29]
detect_xor_encryption(d, k)
test_detect_xor_encryption()
