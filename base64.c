#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "coreystring.h"

#define DEBUG 1

const unsigned char base64_table[64] = "ABCDEFGH" "IJKLMNOP" "QRSTUVWX" "YZabcdef" "ghijklmn" "opqrstub" "wxyz0123" "456789+/";
const unsigned char hex_table[16] = "0123456789abcdef";
const unsigned char pad_char[] = "=";

cmstring_byte_array * cmstring_byte_array_to_base64(cmstring_byte_array * input_bytes) {
    int s_idx = 0;
    int d_idx = 0;
    size_t buf;
    signed int i;

    size_t input_len = input_bytes->len;
    unsigned int padding = input_len % 3;
    size_t output_length_bytes = 4 * (input_len - padding) / 3;
    if ( padding != 0 ) {output_length_bytes += 4;}

    cmstring_byte_array * output_bytes = cmstring_new_byte_array(output_length_bytes);

    while (s_idx < input_len) {
        buf = 0;
        i = 2;
        while ( s_idx < input_len && i > -1 ) {
            buf += input_bytes->bytes[s_idx++] << (8 * i);
            i--;
        }

        i = 3;
        while ( d_idx < output_length_bytes && i > -1 ) {
            output_bytes->bytes[d_idx++] = base64_table[(buf & 0x3F << (6 * i)) >> (6 * i)];
            i--;
        }
    }

    if ( padding > 0 ) {
        i = output_length_bytes;
        while ( i < 3 - padding ) {
            output_bytes->bytes[i - 1] = pad_char[0];
            i--;
        }
    }

    return output_bytes;
}

cmstring_byte_array * hex_format_string_to_bytes (cmstring_byte_array * input_bytes) {
    int i;
    unsigned char lookup_digit[1];
    unsigned char d1;
    unsigned char d2;
    size_t output_len = (input_bytes->len) / 2;
    cmstring_byte_array * output_bytes = cmstring_new_byte_array(output_len);

    for (i = 0; i < output_len; i++) {
        lookup_digit[0] = input_bytes->bytes[2 * i];
        d1 = strcspn(hex_table, lookup_digit);
        lookup_digit[0] = input_bytes->bytes[(2 * i) + 1];
        d2 = strcspn(hex_table, lookup_digit);
        output_bytes->bytes[i] = d1 * 16 + d2;
    }

    return output_bytes;
}


cmstring_byte_array * hex_format_c_string_to_base64 (unsigned char input_string[], size_t input_len) {
    cmstring_byte_array * input_bytes = cmstring_new_byte_array(input_len - 1);
    cmstring_set_byte_array(input_string, input_len - 1, input_bytes);
    cmstring_byte_array * as_bytes = hex_format_string_to_bytes(input_bytes);
    cmstring_byte_array * as_base64 = cmstring_byte_array_to_base64(as_bytes);
    return as_base64;
}
