immutable AES_cipher_params
  bits::Unsigned # Cipher key length, bits
  nk::Unsigned # Number of 32-bit words, cipher key
  nb::Unsigned # Number of columns in State
  nr::Unsigned # Number of rounds
end

function aes_get_cipher_params(key_length_bits::Int)
  @assert key_length_bits in (128, 192, 256)
  return AES_cipher_params(key_length_bits, key_length_bits / 32, 4, key_length_bits / 32 + 6)
end

function polynomial_degree(p::Unsigned, i::Integer)
  while i > -1
    if p & (0x0000001 << i) != 0
      return i
    end
    i -= 1
  end
  return -1
end

function polynomial_degree(p::Uint8)
  polynomial_degree(p, 7)
end

function polynomial_degree(p::Uint16)
  i = 15
  polynomial_degree(p, 15)
end

function gf_div(x::Unsigned, d::Unsigned)
  r = uint16(x)
  d = uint16(d)
  q::Uint16 = 0x0
  r_deg = polynomial_degree(r)
  d_deg = polynomial_degree(d)
  shift = r - d

  while r_deg >= d_deg
    shift = r_deg - d_deg
    q |= uint16(0x1) << shift
    r = r $ (d << (shift))
    r_deg = polynomial_degree(r)
  end
  q, r
end

function gf_modulo(x::Unsigned)
  q, r = gf_div(x, 0x011b)
  r
end

function xtime(x::Uint8)
  x & 0x80 == 0x80 ? (x << 1) $ 0x1b : x << 1
end

function xtime_recursive(x::Uint8, i::Integer)
  while i > 0
    i -= 1
    x = xtime(x)
  end
  return x
end

function gf_mult(x::Uint8, y::Uint8)
  s::Uint8 = 0x0
  xtm::Uint8 = x
  for i in 0:7
    if y & (0x1 << i) != 0   # checks all bits.  is there a smarter way?
      s $= xtm
    end
    xtm = xtime(xtm)
    end
  s
end
@vectorize_2arg Uint8 gf_mult

function mult_poly(x::Unsigned, y::Unsigned)
  shifts = Array(Any, 0)
  p::Uint64 = 0
  for i = 0:polynomial_degree(uint16(y))
    if y & (1 << i) != 0
      push!(shifts, i)
    end
  end

  for i = 1:length(shifts)
    p $= uint64(x) << shifts[i]
  end
  p
end

function gf_mult_long(x::Unsigned, y::Unsigned)
  p = mult_poly(x, y)
  gf_modulo(p)
end

function gf_mult_inv(a::Unsigned, p::Unsigned = 0x011b)
  u::Unsigned = p
  u_next::Unsigned = a
  v::Unsigned = 0
  v_next::Unsigned = 1
  q = 0
  r = 0

  while u_next != 0
    q, r = gf_div(u, u_next)
    (u, u_next) = (u_next, u $ mult_poly(q, u_next))
    (v, v_next) = (v_next, v $ mult_poly(q, v_next))
  end
  v
end

function gf_mult_inv_by_force(x::Uint8)
  for i = 0x00:0xff
    if gf_mult(x, i) == 0x01
      return i
    end
  end
end

function get_bit_of_byte(byte::Unsigned, bit::Unsigned)
  return byte & (one(Uint64) << bit) == 0x0 ? 0 : 1
end

function bit_array(byte::Unsigned)
  len = sizeof(byte) * 8
  arr = Array(Uint8, len, 1)
  for i::Unsigned = 1:len
    arr[i, 1] = get_bit_of_byte(byte, i - 1)
  end
  arr
end

function bit_vector(byte::Unsigned)
  len = sizeof(byte) * 8
  arr = Array(Uint8, len)
  for i::Unsigned = 1:len
    arr[i] = get_bit_of_byte(byte, i - 1)
  end
  arr
end

function bit_vector_to_byte(bits::Vector{Uint8})
  b::Uint8 = 0x0
  for i = 1:8
    b |= bits[i] << (i - 1)
  end
  b
end

function subbytes_affine_transform(b::Uint8)
  b_bits = bit_vector(b)
  o_bits = bit_vector(0x00)
  bits_addend = bit_vector(0x63)

  for i::Unsigned = 1:8
    o_bits[i] = b_bits[i] $ b_bits[mod1(i+4,8)] $ b_bits[mod1(i+5,8)] $ b_bits[mod1(i+6,8)] $ b_bits[mod1(i+7,8)] $ bits_addend[i]
  end
  bit_vector_to_byte(o_bits)
end

function gen_s_box(s::Uint8)
  s::Uint8 = gf_mult_inv(s)
  subbytes_affine_transform(s)
end

const s_box = [gen_s_box(s) for s::Uint8 = 0:255]

function sub_bytes!(state::Array{Uint8})
  for i = 1:4
    for j = 1:4
      state[i, j] = s_box[1+state[i, j]]
    end
  end
end

function shift_rows!(state::Array{Uint8})
  for i = 2:4
    row = state[i, :]
    for j in 1:4
      row[j] = state[i, mod1(j+i-1, 4)]
    end
    state[i, :] = row
  end
end

const mix_columns_matrix = [0x02 0x01 0x01 0x03
                            0x03 0x02 0x01 0x01
                            0x01 0x03 0x02 0x01
                            0x01 0x01 0x03 0x02]

function mix_columns!(state::Array{Uint8})
  col = Array(Uint8, 4, 1)
  res = Array(Uint8, 4, 1)
  for j = 1:4
    for i = 1:4
      vec = mix_columns_matrix[:,i]
#       println("vec: ", vec)
      col = gf_mult(state[:,j], vec)
#       println("col: ", col)
      res[i,1] = col[1] $ col[2] $ col[3] $ col[4]
    end
    state[:,j] = res
  end
end

function add_words(a::Uint8, b::Uint8)
  a $ b
end

@vectorize_2arg Uint8 add_words

function mult_words(A::Vector{Uint8}, B::Vector{Uint8})
  d::Vector{Uint8} = [0, 0, 0, 0]
  d[1] = gf_mult(a[1], b[1]) $ gf_mult(a[4], b[2]) $ gf_mult(a[3], b[3]) $ gf_mult(a[2], b[4])
  d[2] = gf_mult(a[2], b[1]) $ gf_mult(a[1], b[2]) $ gf_mult(a[4], b[3]) $ gf_mult(a[3], b[4])
  d[3] = gf_mult(a[3], b[1]) $ gf_mult(a[2], b[2]) $ gf_mult(a[1], b[3]) $ gf_mult(a[4], b[4])
  d[4] = gf_mult(a[4], b[1]) $ gf_mult(a[3], b[2]) $ gf_mult(a[2], b[3]) $ gf_mult(a[1], b[4])
  return d
end

function add_round_key!(state::Array{Uint8}, words::Array{Uint8})
  for j = 1:4
    state[:,j] = add_words(state[:,j],words[:,j])
  end
end

function sub_word!(word::Vector{Uint8})
  for i = 1:4
    word[i] = s_box[1 + word[i]]
  end
end

function rot_word!(word::Vector{Uint8})
  b = word[1]
  for i = 1:3
    word[i] = word[i + 1]
  end
  word[4] = b
end

function rcon_xor!(word::Vector{Uint8}, i::Uint8)
  word[1] = word[1] $ xtime_recursive(0x01, i-1)
end

function gen_keys(key::Vector{Uint8}, params::AES_cipher_params)
  i = 0
  key_block = Array(Uint8, 4, params.nb * (1 + params.nr))

  while i < params.nk
    key_block[:, i+1] = key[4i+1:4(i+1)]
    i += 1
  end

  while i < params.nb * (1 + params.nr)
    key_ = key_block[:,i]
    if i % params.nk == 0
      rot_word!(key_)
      sub_word!(key_)
      rcon_xor!(key_, uint8(i / params.nk))
    elseif (params.bits == 256) && (i % params.nk == 4)
      sub_word!(key_)
    end
    key_block[:,i+1] = add_words(key_block[:,i - params.nk + 1], key_)
    i += 1
  end
  key_block
end

function aes_encode(input::Vector{Uint8}, key::Vector{Uint8})
  params = aes_get_cipher_params(length(key) * 8)
  state = copy(reshape(input, 4, 4))
  key_block = gen_keys(key, params)

  add_round_key!(state, key_block[:,1:params.nb])
  i = 1
  while i <= params.nr - 1
    sub_bytes!(state)
    shift_rows!(state)
    mix_columns!(state)
    add_round_key!(state, key_block[:,1 + i*params.nb:(i+1)*params.nb])
    i += 1
  end

  sub_bytes!(state)
  shift_rows!(state)
  add_round_key!(state, key_block[:,1 + i*params.nb:end])

  state
end
