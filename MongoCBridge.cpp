#include "pch.h" //windows.h
#include <iostream> 
#include <fstream>
#include <time.h>
#include <string>
#include <cwchar> // For wide character functions

#include "MongoCBridge.h"

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
        return impl::_setLogHandler(filePath,err);
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

    DECLDIR int InsertOne(mongoc_collection_t* c, wchar_t* utf16String, struct ErrorStruct* err)
    {
        return impl::_InsertOne(c, utf16String, err);
    }

    DECLDIR bool InsertMany(mongoc_collection_t* c, wchar_t* utf16ArrayOfJsons, struct ErrorStruct* err)
    {
        return impl::_InsertMany(c, utf16ArrayOfJsons, err);
    }

    DECLDIR wchar_t* FindOne(mongoc_collection_t* c, wchar_t* query, wchar_t* utf_16_options, struct ErrorStruct* err)
    {
        return impl::_FindOne(c, query, utf_16_options, err);
    }

    DECLDIR wchar_t* UpdateOne(mongoc_collection_t* c, wchar_t* utf16_search, wchar_t* utf16_update, wchar_t* utf16_options, struct ErrorStruct* err)
    {
        return impl::_UpdateOne(c, utf16_search, utf16_update, utf16_options, err);
    }

    DECLDIR int DeleteOne(mongoc_collection_t* c, wchar_t* utf16_search, struct ErrorStruct* err)
    {
        return impl::_DeleteOne(c, utf16_search, err);
    }

    DECLDIR mongoc_cursor_t* FindMany(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf_16_options, struct ErrorStruct* err) {
        return impl::_FindMany(c, utf16_query_json, utf_16_options, err);
    }

    DECLDIR bool CursorNext(mongoc_cursor_t* cursor, wchar_t*& result, UINT64* resultlen, struct ErrorStruct* err) {
        return impl::_CursorNext(cursor, result, resultlen, err);
    }

    DECLDIR wchar_t* ClientCommandSimple(mongoc_collection_t* c, wchar_t* utf_16_command, struct ErrorStruct* err){
        return impl::_ClientCommandSimple (c, utf_16_command, err);
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

    int _InsertOne(mongoc_collection_t* c, wchar_t* utf16Doc, struct ErrorStruct* err) {

        bson_error_t error;
        bson_t* b;

        std::string yip = utils::wide_string_to_string(utf16Doc);
        b = bson_new_from_json((const uint8_t*)yip.c_str(), yip.size(), &error); 
        if (error.code != 0) {
            MONGOC_ERROR("Invalid json, %s",error.message);
            utils::bsonErrtoStruct(error, err); //ensure error is set
            return NULL;
        }

        if (!mongoc_collection_insert_one(
            c, b, NULL, NULL, &error)) {
            MONGOC_ERROR("mongoc_collection_insert_one error: %s\n", error.message);
            utils::bsonErrtoStruct(error, err); //ensure error is set
            return NULL;
        }

        bson_destroy(b);
        return 0;
    }

    bool _InsertMany(mongoc_collection_t* c, wchar_t* utf16ArrayOfJsons, struct ErrorStruct* err) {

        bson_error_t error;
        bson_t* b;

        std::string yip = utils::wide_string_to_string(utf16ArrayOfJsons);
        b = bson_new_from_json((const uint8_t*)yip.c_str(), yip.size(), &error);
        if (error.code != 0) {
            utils::bsonErrtoStruct(error, err);
            return false;
        }

        bson_iter_t iter; //the exapmles do not free this, so we do not either
        size_t doc_count = 0;
        bson_t** docs = NULL;
                
        if (bson_iter_init(&iter, b)) {
            while (bson_iter_next(&iter)) {
                const bson_value_t* bval = bson_iter_value(&iter);
                if (bval->value_type != BSON_TYPE_DOCUMENT && bval->value_type != BSON_TYPE_ARRAY) {
                    MONGOC_ERROR("_InsertMany Skipping non-document or non-array value.");
                    utils::charErrtoStruct(1, "Skipping non-document or non-array value.",err);
                    free(docs);
                    bson_destroy(b);
                    return false;
                }
                
                const uint8_t* data = bval->value.v_doc.data;
                uint32_t length = bval->value.v_doc.data_len;
                bson_t* doc = bson_new_from_data(data, length);
                bson_t** new_docs = (bson_t**)realloc(docs, (doc_count + 1) * sizeof(bson_t*));
                if (!new_docs) {
                    // Exit on allocation failure
                    MONGOC_ERROR("_InsertMany Memory allocation failed for docs array.\n");
                    utils::charErrtoStruct(1, "_InsertMany Memory allocation failed for docs array.\n", err);
                    bson_destroy(doc);
                    break;  
                }
                // Add the new document to the array
                docs = new_docs;
                docs[doc_count] = doc;  
                doc_count++;
            }
            mongoc_collection_insert_many(c, (const bson_t**)docs, doc_count, NULL, NULL, NULL);
        }
        else {
            bson_destroy(b);
            free(docs);
            MONGOC_ERROR("Could not create iterator for the document list");
            utils::charErrtoStruct(1, "Could not create iterator for the document list", err);
            return NULL;
        }

        bson_destroy(b);
        free(docs);

        return 0;
    }


    wchar_t* _FindOne(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf_16_options, struct ErrorStruct* err)
    {
        bson_t* filter;
        const bson_t* doc;
        bson_error_t error;
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
            MONGOC_ERROR("mongoc_collection_find_with_opts Error: %s\n", error.message);
            utils::bsonErrtoStruct(error, err);
            return 0;
        }
        //if no result found, return empty result
        MONGOC_ERROR("FindOne mongoc_collection_find_with_opts graceful but got no results for query.\n");
        mongoc_cursor_destroy(cursor);
        bson_destroy(filter);
        return 0;
    }

    wchar_t* _UpdateOne(mongoc_collection_t* c, wchar_t* utf_16_selector, wchar_t* utf_16_update, wchar_t* utf_16_options, struct ErrorStruct* err)
    {
        bson_error_t error;

        if (!utils::is_valid_wstring(utf_16_selector)) {
            utils::charErrtoStruct(1, "update failed because update was not a valid value", err);
            MONGOC_ERROR("update failed because selector was not a valid value\n");
            return NULL;
        }
        if (!utils::is_valid_wstring(utf_16_update)) {
            utils::charErrtoStruct(1, "update failed because update was not a valid value", err);
            MONGOC_ERROR("update failed because update was not a valid value");
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
            utils::bsonErrtoStruct(error, err); 
            MONGOC_ERROR("update failed: %s\n", error.message);
            return NULL;
        }
        return utils::bson_t_to_wchar_t(reply);
    }

    int _DeleteOne(mongoc_collection_t* c, wchar_t* utf_16_selector, struct ErrorStruct* err)
    {
        bson_error_t error;

        if (!utils::is_valid_wstring(utf_16_selector)) {
            utils::charErrtoStruct(1, "delete failed because selector was not a valid value", err);
            MONGOC_ERROR("delete failed because selector was not a valid value");
            return 0;
        }

        bson_t* selector = utils::wchar_to_bson_t(utf_16_selector);
        if (!mongoc_collection_remove(c, MONGOC_REMOVE_SINGLE_REMOVE, selector, NULL, &error)) {
            MONGOC_ERROR("Delete failed: %s\n", error.message);
            utils::bsonErrtoStruct(error, err);
            return 0;
        }
        if (error.code) {
            MONGOC_ERROR("bson_new_from_json error: %s\n", error.message);
            utils::bsonErrtoStruct(error, err);
            return 0;
        }
        return 1;
    }

    mongoc_cursor_t* _FindMany(mongoc_collection_t* c, wchar_t* utf16_query_json, wchar_t* utf_16_options, struct ErrorStruct* err)
    {
        /* returns cursor, caller needs to destroy it */
        bson_t* filter;
        bson_error_t error;

        if (!utils::is_valid_wstring(utf_16_options)) {
            utf_16_options = (wchar_t*)L"{}";
        }

        bson_t* opts = utils::wchar_to_bson_t(utf_16_options);
        std::string utf8_query = utils::wide_string_to_string(utf16_query_json);
        filter = bson_new_from_json((const uint8_t*)utf8_query.c_str(), utf8_query.size(), &error);

        if (error.code) {
            MONGOC_ERROR("_FindMany error: %s\n", error.message);
            utils::bsonErrtoStruct(error, err);
            return NULL;
        }

        mongoc_cursor_t* results = mongoc_collection_find_with_opts(c, filter, opts, NULL);
        return results;
    }

    bool _CursorNext(mongoc_cursor_t* cursor, wchar_t*& result, UINT64* resultlen, struct ErrorStruct* err)
    {
        const bson_t* doc;
        bson_error_t error;
        
        if (mongoc_cursor_next(cursor, &doc)) {
            char* charptr = bson_as_canonical_extended_json(doc, NULL);
            std::string str(charptr);
            result = utils::string_to_wide_string(str);
            *resultlen = wcslen(result);
            bson_free(charptr);
            return true;
        }
        if (mongoc_cursor_error(cursor, &error)) {
            MONGOC_ERROR( "_CursorNext Error: %s\n", error.message);
            utils::bsonErrtoStruct(error, err);
            return false;
        }
        return false;
    }

    wchar_t* _ClientCommandSimple(mongoc_collection_t* c, wchar_t* utf_16_command, struct ErrorStruct* err) {
        //https://www.mongodb.com/docs/manual/reference/command/
        if (!utils::is_valid_wstring(utf_16_command)) {
            MONGOC_ERROR("Invalid parameter \"command\"\n");
            return NULL;
        }
        bson_t* command = utils::wchar_to_bson_t(utf_16_command);
        bson_t* reply = bson_new();
        bson_error_t error;

        //if the command is successful, error is not initialized so we must use if else as seen in mongo tutorials executing.c example code
        if (mongoc_client_command_simple(c->client,
                                    c->db,
                                    command,
                                    NULL,//const mongoc_read_prefs_t * read_prefs,
                                    reply,
                                    &error)){
            char* charptr = bson_as_canonical_extended_json(reply, NULL);
            std::string str(charptr);
            wchar_t* result = utils::string_to_wide_string(str);
            bson_free(charptr);
            bson_free(reply);
            return result;
        }
        else {
            MONGOC_ERROR("mongoc_client_command_simple error: %s\n", error.message);
            utils::bsonErrtoStruct(error, err); //ensure error is set
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
        //error callback from mongoc, only used when _setLogHandler was called.

        if (!currentLogPath.size()) {
            return;
        }

        //get current time
        char buff[100];
        time_t now = time(0);
        struct tm sTm;
        if (localtime_s(&sTm, &now) == 0) {
            strftime(buff, sizeof(buff), "%Y-%m-%d %H:%M:%S", &sTm);
        }
        else {
            snprintf(buff, sizeof(buff), "unknown time");
        }

        //print to log file
        FILE* logFile = nullptr;
        errno_t err = fopen_s(&logFile, currentLogPath.c_str(), "a");
        //todo: find out why fopen_S always returns 183 when file exists (which it usually does)
        if (GetLastError() == 183) { 
            SetLastError(0); //ignore error
        }
        if (err != 0 || logFile == nullptr) {
            MONGOC_ERROR(
                "Error opening logfile [%s]", currentLogPath.c_str());
            return;
        }

        //log to file formatted
        bool endsWithNewline = message[strlen(message) - 1] == '\n';

        if (endsWithNewline) {
            fprintf(logFile, "%s\t%s\t%s\t%s", buff, log_domain, getLogLevelStr(log_level), message);
        }
        else {
            fprintf(logFile, "%s\t%s\t%s\t%s\n", buff, log_domain, getLogLevelStr(log_level), message);
        }

        fclose(logFile);
    }

    void _setLogHandler(wchar_t* filePath, struct ErrorStruct* err) {
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
        mongoc_log_trace_enable();
    }

}

/* winmain and main are only used when compiled as commandline exe instead of dll for testing */
int main(int argc, char* argv[]) {
    //when started from commandline, this is the entry point
    // it is not possible to use wchar_t* when initializing the variable by string literal
    const wchar_t* constr   = L"mongodb://localhost:27017"; 
    wchar_t* modifiable_str = new wchar_t[wcslen(constr) + 1];
    size_t prefixLength     = std::wcslen(modifiable_str);
    //just because we should not cast const wchar_t to wchar_t
    wcscpy_s(modifiable_str, prefixLength, constr); 

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

