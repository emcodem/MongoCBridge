#pragma once

#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
// Windows Header Files
#include <windows.h>

struct ErrorStruct {
    int code;                // MongoDB error code
    wchar_t message[1024];   // MongoDB error string, max 1024 characters
};