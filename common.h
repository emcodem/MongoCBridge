#pragma once

#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
// Windows Header Files
#include <windows.h>

// to compile MT (static) without errors, we have to add /NODEFAULTLIB:MSVCRTD (or /NODEFAULTLIB:MSVCRT for release) to linker commandline
// Linker Input:
// $(ProjectDir)Dependencies\mongo-c-driver\lib\MT\Release\bson-static-1.0.lib
// $(ProjectDir)Dependencies\mongo - c - driver\lib\MT\Release\mongoc - static - 1.0.lib
// ws2_32.lib
// Secur32.lib
// Crypt32.lib
// BCrypt.lib
// DnsAPI.Lib

//note that these the windows libs from above cannot be added static (MS does not provide static) because they depend on windows version
//so they automatically use dll instead of static

//this disables warning LNK4286: when compiling with mongo Static libs, it sets cdecl instead of decldir dllimport
#define BSON_STATIC
#define MONGOC_STATIC

#include <mongoc/mongoc.h>
#include <bson.h>


struct ErrorStruct {
    int code;                // MongoDB error code
    wchar_t message[1024];   // MongoDB error string, max 1024 characters
};