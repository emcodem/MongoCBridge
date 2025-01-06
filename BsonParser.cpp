#include "pch.h"
#include "BsonParser.h"
#include "utils.h"

namespace bsonparser {

    // Function to convert UTF-8 string to wchar_t (UTF-16 on Windows, UTF-32 on Linux/macOS)
    wchar_t* utf8_to_wchar(const char* utf8_str) {
        size_t len = 0;
        errno_t err = mbstowcs_s(&len, NULL, 0, utf8_str, _TRUNCATE);  // Get the required buffer size
        if (err != 0) {
            return NULL;  // Conversion failed
        }

        wchar_t* wstr = (wchar_t*)malloc((len + 1) * sizeof(wchar_t));
        if (wstr != NULL) {
            err = mbstowcs_s(&len, wstr, len + 1, utf8_str, _TRUNCATE);  // Convert UTF-8 to wide string
            if (err != 0) {
                free(wstr);
                return NULL;  // Conversion failed
            }
        }

        return wstr;
    }

    // Function to handle BSON value and return wchar_t string
    wchar_t* convert_bson_iter_value(const bson_iter_t* iter) {
        wchar_t* result = NULL;

        switch (bson_iter_type(iter)) {
        case BSON_TYPE_UTF8: {
            const char* utf8_str;
            uint32_t utf8_len;
            utf8_str = bson_iter_utf8(iter, &utf8_len);
            result = utf8_to_wchar(utf8_str);  // Convert UTF-8 string to wchar_t
            break;
        }

        case BSON_TYPE_INT32: {
            int32_t int32_val = bson_iter_int32(iter);
            wchar_t buffer[64];
            swprintf(buffer, sizeof(buffer) / sizeof(wchar_t), L"%d", int32_val);
            result = _wcsdup(buffer);  // Use _wcsdup instead of wcsdup
            break;
        }

        case BSON_TYPE_INT64: {
            int64_t int64_val = bson_iter_int64(iter);
            wchar_t buffer[64];
            swprintf(buffer, sizeof(buffer) / sizeof(wchar_t), L"%lld", int64_val);
            result = _wcsdup(buffer);  // Use _wcsdup instead of wcsdup
            break;
        }

        case BSON_TYPE_DOUBLE: {
            double double_val = bson_iter_double(iter);
            wchar_t buffer[64];
            swprintf(buffer, sizeof(buffer) / sizeof(wchar_t), L"%f", double_val);
            result = _wcsdup(buffer);  // Use _wcsdup instead of wcsdup
            break;
        }

        case BSON_TYPE_BOOL: {
            bool bool_val = bson_iter_bool(iter);
            result = bool_val ? _wcsdup(L"true") : _wcsdup(L"false");  // Use _wcsdup instead of wcsdup
            break;
        }

        case BSON_TYPE_NULL: {
            result = _wcsdup(L"null");  // Use _wcsdup instead of wcsdup
            break;
        }

        case BSON_TYPE_DOCUMENT: {
            // Handle document (for simplicity, return a placeholder)
            const uint8_t* data;
            uint32_t length;
            bson_iter_document(iter, &length, &data);
            bson_t* nested_doc = bson_new_from_data(data, length);
            result = utils::bson_t_to_wchar_t(nested_doc);
            //result = _wcsdup(L"Embedded Document");  // Use _wcsdup instead of wcsdup
            break;
        }

        case BSON_TYPE_ARRAY: {
            const uint8_t* data;
            uint32_t length;
            bson_iter_array(iter, &length, &data);
            bson_t* nested_doc = bson_new_from_data(data, length);
            result = utils::bson_t_to_wchar_t(nested_doc);
            break;
            //todo: use this?
            //https://mongoc.org/libbson/current/bson_array_as_canonical_extended_json.html
            //bson_array_as_canonical_extended_json (const bson_t *bson, size_t *length);
           

        }

        case BSON_TYPE_DATE_TIME: {
            int64_t datetime_val = bson_iter_date_time(iter);
            wchar_t buffer[64];
            swprintf(buffer, sizeof(buffer) / sizeof(wchar_t), L"%" PRId64, datetime_val);
            result = _wcsdup(buffer);  // Use _wcsdup instead of wcsdup
            break;
        }

        case BSON_TYPE_REGEX: {
            const char* regex_pattern = bson_iter_regex(iter, NULL);
            const char* regex_options = bson_iter_regex(iter, NULL);

            // Convert regex_pattern and regex_options to wide-character strings
            wchar_t* w_regex_pattern = utf8_to_wchar(regex_pattern);
            wchar_t* w_regex_options = utf8_to_wchar(regex_options);

            if (w_regex_pattern && w_regex_options) {
                wchar_t buffer[256];
                swprintf(buffer, sizeof(buffer) / sizeof(wchar_t), L"Regex: /%ls/%ls", w_regex_pattern, w_regex_options);
                result = _wcsdup(buffer);  // Use _wcsdup instead of wcsdup

                // Clean up memory allocated for regex strings
                free(w_regex_pattern);
                free(w_regex_options);
            }
            break;
        }

        default:
            result = _wcsdup(L"Unknown BSON Type");  // Use _wcsdup instead of wcsdup
            break;
        }

        return result;
    }

    // Function to append a field to BSON document from wchar_t* string
    void append_kv(bson_t* bson, const wchar_t* key, const wchar_t* value) {
        // Convert wide-character string to UTF-8
        std::string _sk = utils::wide_string_to_string(key);
        std::string _sv = utils::wide_string_to_string(value);
        bson_append_utf8(bson, _sk.c_str(), (int)_sk.length(), _sv.c_str(), (int)_sv.length());
        return;
    }

    void append_bson(bson_t* bson, const wchar_t* key, const wchar_t* value) {
        // Convert wide-character string to UTF-8
        std::string _sk = utils::wide_string_to_string(key);
        std::string _sv = utils::wide_string_to_string(value);
        bson_append_utf8(bson, _sk.c_str(), (int)_sk.length(), _sv.c_str(), (int)_sv.length());
        return;
    }


    bool insert_bson_at_selector(bson_t* existing_doc, const char* selector, const char* key, const bson_t* new_doc) {
        bson_iter_t iter;
        bson_iter_t child_iter;
        bson_t updated_doc;
        bson_t child_doc;

        // Initialize the updated BSON document
        bson_init(&updated_doc);

        //if no selector, insert at root
        if (selector == NULL || strcmp(selector, "") == 0) {
            bson_append_document(existing_doc, key, -1, new_doc);
            return true;
        }

        // Find the selector in the existing document
        if (bson_iter_init(&iter, existing_doc) && bson_iter_find_descendant(&iter, selector, &child_iter)) {
            if (BSON_ITER_HOLDS_DOCUMENT(&child_iter)) {
                const uint8_t* doc_data;
                uint32_t doc_len;

                // Get the sub-document at the selector position
                bson_iter_document(&child_iter, &doc_len, &doc_data);
                bson_init_static(&child_doc, doc_data, doc_len);

                // Make a copy of the sub-document to modify it
                bson_t modified_child_doc;
                bson_copy_to(&child_doc, &modified_child_doc);

                // Insert the new BSON document into the sub-document
                if (!bson_append_document(&modified_child_doc, key, -1, new_doc)) {
                    fprintf(stderr, "Failed to append BSON document to child document\n");
                    bson_destroy(&modified_child_doc);
                    return false;
                }

                // Rebuild the updated document by copying existing fields and replacing the modified child
                bson_iter_init(&iter, existing_doc);
                while (bson_iter_next(&iter)) {
                    const char* field_key = bson_iter_key(&iter);
                    if (strcmp(field_key, selector) == 0) {
                        bson_append_document(&updated_doc, field_key, -1, &modified_child_doc);
                    }
                    else {
                        bson_append_value(&updated_doc, field_key, -1, bson_iter_value(&iter));
                    }
                }

                bson_destroy(&modified_child_doc);
            }
            else {
                bson_append_document(existing_doc, key, -1, new_doc);
                fprintf(stderr, "Selector is not a document.\n");
                return false;
            }
        }
        else {
            bson_append_document(existing_doc, key, -1, new_doc);
            fprintf(stderr, "Selector not found in existing document.\n");
            return false;
        }

        // Replace the original document with the updated document
        bson_copy_to(&updated_doc, existing_doc);
        bson_destroy(&updated_doc);

        return true;
    }

}
