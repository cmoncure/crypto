include("tests.jl")

export hex_string_to_base64
const base64_charset = uint8([['A':'Z'], ['a':'z'], ['0':'9'], '+', '/'])
const base64_charset_inverse = fill(uint8(255), 256)
for (i, c) in enumerate(base64_charset)
  base64_charset_inverse[uint8(c)] = uint8(i - 1)
end
const base64_pad_char = uint8('=')

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

function reverse_modulo(x::Int, y::Int)
  return abs((x % y) - y)
end

function reverse_modulo(x::Uint, y::Int)
  x = int(x)
  reverse_modulo(x, y)
end

function reverse_modulo(x::Uint, y::Uint)
  x = int(x)
  y = int(y)
  reverse_modulo(x, y)
end

function base64_encode(bytes_input::Array{Uint8})
  i_idx::Uint = 1
  o_idx::Uint = 1
  buf::Uint32 = 0
  i::Int = 0

  input_len::Uint = sizeof(bytes_input)
  padding::Int = input_len % 3 == 0 ? 0 : reverse_modulo(input_len, 3)
  bytes_output_len::Uint = uint(4 * (input_len + padding) / 3)
  bytes_output = Array(Uint8, bytes_output_len)

  while i_idx <= input_len
    buf = 0
    i = 2
    while i_idx <= input_len && i > -1
      buf += uint32(bytes_input[i_idx]) << (8 * i)
      i_idx += 1
      i -= 1
    end
    i = 3
    while o_idx <= bytes_output_len && i > -1
      bytes_output[o_idx] = base64_charset[((buf & (0x0000003f << 6 * i)) >>> (6 * i)) + 1]  # julia +1
      o_idx += 1
      i -= 1
    end
  end
  if padding > 0
    i = bytes_output_len
    while i > bytes_output_len - padding
      bytes_output[i] = base64_pad_char
      i -= 1
    end
  end
  return bytes_output
end

function base64_decode(bytes_input::Array{Uint8})
  @assert sizeof(bytes_input) % 4 == 0
  i::Int = 0
  i_idx::Uint = 1
  o_idx::Uint = 1
  buf::Uint32 = 0
  padding::Uint = 0
  bytes_input_len::Uint = sizeof(bytes_input)
  bytes_output_len::Uint = 3 * bytes_input_len / 4

  while i <= 2
    if bytes_input[bytes_input_len - i] == uint8(base64_pad_char)
      padding += 1
    end
    i += 1
  end

  if padding == 1
    bytes_output_len -= 1
  elseif padding == 2
    bytes_input_len -= 1
    bytes_output_len -= 2
  end

  bytes_output = Array(Uint8, bytes_output_len)
  i = 0
  while o_idx <= bytes_output_len
    buf = 0
    i = 3
    while i > -1 && i_idx <= bytes_input_len
      buf |= uint32(base64_charset_inverse[bytes_input[i_idx]]) << 6 * i
      i_idx += 1
      i -= 1
    end

#    println("buf = ", bits(buf))
    i = 2
    while i > -1 && o_idx <= bytes_output_len
      bytes_output[o_idx] = uint8(buf >>> 8 * i)
      o_idx += 1
      i -= 1
    end
  end
  return bytes_output
end

function base64_decode_file_to_bytes(file_path::String)
  infile = open(file_path, "r")
  b64 = readall(infile)
  b64 = map(uint8, collect(b64))
  filter!(x -> x != '\n', b64)
  base64_decode(b64)
end

test_module()
