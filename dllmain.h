#pragma once
#ifndef _DLLTEST_H_
#define _DLLTEST_H_  // This is basically to tell compiler that we want to include this code only once(in case duplication occurs)

#define DLL_EXPORT
#if defined DLL_EXPORT
#define DECLDIR __declspec(dllexport)
#else
#define DECLDIR __declspec(dllimport)
#endif

extern "C"
{
    // declare all functions here
    DECLDIR void Function(void);
    DECLDIR int Add(int a, int b);

}
#endif