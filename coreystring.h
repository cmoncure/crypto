#ifndef COREYSTRING_H_INCLUDED
#define COREYSTRING_H_INCLUDED

typedef struct {
    size_t len;
    unsigned char * bytes;
    signed int alive;
} cmstring_byte_array;

void cmstring_set_byte_array (unsigned char * bytes, size_t len, cmstring_byte_array * byte_array);
cmstring_byte_array * hex_format_c_string_to_byte_array (unsigned char input_string[], size_t input_len);
cmstring_byte_array * bytes_to_hex_format_string (cmstring_byte_array * input_bytes);
cmstring_byte_array * cmstring_new_byte_array (size_t len);
void cmstring_cleanup_all();
void cmstring_print_all();

#endif // COREYSTRING_H_INCLUDED
