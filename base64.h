#ifndef BASE64_H_INCLUDED
#define BASE64_H_INCLUDED
#include "coreystring.h"

cmstring_byte_array * cmstring_byte_array_to_base64(cmstring_byte_array * input_bytes);
cmstring_byte_array * hex_format_string_to_bytes (cmstring_byte_array * input_bytes);
cmstring_byte_array * hex_format_c_string_to_base64 (unsigned char input_string[], size_t input_len);

#endif // BASE64_H_INCLUDED
