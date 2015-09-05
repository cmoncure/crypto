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

function repeating_xor (bytes_input::Array{Uint8}, bytes_key::Array{Uint8})
  i = one(Int32)
  input_len = sizeof(bytes_input)
  key_len = sizeof(bytes_key)
  bytes_output = Array(Uint8, input_len)
  while (i <= input_len)
    bytes_output[i] = bytes_input[i] $ bytes_key[1 + ((i - 1) % key_len)]  # -1 julia
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

function rank_repeating_xor_decryption_keys(cipher_text::Array{Uint8}, keys::Vector, threshold::Int)
  clear_text::ASCIIString = ""
  results = Array((Array{Uint8}, Float32, ASCIIString), 0)
  for key in keys
    clear_text = ascii_filter(repeating_xor(cipher_text, key))
    score = score_candidate_language(clear_text, "english")
    if score >= threshold
      push!(results, (key, round(score, 2), clear_text))
    end
  end
  return sort(results, by=x -> x[2], rev=true)
end

function detect_xor_encryption(cipher_text::Array{Uint8}, keys::Vector, threshold::Int)
  clear_text::ASCIIString = ""
  for key = keys
    clear_text = ascii_filter(repeating_xor(cipher_text, key))
    s = score_candidate_language(clear_text, "english")
    if s > threshold
      return true
    end
  end
  return false
end

function create_keys()
  k = Array(Any, 0)
  for i = 0:255
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
  pass1 = (ascii(output) == "Cooking MC's like a pound of bacon")

  k = map(uint8, collect("ICE"))
  plain_text = map(uint8, collect("Burning 'em, if you ain't quick and nimble\nI go crazy when I hear a cymbal"))
  res = repeating_xor(plain_text, k)
  pass2 = (res == hex2bytes("0b3637272a2b2e63622c2e69692a23693a2a3c6324202d623d63343c2a26226324272765272a282b2f20430a652e2c652a3124333a653e2b2027630c692b20283165286326302e27282f"))
  return (pass1 && pass2)
end

function ascii_filter(s::Array{Uint8})
  if is_valid_ascii(s)
    return s
  end
  filter!(x -> is_valid_ascii([x]), s)
  @assert is_valid_ascii(s)
  s = ascii(s)
  @assert isa(s, ASCIIString)
  return s
end

function stream_detect_xor_encryption(input::IOStream, k::Vector, stride::Uint = 256, threshold::Int = 50)
  detected::Uint = 0
  while !ismarked(input)
    start = position(input) + 1
    s = read_filtered_bytes_from_stream(input, stride)
    s = ascii_filter(s)
    if is_valid_ascii(s)
      s = ascii(s)
        if isalnum(s)
        s = hex2bytes(ascii(s))
      end
    end
    if detect_xor_encryption(s, k, threshold)
      detected += 1
      r = rank_repeating_xor_decryption_keys(s, k, threshold)
      println("Possible XOR encrypted string detected at byte: ", start, "length: ", length(s))
      println("ciphertext: ", ascii(ascii_filter(s)))
      for t in r
        println("Key: ", t[1], " rank: ", t[2], " cleartext: ", t[3])
      end
    end
  end
  return detected
end

function read_filtered_bytes_from_stream(input::IOStream, stride::Uint)
  s = Array(Uint8, 0)
  s = readbytes(input, stride)
  s = inline_filter_bytes(s, uint8('\n'))
  while length(s) < stride
    b = readbytes(input, 1)
    if length(b) == 0
      mark(input)
      return s
    elseif b[1] != '\n'
      append!(s, b)
    end
  end
  return s
end

function hamming_distance(input_A::Array{Uint8}, input_B::Array{Uint8})
  i = 1
  x::Uint8 = 0
  d::Uint8 = 0
  bits(i)
  while i <= length(input_A)
    x = input_A[i] $ input_B[i]
    for bit in map(uint8, (1, 2, 4, 8, 16, 32, 64, 128))
      if (x & bit > 0)
        d += 1
      end
    end
    i += 1
  end
  return d
end

function test_detect_xor_encryption()
  filename = "find_xor.txt"
  infile = open(filename, "r")
  k = create_keys()
  d = stream_detect_xor_encryption(infile, k, uint(60), 65)
  close(infile)
  if d > 0
    return true
  end
  return false
end

function inline_filter_bytes(input::Array{Uint8}, filter_byte::Uint8)
  filter!(x -> x != filter_byte, input)
  return input
end


function test_hamming_distance()
  a = map(uint8, collect("this is a test"))
  b = map(uint8, collect("wokka wokka!!!"))
  return 0x25 == hamming_distance(a, b)
end

function test_module()
  run_test(test_fixed_xor)
  run_test(test_repeating_xor)
  run_test(test_hamming_distance)
  run_test(test_detect_xor_encryption)
end

test_module()

