export hex_string_to_base64

function hex_string_to_base64(str)
  str = hex2bytes(str)
  str = base64(str)
  return str
end
