#include "pch.h"
#include "BsonBridge.h"
#include "utils.h"
#define DECLDIR __declspec(dllexport)

/*
    Prototype to expose native bson functions, we used that for benchmarking.
    The plan can be to allow the user of MongoCbridge to either work with wchar*t or with bson*t which should improve performance dramatically
*/
extern "C"
{
    // DLL Exports

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



}