#include "pch.h"
#include "BsonBridge.h"
#include "utils.h"
#include <string.h>
/*
    Prototype to expose native bson functions, we used that for benchmarking.
    The plan can be to allow the user of MongoCbridge to either work with wchar*t or with bson*t which should improve performance dramatically
*/
extern "C"
{

    // DLL Exports
    #define DECLDIR __declspec(dllexport)
    DECLDIR bson_t* _bson_new_from_json(wchar_t* utf16String, struct ErrorStruct* err) {
        bson_error_t error;
        std::string _json = utils::wide_string_to_string(utf16String);
        bson_t* parsed_bson = bson_new_from_json((const uint8_t*)_json.c_str(), _json.size(), &error);
        return parsed_bson;
    }

    DECLDIR void _bson_destroy(bson_t* b) {
        bson_destroy(b);
    }

    DECLDIR wchar_t* _bson_as_canonical_extended_json(bson_t* b) {
        char* json_out = bson_as_canonical_extended_json(b, NULL);
        std::string sjout(json_out);
        wchar_t* result = utils::string_to_wide_string(sjout);  // Convert the JSON back to wchar_t*
        return result;
    }

    DECLDIR wchar_t* _bson_as_relaxed_extended_json(bson_t* b) {
        char* json_out = bson_as_relaxed_extended_json(b, NULL);
        std::string sjout(json_out);
        wchar_t* result = utils::string_to_wide_string(sjout);  // Convert the JSON back to wchar_t*
        return result;
    }

    DECLDIR bool _append_binary_data_with_dot_notation(bson_t* doc, wchar_t* selector, uint8_t* binary_data, uint32_t binary_len) {
        /* this function is just for playing around, it kind of works */
        bson_iter_t iter;
        bson_t parent, temp;
        std::string spath = utils::wide_string_to_string(selector);

        // Find the last dot in the selector to separate the parent path and the key
        size_t dot_pos = spath.find_last_of('.');
        if (dot_pos != std::string::npos) {
            // Extract parent path (everything before the last dot) and key (after the last dot)
            std::string parent_path = spath.substr(0, dot_pos);
            std::string key = spath.substr(dot_pos + 1);

            // Check if the parent document exists
            if (bson_iter_init_find(&iter, doc, parent_path.c_str()) && BSON_ITER_HOLDS_DOCUMENT(&iter)) {
                const uint8_t* data = NULL;
                uint32_t data_len = 0;

                // Extract the existing parent document
                bson_iter_document(&iter, &data_len, &data);
                bson_init_static(&parent, data, data_len);
            }
            else {
                // If the parent document doesn't exist, initialize a new one
                bson_init(&parent);
            }

            // Append the binary data to the child document under the specified key
            if (!bson_append_binary(&parent, key.c_str(), -1, BSON_SUBTYPE_BINARY, binary_data, binary_len)) {
                bson_destroy(&parent);
                return false; // Failed to append binary data
            }

            // Replace or insert the parent document back into the main document
            if (!bson_append_document(doc, parent_path.c_str(), -1, &parent)) {
                bson_destroy(&parent);
                return false; // Failed to append the parent document
            }

            bson_destroy(&parent);
        }
        else {
            // No dot notation; directly append the binary data to the top-level document
            if (!bson_append_binary(doc, spath.c_str(), -1, BSON_SUBTYPE_BINARY, binary_data, binary_len)) {
                return false; // Failed to append binary data
            }
        }

        return true; // Success
    }
    



}