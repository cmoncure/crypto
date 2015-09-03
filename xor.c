#include <stdlib.h>
#include "coreystring.h"

cmstring_byte_array * xor_cmstring_byte_arrays (cmstring_byte_array * input_bytes_A, cmstring_byte_array * input_bytes_B) {
    if ( input_bytes_A->len != input_bytes_B->len ) { return NULL; }
    unsigned char out[input_bytes_A->len];
    unsigned long long * out_long = (unsigned long long *) out;
    unsigned long long * in_A_long = (unsigned long long *) input_bytes_A->bytes;
    unsigned long long * in_B_long = (unsigned long long *) input_bytes_B->bytes;
    unsigned long long a_reg_long ;
    unsigned long long b_reg_long ;
    unsigned char a_reg;
    unsigned char b_reg;

    unsigned char rem;
    unsigned char i = 0;
    cmstring_byte_array * output_bytes = cmstring_new_byte_array(input_bytes_A->len);

    rem = input_bytes_A->len % 8;
    while ( i * 8 < input_bytes_A->len - rem ) {
        a_reg_long = in_A_long[i];
        b_reg_long = in_B_long[i];
        out_long[i] = a_reg_long ^ b_reg_long;
        i++;
    }

    if ( rem ) {
        i *= 8;
        while ( i < input_bytes_A->len ) {
            a_reg = input_bytes_A->bytes[i];
            b_reg = input_bytes_B->bytes[i];
            out[i] = a_reg ^ b_reg;
            i++;
        }
    }

    cmstring_set_byte_array(out, input_bytes_A->len, output_bytes);
    return output_bytes;
}
