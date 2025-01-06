#include "pch.h"
#include <bson.h>
#include <stdio.h>
#include <wchar.h>
#include <locale.h>
#include <stdlib.h>

namespace bsonparser {
    wchar_t* convert_bson_iter_value(const bson_iter_t* iter);
    void append_kv(bson_t* bson, const wchar_t* key, const wchar_t* value);
    bool insert_bson_at_selector(bson_t* existing_doc, const char* selector, const char* key, const bson_t* new_doc);
}