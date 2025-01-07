#include "pch.h"
#include "utils.h"
#include "MongoCBridge.h"
#include <cwchar> 
#include <cstring>
#include "common.h"

namespace utils {

    void bsonErrtoStruct(bson_error_t error, ErrorStruct* err) {
        err->code = error.code;
        wcscpy_s(err->message, BSON_ERROR_BUFFER_SIZE, utils::charToWChar(error.message));
    }

    void charErrtoStruct(int code, const char* msg, ErrorStruct* err) {
        err->code = code;
        wcscpy_s(err->message, BSON_ERROR_BUFFER_SIZE, utils::charToWChar(msg));
    }

    const wchar_t* charToWChar(const char* message) {
        // Get the length of the message
        size_t len = std::strlen(message);
        wchar_t* wideMessage = new wchar_t[len + 1]; // +1 for null terminator
        size_t i;
        for (i = 0; i < len; ++i) {
            wideMessage[i] = static_cast<wchar_t>(message[i]);
        }

        // Null-terminate the wide string
        wideMessage[i] = L'\0';

        return wideMessage;
    }

    std::string wide_string_to_string(const std::wstring& wide_string)
    {
        if (wide_string.empty())
        {
            return "";
        }

        const auto size_needed = WideCharToMultiByte(CP_UTF8, 0, wide_string.data(), (int)wide_string.size(), nullptr, 0, nullptr, nullptr);
        if (size_needed <= 0)
        {
            throw std::runtime_error("WideCharToMultiByte() failed: " + std::to_string(size_needed));
        }

        std::string result(size_needed, 0);
        WideCharToMultiByte(CP_UTF8, 0, wide_string.data(), (int)wide_string.size(),(LPSTR) result.data(), size_needed, nullptr, nullptr);
        return result;
    }

    wchar_t* string_to_wide_string(std::string& narrow_string)
    {
        if (narrow_string.empty())
        {
            static wchar_t empty_wide_string[] = L"";
            return empty_wide_string;
        }

        const auto size_needed = MultiByteToWideChar(CP_UTF8, 0, narrow_string.data(), (int)narrow_string.size(), nullptr, 0);
        if (size_needed <= 0)
        {
            throw std::runtime_error("MultiByteToWideChar() failed: " + std::to_string(size_needed));
        }

        // Allocate a buffer for the wide string
        static thread_local std::wstring result; // Thread-local storage to handle thread safety
        result.resize(size_needed);

        MultiByteToWideChar(CP_UTF8, 0, narrow_string.data(), (int)narrow_string.size(), (LPWSTR) result.data(), size_needed);
        return (wchar_t*)result.data(); // Return a C-style wide string
    }

    bson_t* wchar_to_bson_t(wchar_t* what) {
        bson_error_t error;
        std::string _utf8 = utils::wide_string_to_string(what);
        bson_t* _bson = bson_new_from_json((const uint8_t*)_utf8.c_str(), _utf8.size(), &error);
        if (error.code) {
            fprintf(stderr, "bson_new_from_json error: %s\n", error.message);
            SetLastError(error.code);
            return NULL;
        }
        return _bson;
    }

    wchar_t* bson_t_to_wchar_t(bson_t* what) {
        char* utf8json = bson_as_relaxed_extended_json(what, NULL);
        std::string s_utf8 = std::string(utf8json);
        wchar_t* converted = utils::string_to_wide_string(s_utf8);
        return converted;
    }

    bool IsBadReadPtr(void* p)
    {
        /* protects against reading inaccesible address pointers like 0x000000000001 */
        MEMORY_BASIC_INFORMATION mbi = { 0 };
        if (::VirtualQuery(p, &mbi, sizeof(mbi)))
        {
            DWORD mask = (PAGE_READONLY | PAGE_READWRITE | PAGE_WRITECOPY | PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY);
            bool b = !(mbi.Protect & mask);
            // check the page is not a guard page
            if (mbi.Protect & (PAGE_GUARD | PAGE_NOACCESS)) b = true;

            return b;
        }
        return true;
    }

    int is_valid_wstring(wchar_t* str) {
        // Check if the pointer is null
        if (str == NULL) {
            return 0;
        }
        if (IsBadReadPtr(str)) {
            return 0;
        }

        // Use wcslen to check for null termination
        // wcslen returns the length of the string if it's valid
        // If `str` is invalid, behavior is undefined, so we assume it's valid if `wcslen` completes.
        size_t length = wcslen(str);
        (void)length;  // Avoid unused variable warning if needed
        return 1;  // Valid string
    }

    /* BSON UTILS*/
    static bool lookup_string(
        const bson_t* bson, const char* key, const char** out, const char* source, mongoc_bulkwriteexception_t* exc)
    {
        BSON_ASSERT_PARAM(bson);
        BSON_ASSERT_PARAM(key);
        BSON_ASSERT_PARAM(out);
        BSON_OPTIONAL_PARAM(source);
        BSON_ASSERT_PARAM(exc);

        bson_iter_t iter;
        if (bson_iter_init_find(&iter, bson, key) && BSON_ITER_HOLDS_UTF8(&iter)) {
            *out = bson_iter_utf8(&iter, NULL);
            return true;
        }
        bson_error_t error;
        if (source) {
            bson_set_error(&error,
                MONGOC_ERROR_COMMAND,
                MONGOC_ERROR_COMMAND_INVALID_ARG,
                "expected to find string `%s` in %s, but did not",
                key,
                source);
        }
        else {
            bson_set_error(&error,
                MONGOC_ERROR_COMMAND,
                MONGOC_ERROR_COMMAND_INVALID_ARG,
                "expected to find string `%s`, but did not",
                key);
        }
        
        return false;
    }


}
