export fixed_length_xor

function fixed_length_xor (bytes_A, bytes_B)
  @assert sizeof(bytes_A) == sizeof(bytes_B)
  i = 1
  while (i <= sizeof(bytes_A))
    bytes_B[i] = bytes_A[i] $ bytes_B[i]
    i += 1
  end
  return bytes_B
end