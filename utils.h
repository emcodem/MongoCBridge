#ifndef UTILS_H
#define UTILS_H

#include <string>
#include <stdexcept>
#include <Windows.h>
#include <bson.h>

namespace utils {

    // Converts a wide string (std::wstring) to a narrow string (std::string) in UTF-8 format.
    std::string wide_string_to_string(const std::wstring& wide_string);

    // Converts a narrow string (std::string) in UTF-8 format to a wide string (wchar_t*).
    wchar_t* string_to_wide_string(std::string& narrow_string);

    // Converts a wchar_t* to a BSON object.
    bson_t* wchar_to_bson_t(wchar_t* what);

    // Converts a BSON object to a wchar_t*.
    wchar_t* bson_t_to_wchar_t(bson_t* what);

    // Checks if a pointer is pointing to an invalid or inaccessible memory address.
    bool IsBadReadPtr(void* p);

    // Validates whether the given wchar_t* is a valid null-terminated wide string.
    int is_valid_wstring(wchar_t* str);

} // namespace utils

#endif // UTILS_H