#include "pch.h"
#include <iostream>
#include <Windows.h> 
#include "MongoCBridge.h"
#include <iostream>
#include <string>
#include <cwchar> // For wide character functions

//
//using bsoncxx::builder::basic::kvp;
//using bsoncxx::builder::basic::make_document;

using namespace std;

extern "C"
{



    DECLDIR wchar_t* Echo(wchar_t* utf16String)
    {
        if (utf16String == nullptr) {
            std::wcout << L"Received NULL pointer!" << std::endl;
        }
        std::wcout << L"You wrote: [" << utf16String << L"]" << std::endl;
        const wchar_t* prefix = L"You wrote: ";
        size_t prefixLength = std::wcslen(prefix);
        size_t inputLength = std::wcslen(utf16String);
        wchar_t* result = new wchar_t[prefixLength + inputLength + 1]; // +1 for null terminator
        //create a new wchar_t concatting prefix and original string
        wcscpy_s(result, prefixLength + 1, prefix);
        wcscat_s(result, prefixLength + inputLength + 1, utf16String); // +1 for the null terminator
        return result; // Caller is responsible for freeing the memory
    }

    DECLDIR mongoc_collection_t* CreateCollection(wchar_t* utf16_conn_str, wchar_t* db_name, wchar_t* collection_name )
    {
        mongoc_collection_t* c = impl::_CreateCollection(utf16_conn_str,db_name,collection_name);
        return c;
    }

    DECLDIR int InsertOne(mongoc_collection_t* c, wchar_t* utf16String)
    {
        return impl::_InsertOne(c, utf16String);
    }

    DECLDIR wchar_t* FindOne(mongoc_collection_t* c, wchar_t* query)
    {
        return impl::_FindOne(c, query);
    }

    DECLDIR wchar_t* UpdateOne(mongoc_collection_t* c, wchar_t* utf16_search, wchar_t* utf16_update, wchar_t* utf16_options)
    {
        return impl::_UpdateOne(c, utf16_search, utf16_update, utf16_options);
    }

    DECLDIR int DeleteOne(mongoc_collection_t* c, wchar_t* utf16_search)
    {
        return impl::_DeleteOne(c, utf16_search);
    }
}

namespace utils {

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
        WideCharToMultiByte(CP_UTF8, 0, wide_string.data(), (int)wide_string.size(), result.data(), size_needed, nullptr, nullptr);
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

        MultiByteToWideChar(CP_UTF8, 0, narrow_string.data(), (int)narrow_string.size(), result.data(), size_needed);
        return result.data(); // Return a C-style wide string
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
}


namespace impl {

    mongoc_collection_t* _CreateCollection(wchar_t* utf16_conn_str, wchar_t* db_name, wchar_t* collection_name) {
     
        try {
            mongoc_init();
            std::string connstr;
            if (utf16_conn_str == nullptr || wcslen(utf16_conn_str) == 0) {
                connstr = "mongodb://localhost:27017";
            }
            else {
                connstr = utils::wide_string_to_string(utf16_conn_str);
            } 
            std::string s_db_name;
            if (db_name == nullptr || wcslen(db_name) == 0) {
                s_db_name = "Default_Database";
            }
            else {
                s_db_name = utils::wide_string_to_string(db_name);
            }
            std::string s_collection_name;
            if (collection_name == nullptr || wcslen(collection_name) == 0) {
                s_collection_name = "Default_Collection";
            }
            else {
                s_collection_name = utils::wide_string_to_string(collection_name);
            }
            const char* uri_string = connstr.c_str();
            mongoc_uri_t* uri;
            bson_error_t error;
            uri = mongoc_uri_new_with_error(uri_string, &error);
            if (!uri) {
                fprintf(stderr,
                    "mongoc_uri_new_with_error failed to parse URI: %s\n"
                    "error message:       %s\n",
                    uri_string,
                    error.message);
                SetLastError(error.code);
                return NULL;
            }

            mongoc_client_t* client = mongoc_client_new_from_uri(uri);
            if (!client) {
                fprintf(stderr,
                    "mongoc_client_new_from_uri error, message: %s",
                    error.message);
                SetLastError(error.code);
                return NULL;
            }

            mongoc_client_set_appname(client, "mongo_c_dll");
            database = mongoc_client_get_database(client, s_db_name.c_str());
            //create collection in case it does not exist
            mongoc_database_create_collection(database, s_collection_name.c_str(), NULL, &error);
            collection = mongoc_client_get_collection(client, s_db_name.c_str(), s_collection_name.c_str());

            return collection;

        }
        catch (const std::exception& xcp) {
            std::cout << "connection failed: " << xcp.what() << "\n";
            return NULL;
        }
    }

    int _InsertOne(mongoc_collection_t* c, wchar_t* utf16String) {

        bson_error_t error;
        bson_t* b;

        std::string yip = utils::wide_string_to_string(utf16String);
        b = bson_new_from_json((const uint8_t*)yip.c_str(), yip.size(), &error); 

        if (!mongoc_collection_insert_one(
            collection, b, NULL, NULL, &error)) {
            fprintf(stderr, "mongoc_collection_insert_one error: %s\n", error.message);
            SetLastError(error.code);
            return 1;
        }

        bson_destroy(b);
        return 0;
    }

    wchar_t* _FindOne(mongoc_collection_t* c, wchar_t* utf16_query_json)
    {
        bson_t* filter;
        const bson_t* doc;
        bson_error_t error;
        //bson_t* filter = BCON_NEW("filename", BCON_UTF8("Processors\\db\\configs\\workflows\\20230625-1518-1896-1790-0dda9dfc0f34.json"));
        std::string utf8_query = utils::wide_string_to_string(utf16_query_json);
        filter = bson_new_from_json((const uint8_t*)utf8_query.c_str(), utf8_query.size(), &error);
        mongoc_cursor_t* results = mongoc_collection_find_with_opts(collection, filter, NULL, NULL);
        
        while (mongoc_cursor_next(results, &doc)) {
            char* charptr = bson_as_canonical_extended_json(doc, NULL);
            std::string str(charptr);
            wchar_t * result = utils::string_to_wide_string(str);
            bson_free(charptr);
            mongoc_cursor_destroy(results);
            return result;
        }

        if (mongoc_cursor_error(results, &error)) {
            fprintf(stderr, "mongoc_collection_find_with_opts Error: %s\n", error.message);
            SetLastError(error.code);
            return 0;
        }
        //if no result found, return empty result
        fprintf(stderr, "FindOne mongoc_collection_find_with_opts graceful but got no results for query.\n");
        mongoc_cursor_destroy(results);
        bson_destroy(filter);
        return 0;
    }

    wchar_t* _UpdateOne(mongoc_collection_t* c, wchar_t* utf_16_selector, wchar_t* utf_16_update, wchar_t* utf_16_options)
    {
        bson_error_t error;

        if (!utils::is_valid_wstring(utf_16_selector)) {
            SetLastError(2);
            fprintf(stderr, "update failed because selector was not a valid value\n");
            return NULL;
        }
        if (!utils::is_valid_wstring(utf_16_update)) {
            SetLastError(2);
            fprintf(stderr, "update failed because update was not a valid value\n");
            return NULL;
        }
        if (!utils::is_valid_wstring(utf_16_options)) {
            utf_16_options = (wchar_t*)L"{}";
        }

        bson_t* selector    = utils::wchar_to_bson_t(utf_16_selector);
        bson_t* update      = utils::wchar_to_bson_t(utf_16_update);
        bson_t* opts        = utils::wchar_to_bson_t(utf_16_options);
        bson_t* reply       = bson_new();

        if (!mongoc_collection_update_one(c, selector, update, opts, reply, &error)) {
            SetLastError(error.code);
            fprintf(stderr, "update failed: %s\n", error.message);
            return NULL;
        }
        return utils::bson_t_to_wchar_t(reply);
    }

    int _DeleteOne(mongoc_collection_t* c, wchar_t* utf_16_selector)
    {
        bson_error_t error;

        if (!utils::is_valid_wstring(utf_16_selector)) {
            SetLastError(2);
            fprintf(stderr, "delete failed because selector was not a valid value\n");
            return 0;
        }

        bson_t* selector = utils::wchar_to_bson_t(utf_16_selector);
        if (!mongoc_collection_remove(c, MONGOC_REMOVE_SINGLE_REMOVE, selector, NULL, &error)) {
            printf("Delete failed: %s\n", error.message);
            SetLastError(2);
            return 0;
        }
        if (error.code) {
            fprintf(stderr, "bson_new_from_json error: %s\n", error.message);
            SetLastError(error.code);
            return 0;
        }
        return 1;
    }

}

/* winmain and main are only used when compiled as commandline exe instead of dll for testing*/
int main(int argc, char* argv[]) {
    //when started from commandline, this is the entry point
    const wchar_t* constr = L"mongodb://localhost:27017"; // it is not possible to use wchar_t* when initializing the variable by string literal
    wchar_t* modifiable_str = new wchar_t[wcslen(constr) + 1];
    size_t prefixLength = std::wcslen(modifiable_str);
    wcscpy_s(modifiable_str, prefixLength, constr); //just because we should not cast const wchar_t to wchar_t

    //impl::_ConnectDatabase(modifiable_str);
    const wchar_t* prefix = L"{\"hello\":\"worldöy\"}";
    //impl::_InsertOne((wchar_t*)prefix);
    return 0;
}

int APIENTRY WinMain(HINSTANCE hInstance,
    HINSTANCE hPrevInstance,
    LPSTR lpCmdLine, int nCmdShow)
{
    return main(__argc, __argv);
}

