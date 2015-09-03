#include <stdio.h>
#include <stdlib.h>
#include "base64.h"
#include "coreystring.h"

void test_base64(){
    unsigned char teststr[] = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d";
    cmstring_byte_array * as_base64 = hex_format_c_string_to_base64(teststr, sizeof teststr);
}

void test_xor() {
    unsigned char teststr_A[] = "1c0111001f010100061a024b53535009181c";
    unsigned char teststr_B[] = "686974207468652062756c6c277320657965";
    cmstring_byte_array * input_A = hex_format_c_string_to_byte_array(teststr_A, sizeof(teststr_A));
    cmstring_byte_array * input_B = hex_format_c_string_to_byte_array(teststr_B, sizeof(teststr_B));
    cmstring_byte_array * output = xor_cmstring_byte_arrays(input_A, input_B);
    cmstring_byte_array * as_hex = bytes_to_hex_format_string(output);
}

int main() {
    test_base64();
    test_xor();

    cmstring_print_all();
    cmstring_cleanup_all();
    return 0;
}
