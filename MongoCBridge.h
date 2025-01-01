#include <wchar.h>
#define DECLDIR __declspec(dllexport)

#include <mongoc/mongoc.h>
#include "utils.h"

extern "C"
{
    // DLL Exports

    DECLDIR wchar_t* Echo( wchar_t* utf16String);  // Function takes a pointer to MyStructure

    DECLDIR void        SetLogFile(wchar_t* filepath);
    DECLDIR mongoc_collection_t* CreateCollection(wchar_t* utf16_conn_str, wchar_t* db_name, wchar_t* collection_name);
    DECLDIR int         InsertOne(mongoc_collection_t* c, wchar_t* utf16String);
    DECLDIR wchar_t*    FindOne(mongoc_collection_t* c, wchar_t* query, wchar_t* utf_16_options);
    DECLDIR wchar_t*    UpdateOne(mongoc_collection_t* c, wchar_t* utf16_search, wchar_t* utf16_update, wchar_t* utf16_options);
    DECLDIR int         DeleteOne(mongoc_collection_t* c, wchar_t* utf16_search);
    DECLDIR mongoc_cursor_t*    FindMany(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf_16_options);
    DECLDIR bool                CursorNext(mongoc_cursor_t* cursor, wchar_t*& result);
    DECLDIR void*               CursorDestroy(mongoc_cursor_t* cursor);

}

namespace impl {
    // Implementation

    mongoc_collection_t* _CreateCollection(wchar_t* utf16_conn_str, wchar_t* db_name, wchar_t* collection_name);
    int         _InsertOne(mongoc_collection_t* c, wchar_t* utf16String);
    wchar_t*    _FindOne(mongoc_collection_t* c, wchar_t* query, wchar_t* utf_16_options);
    wchar_t*    _UpdateOne(mongoc_collection_t* c, wchar_t* query, wchar_t* payload, wchar_t* utf16_options);
    int         _DeleteOne(mongoc_collection_t* c, wchar_t* query);
    mongoc_cursor_t* _FindMany(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf_16_options);
    bool        _CursorNext(mongoc_cursor_t* cursor, wchar_t*& result);
    void*       _CursorDestroy(mongoc_cursor_t* cursor);
   
}

namespace mong {
    void _setLogHandler(wchar_t* filePath);
}