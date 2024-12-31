#include "pch.h" //windows.h
#include <iostream> 
#include <string>
#include <cwchar> // For wide character functions

#include "MongoCBridge.h"


//
//using bsoncxx::builder::basic::kvp;
//using bsoncxx::builder::basic::make_document;

using namespace std;

extern "C"
{
    /* DLL Exports */
    DECLDIR wchar_t* Echo(wchar_t* utf16String)
    {
        if (utf16String == nullptr) {
            std::wcout << L"Received NULL pointer!" << std::endl;
            utf16String = (wchar_t*)L"Received NULL pointer!";
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

    DECLDIR wchar_t* FindOne(mongoc_collection_t* c, wchar_t* query, wchar_t* utf_16_options)
    {
        return impl::_FindOne(c, query, utf_16_options);
    }

    DECLDIR wchar_t* UpdateOne(mongoc_collection_t* c, wchar_t* utf16_search, wchar_t* utf16_update, wchar_t* utf16_options)
    {
        return impl::_UpdateOne(c, utf16_search, utf16_update, utf16_options);
    }

    DECLDIR int DeleteOne(mongoc_collection_t* c, wchar_t* utf16_search)
    {
        return impl::_DeleteOne(c, utf16_search);
    }

    DECLDIR mongoc_cursor_t* FindMany(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf_16_options) {
        return impl::_FindMany(c, utf16_query_json, utf_16_options);
    }

    DECLDIR bool CursorNext(mongoc_cursor_t* cursor, wchar_t*& result) {
        return impl::_CursorNext(cursor, result);
    }

    DECLDIR void* CursorDestroy(mongoc_cursor_t* cursor) {
        return impl::_CursorDestroy(cursor);
    }
}


namespace impl {

    mongoc_collection_t* _CreateCollection(wchar_t* utf16_conn_str, wchar_t* db_name, wchar_t* collection_name) {
     
        try {
            mongoc_init();
            std::string connstr;
            mongoc_database_t* database;
            mongoc_collection_t* collection;
            mongoc_uri_t* uri;
            bson_error_t error;

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
            c, b, NULL, NULL, &error)) {
            fprintf(stderr, "mongoc_collection_insert_one error: %s\n", error.message);
            SetLastError(error.code);
            return 1;
        }

        bson_destroy(b);
        return 0;
    }

    wchar_t* _FindOne(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf_16_options)
    {
        bson_t* filter;
        const bson_t* doc;
        bson_error_t error;
        //bson_t* filter = BCON_NEW("filename", BCON_UTF8("Processors\\db\\configs\\workflows\\20230625-1518-1896-1790-0dda9dfc0f34.json"));
        if (!utils::is_valid_wstring(utf_16_options)) {
            utf_16_options = (wchar_t*)L"{}";
        }
        bson_t* opts = utils::wchar_to_bson_t(utf_16_options);

        std::string utf8_query = utils::wide_string_to_string(utf16_query_json);
        filter = bson_new_from_json((const uint8_t*)utf8_query.c_str(), utf8_query.size(), &error);
        mongoc_cursor_t* cursor = mongoc_collection_find_with_opts(c, filter, opts, NULL);
        
        while (mongoc_cursor_next(cursor, &doc)) {
            char* charptr = bson_as_canonical_extended_json(doc, NULL);
            std::string str(charptr);
            wchar_t * result = utils::string_to_wide_string(str);
            bson_free(charptr);
            mongoc_cursor_destroy(cursor);
            return result;
        }

        if (mongoc_cursor_error(cursor, &error)) {
            fprintf(stderr, "mongoc_collection_find_with_opts Error: %s\n", error.message);
            SetLastError(error.code);
            return 0;
        }
        //if no result found, return empty result
        fprintf(stderr, "FindOne mongoc_collection_find_with_opts graceful but got no results for query.\n");
        mongoc_cursor_destroy(cursor);
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

    mongoc_cursor_t* _FindMany(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf_16_options)
    {
        /* returns cursor, caller needs to destroy it */
        bson_t* filter;
        const bson_t* doc;
        bson_error_t error;
        if (!utils::is_valid_wstring(utf_16_options)) {
            utf_16_options = (wchar_t*)L"{}";
        }
        bson_t* opts = utils::wchar_to_bson_t(utf_16_options);

        //bson_t* filter = BCON_NEW("filename", BCON_UTF8("Processors\\db\\configs\\workflows\\20230625-1518-1896-1790-0dda9dfc0f34.json"));
        std::string utf8_query = utils::wide_string_to_string(utf16_query_json);
        filter = bson_new_from_json((const uint8_t*)utf8_query.c_str(), utf8_query.size(), &error);
        mongoc_cursor_t* results = mongoc_collection_find_with_opts(c, filter, opts, NULL);
        return results;
    }

    bool _CursorNext(mongoc_cursor_t* cursor, wchar_t*& result)
    {
        const bson_t* doc;
        bson_error_t error;
        if (mongoc_cursor_next(cursor, &doc)) {
            char* charptr = bson_as_canonical_extended_json(doc, NULL);
            std::string str(charptr);
            result = utils::string_to_wide_string(str);
            bson_free(charptr);
            return true;
        }
        if (mongoc_cursor_error(cursor, &error)) {
            fprintf(stderr, "mongoc_collection_find_with_opts Error: %s\n", error.message);
            SetLastError(error.code);
            return false;
        }
        return false;
    }

    void* _CursorDestroy(mongoc_cursor_t* cursor)
    {
        mongoc_cursor_destroy(cursor);
        return NULL;
    }

}

/* winmain and main are only used when compiled as commandline exe instead of dll for testing*/
int main(int argc, char* argv[]) {
    //when started from commandline, this is the entry point
    const wchar_t* constr   = L"mongodb://localhost:27017"; // it is not possible to use wchar_t* when initializing the variable by string literal
    wchar_t* modifiable_str = new wchar_t[wcslen(constr) + 1];
    size_t prefixLength     = std::wcslen(modifiable_str);
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

