#include "pch.h"
#include <iostream> 
#include <fstream>
#include <time.h>
#include <string>
#include <cwchar> // For wide character functions
#include "BSonParser.h"

#define DECLDIR __declspec(dllexport)

//the BsonBridge.cpp only exports DECLDIR functions but nothing that we need in this header.