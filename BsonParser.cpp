#include "pch.h"
#include "utils.h"

extern "C" {

    #include "BsonParser.h"
    

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

        // Convert "any" iter value to utf16 str, can be subdocument, array, string...
        wchar_t* convert_bson_iter_value(const bson_iter_t* iter) {
            wchar_t* result = NULL;

            switch (bson_iter_type(iter)) {
            case BSON_TYPE_UTF8: {
                const char* utf8_str = NULL;  // Initialize pointer to NULL for safety
                uint32_t utf8_len = 0;       // Initialize length to 0 for clarity
                utf8_str = bson_iter_utf8(iter, &utf8_len);
                if (utf8_str != NULL) {
                    result = utf8_to_wchar(utf8_str);  // Convert UTF-8 to wchar_t
                }
                else {
                    result = _wcsdup(L"");  // If string is NULL, return an empty wide string
                }
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
                bson_destroy(nested_doc);
                //result = _wcsdup(L"Embedded Document");  // Use _wcsdup instead of wcsdup
                break;
            }

            case BSON_TYPE_ARRAY: {
                const uint8_t* data;
                uint32_t length;
                bson_iter_array(iter, &length, &data);
                bson_t* nested_doc = bson_new_from_data(data, length);
                size_t my_size_t = static_cast<size_t>(length);
                char* _utf8 = bson_array_as_canonical_extended_json(nested_doc, &my_size_t);
                result = (wchar_t*)utils::charToWChar(_utf8);
                //result = utils::bson_t_to_wchar_t(nested_doc);
                bson_free(_utf8);
                bson_destroy(nested_doc);
                break;

            }

            case BSON_TYPE_DATE_TIME: {
                int64_t datetime_val = bson_iter_date_time(iter);
                wchar_t buffer[64];
                swprintf(buffer, sizeof(buffer) / sizeof(wchar_t), L"%" PRId64, datetime_val);
                result = _wcsdup(buffer);  // Use _wcsdup instead of wcsdup
                break;
            }
            //case BSON_TYPE_BINARY: {
            //    const uint8_t* binary_data = NULL;
            //    uint32_t binary_len = 0;
            //    uint8_t binary_subtype = 0;
            //    bson_subtype_t subtype;

            //    bson_iter_binary(iter, &subtype, &binary_len, &binary_data);

            //    // Convert binary data to Base64 (or Hex) string
            //    // We'll use Base64 here for demonstration:
            //    result = (wchar_t*)malloc((binary_len * 2 + 1) * sizeof(wchar_t));
            //    if (result) {
            //        // Base64 encode the binary data (you'd need to implement this or use a library for it)
            //        // For now, let's mock this conversion as a placeholder
            //        // In real code, you'd do something like:
            //        // base64_encode(binary_data, binary_len, result);
            //        wcscpy_s(result, L"Base64EncodedData"); // Placeholder
            //    }
            //    break;
            //}

            case BSON_TYPE_REGEX: {
                const char* regex_pattern;
                const char* regex_options;
                regex_pattern = bson_iter_regex(iter, &regex_options);

                wchar_t* w_regex_pattern = utf8_to_wchar(regex_pattern);
                wchar_t* w_regex_options = utf8_to_wchar(regex_options);

                if (w_regex_pattern && w_regex_options) {
                    wchar_t buffer[256];
                    swprintf(buffer, sizeof(buffer) / sizeof(wchar_t), L"Regex: /%ls/%ls", w_regex_pattern, w_regex_options);
                    result = _wcsdup(buffer);

                    free(w_regex_pattern);
                    free(w_regex_options);
                }
                break;
            }
            default:
                wchar_t buffer[64];
                swprintf(buffer, sizeof(buffer) / sizeof(wchar_t), L"Unknown BSON Type (%d)", bson_iter_type(iter));
                result = _wcsdup(buffer);
                break;
            }

            return result;
        }

        // Function to append a field to BSON document from wchar_t* string
        void append_kv(bson_t* bson, const wchar_t* key, const wchar_t* value) {
            std::string _sk = utils::wide_string_to_string(key);
            std::string _sv = utils::wide_string_to_string(value);
            bson_append_utf8(bson, _sk.c_str(), (int)_sk.length(), _sv.c_str(), (int)_sv.length());
            return;
        }

        void append_bson(bson_t* bson, const wchar_t* key, const wchar_t* value) {
            std::string _sk = utils::wide_string_to_string(key);
            std::string _sv = utils::wide_string_to_string(value);
            bson_append_utf8(bson, _sk.c_str(), (int)_sk.length(), _sv.c_str(), (int)_sv.length());
            return;
        }

        bool insert_bson_at_selector(bson_t* existing_doc, const char* selector, const char* key, const bson_t* new_doc) {
            /* TODO: this function is really complex, i am not sure if we can do it without memory leak actually (bson_destroy must be called everywhere)*/
            bson_iter_t iter;
            bson_iter_t child_iter;
            bson_t updated_doc;
            bson_t child_doc;

            // Initialize the updated BSON document
            bson_init(&updated_doc);

            // If no selector, insert at the root
            if (selector == NULL || strcmp(selector, "") == 0) {
                if (!bson_append_document(existing_doc, key, -1, new_doc)) {
                    fprintf(stderr, "Failed to append BSON document at root.\n");
                    bson_destroy(&updated_doc);
                    return false;
                }
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
                    bson_init(&modified_child_doc);
                    bson_copy_to(&child_doc, &modified_child_doc);

                    // Insert the new BSON document into the sub-document
                    if (!bson_append_document(&modified_child_doc, key, -1, new_doc)) {
                        fprintf(stderr, "Failed to append BSON document to child document.\n");
                        bson_destroy(&modified_child_doc);
                        bson_destroy(&updated_doc);
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
                    fprintf(stderr, "Selector is not a document.\n");
                    bson_destroy(&updated_doc);
                    return false;
                }
            }
            else {
                fprintf(stderr, "Selector not found in existing document.\n");
                bson_destroy(&updated_doc);
                return false;
            }

            // Replace the original document with the updated document
            bson_destroy(existing_doc); // Clean up the original memory
            bson_copy_to(&updated_doc, existing_doc);
            bson_destroy(&updated_doc);

            return true;
        }

    }


}

