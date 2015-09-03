#include <stdio.h>
#include <stdlib.h>
#include "base64.h"
#include "coreystring.h"

int main()
{
    unsigned char teststr[] = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d";
    cmstring_byte_array * as_base64 = hex_format_c_string_to_base64(teststr, sizeof teststr);
    cmstring_print_all();
    cmstring_cleanup_all();
    return 0;
}
