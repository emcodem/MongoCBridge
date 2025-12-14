#include "pch.h" //windows.h
#include <iostream> 
#include <fstream>
#include <time.h>
#include <string>
#include <cwchar> // For wide character functions
#include "BSonParser.h"
#include "MongoCBridge.h"
#include "BsonBridge.h"

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
        wcscat_s(result, prefixLength + inputLength + 1, utf16String);
        return result; // Caller is responsible for freeing the memory
    }

    DECLDIR void SetLogFile(wchar_t* filePath, struct ErrorStruct* err) {
        return impl::_setLogFile(filePath,err);
    }

    DECLDIR void* CursorDestroy(mongoc_cursor_t* cursor) {
        return impl::_CursorDestroy(cursor);
    }

    DECLDIR void CloseCollection(mongoc_collection_t* c) {
        return impl::_CloseCollection(c);
    }

    DECLDIR mongoc_collection_t* CreateCollection(wchar_t* utf16_conn_str, wchar_t* db_name, wchar_t* collection_name, struct ErrorStruct* err)
    {
        mongoc_collection_t* c = impl::_CreateCollection(utf16_conn_str,db_name,collection_name, err);
        return c;
    }

    DECLDIR bool InsertOne(mongoc_collection_t* c, wchar_t* utf16String, struct ErrorStruct* err)
    {
        return impl::_InsertOne(c, utf16String, err);
    }

    DECLDIR wchar_t* InsertMany(mongoc_collection_t* c, wchar_t* utf16ArrayOfJsons, wchar_t* utf_16_options, struct ErrorStruct* err)
    {
        return impl::_InsertMany(c, utf16ArrayOfJsons, utf_16_options, err);
    }

    DECLDIR wchar_t* FindOne(mongoc_collection_t* c, wchar_t* query, wchar_t* utf_16_options, wchar_t* selector, struct ErrorStruct* err)
    {
        return impl::_FindOne(c, query, utf_16_options, selector, err);
    }

    DECLDIR wchar_t* UpdateOne(mongoc_collection_t* c, wchar_t* utf16_search, wchar_t* utf16_update, wchar_t* utf16_options, struct ErrorStruct* err)
    {
        return impl::_UpdateOne(c, utf16_search, utf16_update, utf16_options, err);
    }

    DECLDIR bool DeleteOne(mongoc_collection_t* c, wchar_t* utf16_search, struct ErrorStruct* err)
    {
        return impl::_DeleteOne(c, utf16_search, err);
    }

    DECLDIR mongoc_cursor_t* FindMany(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf_16_options, struct ErrorStruct* err) {
        return impl::_FindMany(c, utf16_query_json, utf_16_options, err);
    }

    DECLDIR mongoc_cursor_t* Collection_Aggregate(mongoc_collection_t* c, wchar_t* pipeline, wchar_t* opts, struct ErrorStruct* err) {
        return impl::_Collection_Aggregate(c, pipeline, opts, err);
    }
    
    DECLDIR int64_t CountDocuments(mongoc_collection_t* c, wchar_t* utf16query, wchar_t* utf16opts, struct ErrorStruct* err) {
        
        return impl::_CountDocuments( c,  utf16query,  utf16opts, err);
    }

    DECLDIR bool CursorNext(mongoc_cursor_t* cursor, wchar_t*& result, UINT64* resultlen, wchar_t* selector, struct ErrorStruct* err) {
        return impl::_CursorNext(cursor, result, resultlen, selector, err);
    }

    DECLDIR wchar_t* ClientCommandSimple(mongoc_collection_t* c, wchar_t* utf_16_command, wchar_t* database, struct ErrorStruct* err){
        return impl::_ClientCommandSimple (c, utf_16_command, database, err);
    }
    
    // Function to append a BSON subdocument to a specific path in a JSON document
    DECLDIR wchar_t* JsonAppendSubJson(wchar_t* json, wchar_t* key, wchar_t* subDoc, wchar_t* selector, struct ErrorStruct* err) {
        bson_error_t error;

        // Convert wchar_t to std::string
        std::string _json = utils::wide_string_to_string(json);
        std::string _key = utils::wide_string_to_string(key);
        std::string _selector = utils::wide_string_to_string(selector);
        std::string _subDoc = utils::wide_string_to_string(subDoc);
        bson_t* original_bson = bson_new_from_json((const uint8_t*)_json.c_str(), _json.size(), &error);
        bson_t* to_append = bson_new_from_json((const uint8_t*)_subDoc.c_str(), _subDoc.size(), &error);
        bsonparser::insert_bson_at_selector(original_bson, _selector.c_str(), _key.c_str(), to_append);

        // Convert the updated BSON document back to JSON
        
        char* json_out = bson_as_relaxed_extended_json(original_bson, NULL);
        std::string sjout(json_out);
        wchar_t* result = utils::string_to_wide_string(sjout);  // Convert the JSON back to wchar_t*

        // Clean up
        bson_free(json_out);
        bson_destroy(to_append);
        bson_destroy(original_bson);

        return result;
    }

    // Function to append a BSON subdocument to a new key in a parent document at a specific path
    DECLDIR wchar_t* JsonAppendValue(wchar_t* json, wchar_t* key, wchar_t* value, wchar_t* selector, struct ErrorStruct* err) {
        bson_t* original_bson = NULL;
        bson_t* to_append = NULL;
        bson_error_t error;
        bson_iter_t iter;

        // Convert wide strings to standard strings
        std::string _json = utils::wide_string_to_string(json);
        std::string _key = utils::wide_string_to_string(key);
        std::string _value = utils::wide_string_to_string(value);
        std::string _selector = utils::wide_string_to_string(selector);

        // Parse the input JSON into a BSON object
        original_bson = bson_new_from_json((const uint8_t*)_json.c_str(), _json.size(), &error);
        if (!original_bson) {
            // If parsing fails, return the original JSON
            return json;
        }

        // Create a new BSON object to hold the key-value pair to append
        to_append = bson_new();
        if (!to_append) {
            bson_destroy(original_bson);
            return json;
        }
        bson_append_utf8(to_append, _key.c_str(), -1, _value.c_str(), -1);

        // Locate the position specified by the selector
        if (bson_iter_init(&iter, original_bson) && bson_iter_find_descendant(&iter, _selector.c_str(), &iter)) {
            // If the path exists, append the key-value pair at the found location
            const char* key = bson_iter_key(&iter);
            bson_append_iter(original_bson, key, -1, &iter);
            bson_append_document(original_bson, _key.c_str(), -1, to_append);
        }
        else {
            // If the selector path doesn't exist, append the key-value pair at the top level
            bson_append_document(original_bson, _key.c_str(), -1, to_append);
        }

        // Convert the modified BSON back to a JSON string
        char* charptr = bson_as_canonical_extended_json(original_bson, NULL);
        std::string str(charptr);
        wchar_t* result = utils::string_to_wide_string(str);

        // Cleanup
        bson_free(charptr);
        bson_destroy(original_bson);
        bson_destroy(to_append);

        return result;
    }

    DECLDIR wchar_t* GetJsonValue(wchar_t* json, wchar_t* selector, wchar_t* defaultVal, struct ErrorStruct* err) {
        //todo: error handling?!
        bson_error_t error;
        bson_t* b;

        std::string _json = utils::wide_string_to_string(json);
        b = bson_new_from_json((const uint8_t*)_json.c_str(), _json.size(), &error);
        std::string _selector = utils::wide_string_to_string(selector);

        const bson_value_t* found_value = NULL;
        const bson_t* result = NULL;
        bson_iter_t iter;

        if (bson_iter_init(&iter, b)) {
            if (bson_iter_find_descendant(&iter, _selector.c_str(), &iter)) {
                const bson_value_t* bv = bson_iter_value(&iter);
                bson_type_t t = bv->value_type;
                wchar_t* out = bsonparser::convert_bson_iter_value(&iter);
                return out;
            }
        }

        return defaultVal;
    }
}

namespace impl {

    /**
    * CreateCollection must be used before calling any other function to retrieve the collection ptr
    */

    void _CloseCollection(mongoc_collection_t* c) {
        mongoc_collection_destroy(c);
        mongoc_client_destroy(c->client);
        mongoc_cleanup();
    }

    mongoc_collection_t* _CreateCollection(wchar_t* utf16_conn_str, 
                                        wchar_t* db_name, 
                                        wchar_t* collection_name,
                                        struct ErrorStruct* err) {
     
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
                MONGOC_ERROR(
                    "mongoc_uri_new_with_error failed to parse URI: %s\n"
                    "error message:       %s\n",
                    uri_string,
                    error.message);

                utils::bsonErrtoStruct(error, err); //ensure error is set
                err->code = error.code;
                wcscpy_s(err->message, BSON_ERROR_BUFFER_SIZE, utils::charToWChar(error.message));

                utils::bsonErrtoStruct(error, err); //ensure error is set
                return NULL;
            }

            mongoc_client_t* client = mongoc_client_new_from_uri(uri);
            if (!client) {
                MONGOC_ERROR(
                    "mongoc_client_new_from_uri error, message: %s",
                    error.message);
                utils::bsonErrtoStruct(error, err); //ensure error is set
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

    bool _InsertOne(mongoc_collection_t* c, wchar_t* utf16Doc, struct ErrorStruct* err) {

        bson_error_t error;
        bson_t* b;

        if (!c) {
            utils::charErrtoStruct(1, "Invalid collection", err);
            return false;
        }

        std::string yip = utils::wide_string_to_string(utf16Doc);
        b = bson_new_from_json((const uint8_t*)yip.c_str(), yip.size(), &error); 
        if (error.code != 0) {
            MONGOC_ERROR("Invalid json, %s",error.message);
            utils::bsonErrtoStruct(error, err);
            return false;
        }


        if (!mongoc_collection_insert_one(
            c, b, NULL, NULL, &error)) {
            MONGOC_ERROR("mongoc_collection_insert_one error: %s\n", error.message);
            utils::bsonErrtoStruct(error, err);
            return false;
        }

        bson_destroy(b);
        return true;
    }
   
    wchar_t* _InsertMany(mongoc_collection_t* c, wchar_t* utf16ArrayOfJsons, wchar_t* utf_16_options, struct ErrorStruct* err) {
        bson_error_t error;
        bson_t* b = NULL;
        bson_t* opts = NULL;
        bson_t* reply = bson_new();
        bson_iter_t iter;

        if (!c) {
            utils::charErrtoStruct(1, "Invalid collection", err);
            bson_destroy(reply);
            return NULL;
        }

        if (!utils::is_valid_wstring(utf_16_options)) {
            utf_16_options = (wchar_t*)L"{}";
        }
        opts = utils::wchar_to_bson_t(utf_16_options);
        if (!opts) {
            utils::charErrtoStruct(400, "InvalidOptionsJSON", err);
            bson_destroy(reply);
            return NULL;
        }

        // Convert the input JSON string to BSON
        std::string json_str = utils::wide_string_to_string(utf16ArrayOfJsons);
        b = bson_new_from_json((const uint8_t*)json_str.c_str(), json_str.size(), &error);

        if (!b) {
            // Conversion to BSON failed
            utils::bsonErrtoStruct(error, err);
            bson_destroy(reply);
            bson_destroy(opts);
            return NULL;
        }

        bson_t** docs = NULL;  // Array to hold BSON documents
        size_t doc_count = 0;

        // Initialize the iterator
        if (!bson_iter_init(&iter, b)) {
            bson_destroy(b);
            bson_destroy(reply);
            bson_destroy(opts);
            utils::charErrtoStruct(1, "Could not initialize iterator for the document list", err);
            return NULL;
        }

        // Iterate through the array of BSON documents
        while (bson_iter_next(&iter)) {
            const bson_value_t* bval = bson_iter_value(&iter);

            // Only process documents or arrays
            if (bval->value_type != BSON_TYPE_DOCUMENT && bval->value_type != BSON_TYPE_ARRAY) {
                MONGOC_ERROR("_InsertMany: Skipping non-document or non-array value.");
                utils::charErrtoStruct(1, "Skipping non-document or non-array value.", err);
                continue;
            }

            // Extract the document data
            const uint8_t* data = bval->value.v_doc.data;
            uint32_t length = bval->value.v_doc.data_len;

            bson_t* doc = bson_new_from_data(data, length);
            if (!doc) {
                MONGOC_ERROR("_InsertMany: Failed to create BSON document from data.");
                utils::charErrtoStruct(1, "Failed to create BSON document from data.", err);
                continue;
            }

            // Resize the docs array
            bson_t** new_docs = (bson_t**)realloc(docs, (doc_count + 1) * sizeof(bson_t*));
            if (!new_docs) {
                MONGOC_ERROR("_InsertMany: Memory allocation failed for docs array.");
                utils::charErrtoStruct(1, "Memory allocation failed for docs array.", err);
                bson_destroy(doc);
                break;
            }

            docs = new_docs;
            docs[doc_count] = doc;  // Add the document to the array
            doc_count++;
        }

        // Insert the documents into the collection
        if (doc_count > 0) {
            if (!mongoc_collection_insert_many(c, (const bson_t**)docs, doc_count, opts, reply, &error)) {
                MONGOC_ERROR("_InsertMany: InsertMany failed: %s", error.message);
                utils::bsonErrtoStruct(error, err);

                // Clean up and free allocated memory
                if (docs) {
                    for (size_t i = 0; i < doc_count; i++) {
                        bson_destroy(docs[i]);
                    }
                }
                
                free(docs);
                bson_destroy(b);
                bson_destroy(opts);
                bson_destroy(reply);
                return NULL;
            }
        }

        // Clean up and free allocated memory
        if (docs) {
            for (size_t i = 0; i < doc_count; i++) {
                if (docs[i] != NULL)
                    bson_destroy(docs[i]);
            }
            free(docs);
        }
        
        bson_destroy(b);
        bson_destroy(opts);

        // Convert reply to wchar_t* and clean up
        wchar_t* result = utils::bson_t_to_wchar_t(reply);
        bson_destroy(reply);

        return result;
    }

    wchar_t* _FindOne(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf16_options, wchar_t* selector, struct ErrorStruct* err) {
        bson_t* filter = NULL;
        bson_t* opts = NULL;
        bson_error_t error;

        if (!c) {
            utils::charErrtoStruct(1, "Invalid collection", err);
            return NULL;
        }

        if (!utils::is_valid_wstring(utf16_options)) {
            utf16_options = (wchar_t*)L"{}";
        }
        opts = utils::wchar_to_bson_t(utf16_options);
        if (!opts) {
            utils::charErrtoStruct(400, "InvalidOptionsJSON", err);
            return NULL;
        }

        if (!utils::is_valid_wstring(selector)) {
            selector = (wchar_t*)L"";
        }
        std::string s_selector = utils::wide_string_to_string(selector);

        // Convert the query JSON to BSON
        std::string utf8_query = utils::wide_string_to_string(utf16_query_json);
        filter = bson_new_from_json((const uint8_t*)utf8_query.c_str(), utf8_query.size(), &error);
        if (!filter) {
            utils::bsonErrtoStruct(error, err);
            bson_destroy(opts);
            return NULL;
        }

        // Query the collection
        mongoc_cursor_t* cursor = mongoc_collection_find_with_opts(c, filter, opts, NULL);
        const bson_t* doc = NULL;

        // Iterate over cursor results
        if (mongoc_cursor_next(cursor, &doc)) {
            if (!s_selector.empty()) {
                // If a selector is specified, search within the document
                bson_iter_t iter;
                if (bson_iter_init(&iter, doc) && bson_iter_find_descendant(&iter, s_selector.c_str(), &iter)) {
                    wchar_t* result = bsonparser::convert_bson_iter_value(&iter);

                    // Cleanup and return
                    mongoc_cursor_destroy(cursor);
                    bson_destroy(filter);
                    bson_destroy(opts);
                    return result;
                }
            }

            // If no selector or selector not found, return the entire document
            char* charptr = bson_as_canonical_extended_json(doc, NULL);
            std::string str(charptr);
            wchar_t* result = utils::string_to_wide_string(str);

            // Cleanup and return
            bson_free(charptr);
            mongoc_cursor_destroy(cursor);
            bson_destroy(filter);
            bson_destroy(opts);
            return result;
        }

        // Handle cursor errors
        if (mongoc_cursor_error(cursor, &error)) {
            MONGOC_ERROR("mongoc_collection_find_with_opts Error: %s\n", error.message);
            utils::bsonErrtoStruct(error, err);
        }
        else {
            utils::charErrtoStruct(47, "NoMatchingDocument", err);
        }

        // Cleanup on no result or error
        mongoc_cursor_destroy(cursor);
        bson_destroy(filter);
        bson_destroy(opts);
        return NULL;
    }


    wchar_t* _UpdateOne(mongoc_collection_t* c, wchar_t* utf_16_selector, wchar_t* utf_16_update, wchar_t* utf_16_options, struct ErrorStruct* err) {
        bson_error_t error;

        if (!c) {
            utils::charErrtoStruct(1, "Invalid collection", err);
            return NULL;
        }

        // Validate inputs
        if (!utils::is_valid_wstring(utf_16_selector)) {
            utils::charErrtoStruct(1, "Invalid param selector.", err);
            MONGOC_ERROR("Invalid param selector..\n");
            return NULL;
        }
        if (!utils::is_valid_wstring(utf_16_update)) {
            utils::charErrtoStruct(1, "Invalid param update.", err);
            MONGOC_ERROR("Invalid param update.\n");
            return NULL;
        }
        if (!utils::is_valid_wstring(utf_16_options)) {
            utf_16_options = (wchar_t*)L"{}";  // Default to an empty options document
        }

        // Convert input strings to BSON
        bson_t* selector = utils::wchar_to_bson_t(utf_16_selector);
        if (selector == NULL) {
            MONGOC_ERROR("Invalid param selector.");
            utils::charErrtoStruct(1, "Invalid param selector.", err);
            return NULL;
        }
        bson_t* update = utils::wchar_to_bson_t(utf_16_update);
        if (update == NULL) {
            MONGOC_ERROR("Invalid param update.");
            utils::charErrtoStruct(1, "Invalid param update.", err);
            return NULL;
        }
        bson_t* opts = utils::wchar_to_bson_t(utf_16_options);
        if (update == NULL) {
            MONGOC_ERROR("Invalid param opts.");
            utils::charErrtoStruct(1, "Invalid param opts.", err);
            return NULL;
        }
        bson_t* reply = bson_new();

        if (!selector || !update || !opts) {
            utils::charErrtoStruct(1, "Failed to parse BSON from input strings.", err);
            MONGOC_ERROR("Failed to parse BSON from input strings.\n");
            bson_destroy(selector);
            bson_destroy(update);
            bson_destroy(opts);
            bson_destroy(reply);
            return NULL;
        }

        // Perform the update
        if (!mongoc_collection_update_one(c, selector, update, opts, reply, &error)) {
            utils::bsonErrtoStruct(error, err);
            MONGOC_ERROR("Update failed: %s\n", error.message);
            bson_destroy(selector);
            bson_destroy(update);
            bson_destroy(opts);
            bson_destroy(reply);
            return NULL;
        }

        // Convert reply to wchar_t* and clean up
        wchar_t* result = utils::bson_t_to_wchar_t(reply);

        bson_destroy(selector);
        bson_destroy(update);
        bson_destroy(opts);
        bson_destroy(reply);

        return result;
    }

    bool _DeleteOne(mongoc_collection_t* c, wchar_t* utf_16_selector, struct ErrorStruct* err)
    {
        bson_error_t error;

        if (!c) {
            utils::charErrtoStruct(1, "Invalid collection", err);
            return false;
        }

        if (!utils::is_valid_wstring(utf_16_selector)) {
            utils::charErrtoStruct(1, "delete failed because selector was not a valid value", err);
            MONGOC_ERROR("delete failed because selector was not a valid value");
            return false;
        }

        bson_t* selector = utils::wchar_to_bson_t(utf_16_selector);
        if (selector == NULL) {
            MONGOC_ERROR("Invalid param selector.");
            utils::charErrtoStruct(1, "Invalid param selector.", err);
            return NULL;
        }


        if (!mongoc_collection_remove(c, MONGOC_REMOVE_SINGLE_REMOVE, selector, NULL, &error)) {
            MONGOC_ERROR("Delete failed: %s\n", error.message);
            utils::bsonErrtoStruct(error, err);
            bson_destroy(selector);
            return false;
        }

        if (error.code) {
            MONGOC_ERROR("bson_new_from_json error: %s\n", error.message);
            utils::bsonErrtoStruct(error, err);
            bson_destroy(selector);
            return false;
        }

        bson_destroy(selector);
        return true;
    }

    mongoc_cursor_t* _FindMany(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf_16_options, struct ErrorStruct* err) {
        /* Returns cursor, caller needs to destroy it */
        bson_t* filter = NULL;
        bson_t* opts = NULL;
        bson_error_t error;

        if (!c) {
            utils::charErrtoStruct(1, "Invalid collection", err);
            return NULL;
        }

        // Validate options string and set default if invalid
        if (!utils::is_valid_wstring(utf_16_options)) {
            utf_16_options = (wchar_t*)L"{}";
        }

        // Convert options and query to BSON
        opts = utils::wchar_to_bson_t(utf_16_options);
        if (opts == NULL) {
            MONGOC_ERROR("selector");
            utils::charErrtoStruct(1, "_CountDocuments failed: opts is not a valid value.", err);
            return NULL;
        }

        std::string utf8_query = utils::wide_string_to_string(utf16_query_json);
        filter = bson_new_from_json((const uint8_t*)utf8_query.c_str(), utf8_query.size(), &error);
        if (filter == NULL) {
            MONGOC_ERROR("Invalid param filter.");
            utils::charErrtoStruct(1, "Invalid param filter.", err);
            return NULL;
        }

        if (error.code) {
            MONGOC_ERROR("_FindMany error: %s\n", error.message);
            utils::bsonErrtoStruct(error, err);
            bson_destroy(opts);
            return NULL;
        }

        // Perform the query and return the cursor
        mongoc_cursor_t* results = mongoc_collection_find_with_opts(c, filter, opts, NULL);

        bson_destroy(filter);
        bson_destroy(opts);

        return results;
    }

    mongoc_cursor_t* _Collection_Aggregate(mongoc_collection_t* c, wchar_t* pipeline, wchar_t* opts, struct ErrorStruct* err)
    {
        /* returns cursor, caller needs to destroy it */
        if (!c) {
            utils::charErrtoStruct(1, "Invalid collection", err);
            return NULL;
        }

        if (!utils::is_valid_wstring(pipeline)) {
            pipeline = (wchar_t*)L"{}";
        }
        if (!utils::is_valid_wstring(opts)) {
            opts = (wchar_t*)L"{ cursor: { batchSize: 1 }";
        }

        bson_t* bson_opts       = utils::wchar_to_bson_t(opts);
        bson_t* bson_pipeline   = utils::wchar_to_bson_t(pipeline);

        if (bson_opts == NULL) {
            MONGOC_ERROR("Invalid param opts.");
            utils::charErrtoStruct(1, "Invalid param opts.", err);
            return NULL;
        }
        if (bson_pipeline == NULL) {
            MONGOC_ERROR("Invalid param pipeline.");
            utils::charErrtoStruct(1, "Invalid param pipeline.", err);
            return NULL;
        }

        mongoc_cursor_t* results = mongoc_collection_aggregate(c,
            MONGOC_QUERY_NONE,
            bson_pipeline,
            bson_opts,
            NULL);

        bson_destroy(bson_opts);
        bson_destroy(bson_pipeline);
        return results;
    }

    int64_t _CountDocuments(mongoc_collection_t* c, wchar_t* utf16query, wchar_t* utf16opts, struct ErrorStruct* err) {
        
        bson_error_t error;
        bson_t* selector = utils::wchar_to_bson_t(utf16query);
        bson_t* opts = utils::wchar_to_bson_t(utf16opts);
        
        if (!c) {
            utils::charErrtoStruct(1, "Invalid collection", err);
            return NULL;
        }

        if (selector == NULL) {
            MONGOC_ERROR("Invalid param selector");
            utils::charErrtoStruct(1, "Invalid param selector", err);
            return NULL;
        }
        if (opts == NULL) {
            MONGOC_ERROR("Invalid param opts");
            utils::charErrtoStruct(1, "Invalid param opts", err);
            return NULL;
        }
        int64_t count = mongoc_collection_count_documents(c, selector, opts, NULL, NULL, &error);
       
        bson_destroy(selector);
        bson_destroy(opts);

        if (error.code) {
            MONGOC_ERROR("_CountDocuments error: %s\n", error.message);
            utils::bsonErrtoStruct(error, err);
            return 0;
        }

        return count;

    }

    bool _CursorNext(mongoc_cursor_t* cursor, wchar_t*& result, UINT64* resultlen, wchar_t* selector, struct ErrorStruct* err)
    {
        bson_t* doc;
        bson_error_t error;
        bson_iter_t iter;

        if (!utils::is_valid_wstring(selector) ) {
            selector = (wchar_t*)L"";
        }

        if (cursor == NULL) {
            MONGOC_ERROR("_CursorNext failed: Cursor is null");
            utils::charErrtoStruct(1, "_CursorNext failed: Cursor is null", err);
            return NULL;
        }

        if (mongoc_cursor_next(cursor, (const bson_t**) & doc)) {
            
            std::string sselector = utils::wide_string_to_string(selector);
            //if selector, search into bson
            wchar_t* bla = utils::bson_t_to_wchar_t(doc);
            if (strcmp(sselector.c_str(), "") != 0) {
                if (bson_iter_init(&iter, doc) && bson_iter_find_descendant(&iter, sselector.c_str(), &iter)) {
                    // If the path exists, append the key-value pair at the found location
                    const char* key = bson_iter_key(&iter);
                    result = bsonparser::convert_bson_iter_value(&iter);
                    *resultlen = wcslen(result);
                    bson_destroy((bson_t*)doc);
                    return true;
                }
            }
            //else or default return doc
            char* charptr = bson_as_canonical_extended_json(doc, NULL);
            std::string str(charptr);
            result = utils::string_to_wide_string(str);
            *resultlen = wcslen(result);
            bson_free(charptr);
            return true;
        }
        if (mongoc_cursor_error(cursor, &error)) {
            MONGOC_ERROR( "_CursorNext Error: %d, %s\n",error.code, error.message);
            utils::bsonErrtoStruct(error, err);
            return false;
        }
        return false;
    }

    wchar_t* _ClientCommandSimple(mongoc_collection_t* c, wchar_t* utf_16_command, wchar_t* database, struct ErrorStruct* err) {
        
        if (!utils::is_valid_wstring(utf_16_command)) {
            MONGOC_ERROR("Invalid parameter \"command\"\n");
            return NULL;
        }
        if (!c) {
            utils::charErrtoStruct(1, "Invalid collection", err);
            return NULL;
        }

        bson_t* command = utils::wchar_to_bson_t(utf_16_command);
        if (command == NULL) {
            MONGOC_ERROR("Invalid param command");
            utils::charErrtoStruct(1, "Invalid param command", err);
            return NULL;
        }

        bson_t* reply = bson_new();
        bson_error_t error;

        // Determine the database to use, defaulting to the collection's database
        std::string s_db(c->db);
        if (database != nullptr && wcslen(database) != 0) {
            s_db = utils::wide_string_to_string(database);
        }

        if (mongoc_client_command_simple(c->client, s_db.c_str(), command, NULL, reply, &error)) {
            char* charptr = bson_as_canonical_extended_json(reply, NULL);
            std::string str(charptr);
            wchar_t* result = utils::string_to_wide_string(str);
            bson_free(charptr);
            bson_destroy(reply);

            return result;
        }
        else {
            MONGOC_ERROR("mongoc_client_command_simple error: %s\n", error.message);
            utils::bsonErrtoStruct(error, err);
            bson_destroy(reply);
            return NULL;
        }
    }

    void* _CursorDestroy(mongoc_cursor_t* cursor)
    {
        if (cursor) {
            mongoc_cursor_destroy(cursor);
        }
        return NULL;
    }

    const char* getLogLevelStr(mongoc_log_level_t log_level) {
        switch (log_level) {
        case MONGOC_LOG_LEVEL_ERROR:    return "ERROR";
        case MONGOC_LOG_LEVEL_CRITICAL: return "CRITICAL";
        case MONGOC_LOG_LEVEL_WARNING:  return "WARNING";
        case MONGOC_LOG_LEVEL_MESSAGE:  return "MESSAGE";
        case MONGOC_LOG_LEVEL_INFO:     return "INFO";
        case MONGOC_LOG_LEVEL_DEBUG:    return "DEBUG";
        case MONGOC_LOG_LEVEL_TRACE:    return "TRACE";
        default:                        return "UNKNOWN";
        }
    }

    std::string currentLogPath;

    void logHandler(mongoc_log_level_t log_level,
        const char* log_domain,
        const char* message,
        void* user_data)
    {
        // Error callback from mongoc, only used when _setLogHandler was called.

        if (currentLogPath.empty()) {
            return;
        }

        // Get the current time
        char buff[100];
        time_t now = time(0);
        struct tm sTm;
        if (localtime_s(&sTm, &now) == 0) {
            strftime(buff, sizeof(buff), "%Y-%m-%d %H:%M:%S", &sTm);
        }
        else {
            snprintf(buff, sizeof(buff), "unknown time");
        }

        // Open log file in append mode
        FILE* logFile = nullptr;
        errno_t err = fopen_s(&logFile, currentLogPath.c_str(), "a");
        if (err != 0 || logFile == nullptr) {
            MONGOC_ERROR("Error opening logfile [%s]", currentLogPath.c_str());
            return;
        }

        bool endsWithNewline = (message[strlen(message) - 1] == '\n');
        if (endsWithNewline) {
            fprintf(logFile, "%s\t%s\t%s\t%s", buff, log_domain, getLogLevelStr(log_level), message);
        }
        else {
            fprintf(logFile, "%s\t%s\t%s\t%s\n", buff, log_domain, getLogLevelStr(log_level), message);
        }

        fclose(logFile);
    }

    void _setLogFile(wchar_t* filePath, struct ErrorStruct* err) {
        if (!utils::is_valid_wstring(filePath)) {
            MONGOC_ERROR(
                "Cannot set LogHandler, determined invalid FilePath Pointer.");
            utils::charErrtoStruct(1, "Cannot set LogHandler, determined invalid FilePath Pointer.", err);
            return;
        }

        currentLogPath = utils::wide_string_to_string(filePath);
        mongoc_log_set_handler(logHandler, NULL);
        
        MONGOC_INFO(
            "Log Initialized [%s]", currentLogPath.c_str());
        
    }
}

//
///* winmain and main are only used when compiled as commandline exe instead of dll for testing */
//int main(int argc, char* argv[]) {
//    //when started from commandline, this is the entry point
//    // it is not possible to use wchar_t* when initializing the variable by string literal
//    const wchar_t* constr   = L"mongodb://localhost:27017"; 
//    wchar_t* modifiable_str = new wchar_t[wcslen(constr) + 1];
//    size_t prefixLength     = std::wcslen(modifiable_str);
//    //just because we should not cast const wchar_t to wchar_t
//    wcscpy_s(modifiable_str, prefixLength, constr); 
//
//    //impl::_ConnectDatabase(modifiable_str);
//    const wchar_t* prefix = L"{\"hello\":\"world�y\"}";
//    //impl::_InsertOne((wchar_t*)prefix);
//    return 0;
//}
//
//int APIENTRY WinMain(HINSTANCE hInstance,
//    HINSTANCE hPrevInstance,
//    LPSTR lpCmdLine, int nCmdShow)
//{
//    return main(__argc, __argv);
//}

