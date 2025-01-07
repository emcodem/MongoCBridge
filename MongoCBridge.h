#include <wchar.h>
#include "common.h"
#include "utils.h"

extern "C"
{
    // DLL Exports
    #define DECLDIR __declspec(dllexport)
    
    DECLDIR wchar_t* Echo( wchar_t* utf16String);  // Function takes a pointer to MyStructure

    DECLDIR void        SetLogFile(wchar_t* filepath, struct ErrorStruct* err);
    DECLDIR void        CloseCollection(mongoc_collection_t* c);
    DECLDIR void*       CursorDestroy(mongoc_cursor_t* cursor);

    DECLDIR mongoc_collection_t* CreateCollection(wchar_t* utf16_conn_str, wchar_t* db_name, wchar_t* collection_name, struct ErrorStruct* err);
    DECLDIR int         InsertOne(mongoc_collection_t* c, wchar_t* utf16String, struct ErrorStruct* err);
    DECLDIR bool        InsertMany(mongoc_collection_t* c, wchar_t* utf16ArrayOfJsons, struct ErrorStruct* err);
    DECLDIR wchar_t*    FindOne(mongoc_collection_t* c, wchar_t* query, wchar_t* utf_16_options, wchar_t* top_level_field, struct ErrorStruct* err);
    DECLDIR wchar_t*    UpdateOne(mongoc_collection_t* c, wchar_t* utf16_search, wchar_t* utf16_update, wchar_t* utf16_options, struct ErrorStruct* err);
    DECLDIR int         DeleteOne(mongoc_collection_t* c, wchar_t* utf16_search, struct ErrorStruct* err);
    DECLDIR mongoc_cursor_t* FindMany(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf_16_options, struct ErrorStruct* err);
    DECLDIR mongoc_cursor_t* Collection_Aggregate(mongoc_collection_t* c, wchar_t* pipeline, wchar_t* opts, struct ErrorStruct* err);
    DECLDIR int64_t         CountDocuments(mongoc_collection_t* c, wchar_t* utf16query, wchar_t* utf16opts, struct ErrorStruct* err);
    DECLDIR bool        CursorNext(mongoc_cursor_t* cursor, wchar_t*& result, UINT64* resultlen, wchar_t* selector, struct ErrorStruct* err);
    DECLDIR wchar_t*    ClientCommandSimple(mongoc_collection_t* c, wchar_t* utf_16_command, wchar_t* database, struct ErrorStruct* err);

    /**
        redefines mongoc_collection_t* from moncoc.h For the "command" APIs only.
        In order to expose access to ->client and ->db fields of mongoc_collection_t
        The Code is copied from the private header file that comes with the driver:
        mongo-c-driver-1.29.1\src\libmongoc\src\mongoc\mongoc-collection-private.h
        The reason for this is that the mongoc_collection_t is not exposed in the public header file
        but we want to get the db and client from collection instance so we can live with
        only passing collection pointer back to the caller
    */
    struct _mongoc_collection_t {
        mongoc_client_t* client;
        char* ns;
        uint32_t nslen;
        char* db;
        char* collection;
        uint32_t collectionlen;
        mongoc_read_prefs_t* read_prefs;
        mongoc_read_concern_t* read_concern;
        mongoc_write_concern_t* write_concern;
        bson_t* gle;
    };

    /* End of hacky redefinition */

}

namespace impl {
    // Implementation
    // todo: this is stupid, above functions should take care about validating and translating the params and these funcs should take only mongo compatible params
    // this way we could also offer overloaded versions e.g. where the caller already has a ready to use bson_t* isntead of wchar
    void        _setLogHandler(wchar_t* filePath, struct ErrorStruct* err);
    void        _CloseCollection(mongoc_collection_t* c);
    void*       _CursorDestroy(mongoc_cursor_t* cursor);

    mongoc_collection_t* _CreateCollection(wchar_t* utf16_conn_str, wchar_t* db_name, wchar_t* collection_name, struct ErrorStruct* err);
    int         _InsertOne(mongoc_collection_t* c, wchar_t* utf16String, struct ErrorStruct* err);
    bool        _InsertMany(mongoc_collection_t* c, wchar_t* utf16Doc, struct ErrorStruct* err);
    wchar_t*    _FindOne(mongoc_collection_t* c, wchar_t* query, wchar_t* utf_16_options, wchar_t* top_level_field, struct ErrorStruct* err);
    wchar_t*    _UpdateOne(mongoc_collection_t* c, wchar_t* query, wchar_t* payload, wchar_t* utf16_options, struct ErrorStruct* err);
    int         _DeleteOne(mongoc_collection_t* c, wchar_t* query, struct ErrorStruct* err);
    mongoc_cursor_t* _FindMany(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf_16_options, struct ErrorStruct* err);
    mongoc_cursor_t* _Collection_Aggregate(mongoc_collection_t* c, wchar_t* pipeline, wchar_t* opts, struct ErrorStruct* err);
    int64_t         _CountDocuments(mongoc_collection_t* c, wchar_t* utf16query, wchar_t* utf16opts, struct ErrorStruct* err);
    bool        _CursorNext(mongoc_cursor_t* cursor, wchar_t*& result, UINT64* resultlen, wchar_t* selector, struct ErrorStruct* err);
    
    wchar_t*    _ClientCommandSimple(mongoc_collection_t* c, wchar_t* utf_16_command, wchar_t* database, struct ErrorStruct* err);
    
}
