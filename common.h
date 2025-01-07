#pragma once

#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
// Windows Header Files
#include <windows.h>

//this disables warning LNK4286: when compiling with mongo Static libs, it sets cdecl instead of decldir dllimport
#define BSON_STATIC
#define MONGOC_STATIC

struct ErrorStruct {
    int code;                // MongoDB error code
    wchar_t message[1024];   // MongoDB error string, max 1024 characters
};