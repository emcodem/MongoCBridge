#include <wchar.h>
#define DECLDIR __declspec(dllexport)

#include <mongoc/mongoc.h>

namespace impl {
    
    mongoc_database_t* database;
    mongoc_collection_t* collection;
    mongoc_collection_t* _CreateCollection(wchar_t* utf16_conn_str, wchar_t* db_name, wchar_t* collection_name);
    int _InsertOne(mongoc_collection_t* c, wchar_t* utf16String);
    wchar_t* _FindOne(mongoc_collection_t* c,wchar_t* query);
    wchar_t* _UpdateOne(mongoc_collection_t* c, wchar_t* query, wchar_t* payload, wchar_t* utf16_options);
    int _DeleteOne(mongoc_collection_t* c, wchar_t* query);
}

extern "C"
{
    // Declare all functions here

    DECLDIR wchar_t* Echo( wchar_t* utf16String);  // Function takes a pointer to MyStructure

    DECLDIR mongoc_collection_t* CreateCollection(wchar_t* utf16_conn_str, wchar_t* db_name, wchar_t* collection_name);
    DECLDIR int InsertOne(mongoc_collection_t* c, wchar_t* utf16String);
    DECLDIR wchar_t* FindOne(mongoc_collection_t* c, wchar_t* query);
    DECLDIR wchar_t* UpdateOne(mongoc_collection_t* c, wchar_t* utf16_search, wchar_t* utf16_update, wchar_t* utf16_options);
    DECLDIR int DeleteOne(mongoc_collection_t* c, wchar_t* utf16_search);

}
