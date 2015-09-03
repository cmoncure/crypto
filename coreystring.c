#include <stdlib.h>

typedef struct {
    size_t len;
    unsigned char * bytes;
    signed int alive;
} cmstring_byte_array;

typedef struct cmstring_link cmstring_link;

struct cmstring_link {
    cmstring_byte_array * object_ptr;
    cmstring_link * next_ptr;
    cmstring_link * prev_ptr;
};

typedef struct {
    unsigned int len;
    cmstring_link * first_ptr;
} cmstring_list_header;

cmstring_list_header list_head;

cmstring_link * cmstring_new_link (cmstring_byte_array * object) {
    cmstring_link * new_link = malloc(sizeof(cmstring_link));
    new_link->object_ptr = object;
    return new_link;
}

cmstring_link * cmstring_link_from_index (unsigned int idx) {
    cmstring_link * link_ptr;
    if ( idx > list_head.len || list_head.len == 0 ) {
        return NULL;
    } else {
        link_ptr = list_head.first_ptr;
        while ( idx > 0 ) {
            link_ptr = link_ptr->next_ptr;
            idx--;
        }
    }
    return link_ptr;
}

void cmstring_destroy_link (cmstring_link * link) {
    free(link->object_ptr->bytes);
    free(link->object_ptr);
    free(link);
    return;
}

void cmstring_remove_link (cmstring_link * link) {
    if ( link->next_ptr && link->prev_ptr ) {
        link->prev_ptr->next_ptr = link->next_ptr;
        link->next_ptr->prev_ptr = link->prev_ptr;
        cmstring_destroy_link(link);
    } else if ( link-> next_ptr ) {
    // first in list
        list_head.first_ptr = link->next_ptr;
        link->next_ptr->prev_ptr = NULL;
        cmstring_destroy_link(link);
    } else {
    // last in list
        if ( list_head.len == 1 ) {
            list_head.first_ptr = NULL;
        } else {
        link->prev_ptr->next_ptr = NULL;
        }
        cmstring_destroy_link(link);
    }
    list_head.len--;
    return;
}

void cmstring_insert_link_at_index (cmstring_link * new_link, unsigned int idx) {
    cmstring_link * cur_link = cmstring_link_from_index(idx);
    if ( idx == 0 ) { // first item
        cur_link->prev_ptr = new_link;
        list_head.first_ptr = new_link;
    } else if ( idx == list_head.len ) { // last item
        cur_link->next_ptr = new_link;
        new_link->prev_ptr = cur_link;
    } else { // in between
        cur_link->prev_ptr->next_ptr = new_link;
        cur_link->prev_ptr = new_link;
    }
    list_head.len++;
    return;
}

void cmstring_append_link (cmstring_link * new_link) {
    if ( list_head.len == 0 ) { // list is empty!
        list_head.first_ptr = new_link;
    } else {
        cmstring_link * final_link = cmstring_link_from_index(list_head.len - 1);
        new_link->prev_ptr = final_link;
        final_link->next_ptr = new_link;
    }
    list_head.len++;
    return;
}

void cmstring_cleanup_all () {
    while ( list_head.len > 0 ) {
        cmstring_remove_link(list_head.first_ptr);
    }
    return;
}

void cmstring_cleanup () {
    unsigned int idx = list_head.len;
    cmstring_link * link_ptr = cmstring_link_from_index(idx);
    cmstring_link * next_ptr = NULL;
    while ( idx > 0 ) {
        if ( link_ptr->object_ptr->alive < 0 ) {
            next_ptr = link_ptr->prev_ptr;
            cmstring_destroy_link(link_ptr);
            link_ptr = next_ptr;
        } else {
            link_ptr = link_ptr->prev_ptr;
        }
        idx--;
    }
}

void cmstring_set_byte_array (unsigned char * bytes, size_t len, cmstring_byte_array * byte_array) {
    if ( byte_array->bytes == NULL ) {
        byte_array->bytes = malloc(sizeof(unsigned char) * len);
        byte_array->len = len;
    } else if ( byte_array->len != len ){
        realloc(byte_array->bytes, len);
        byte_array->len = len;
    }
    memcpy(byte_array->bytes, bytes, len * sizeof(unsigned char));

    return;
}

cmstring_byte_array * cmstring_new_byte_array (size_t len) {
    cmstring_byte_array * new_array = malloc(sizeof(cmstring_byte_array));
    if ( len == 0 ) {
        new_array->len = 0;
        new_array->bytes = NULL;
    } else {
        new_array->len = len;
        new_array->bytes = malloc(sizeof(unsigned char) * len);
    }
    cmstring_link * new_link = cmstring_new_link(new_array);
    cmstring_append_link(new_link);
    return new_array;
}

unsigned char * cmstring_byte_array_to_c_str(cmstring_byte_array * byte_array) {
    size_t len_str = byte_array->len + 1;
    unsigned char as_str[len_str];
    memcpy(as_str, byte_array->bytes, byte_array->len * sizeof(unsigned char));
    as_str[len_str - 1] = 0x00;
    return as_str;
}

void cmstring_print_all () {
    int idx = 0;
    if ( list_head.first_ptr == NULL ) {
        return;
    }
    cmstring_link * link = list_head.first_ptr;
    while (1) {
        printf("%03i ", idx);
        printf(link->object_ptr->bytes);
        printf("\n");
        if ( link->next_ptr ) {
            link = link->next_ptr;
            idx++;
        } else {break;}
    }
}
