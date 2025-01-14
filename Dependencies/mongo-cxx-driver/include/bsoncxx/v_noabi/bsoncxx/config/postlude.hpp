// Copyright 2009-present MongoDB, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// config.hpp (generated by CMake)
#undef BSONCXX_POLY_USE_IMPLS
#pragma pop_macro("BSONCXX_POLY_USE_IMPLS")
#undef BSONCXX_POLY_USE_STD
#pragma pop_macro("BSONCXX_POLY_USE_STD")

// version.hpp (generated by CMake)
#undef BSONCXX_VERSION_EXTRA
#pragma pop_macro("BSONCXX_VERSION_EXTRA")
#undef BSONCXX_VERSION_MAJOR
#pragma pop_macro("BSONCXX_VERSION_MAJOR")
#undef BSONCXX_VERSION_MINOR
#pragma pop_macro("BSONCXX_VERSION_MINOR")
#undef BSONCXX_VERSION_PATCH
#pragma pop_macro("BSONCXX_VERSION_PATCH")

// export.hpp (generated by CMake)
#pragma pop_macro("BSONCXX_ABI_EXPORT_H")
#pragma pop_macro("BSONCXX_ABI_EXPORT")
#pragma pop_macro("BSONCXX_ABI_NO_EXPORT")
#pragma pop_macro("BSONCXX_ABI_CDECL")
#pragma pop_macro("BSONCXX_ABI_EXPORT_CDECL")
#pragma pop_macro("BSONCXX_DEPRECATED")

// prelude.hpp
#undef BSONCXX_UNREACHABLE
#pragma pop_macro("BSONCXX_UNREACHABLE")

#pragma pop_macro("bsoncxx_cxx14_constexpr")
#pragma pop_macro("BSONCXX_RETURNS")

// util.hpp
#pragma pop_macro("BSONCXX_PUSH_WARNINGS")
#pragma pop_macro("BSONCXX_POP_WARNINGS")
#pragma pop_macro("BSONCXX_DISABLE_WARNING")

#pragma pop_macro("_bsoncxxDisableWarningImpl_for_MSVC")
#pragma pop_macro("_bsoncxxDisableWarningImpl_for_GCC")
#pragma pop_macro("_bsoncxxDisableWarningImpl_for_GNU")
#pragma pop_macro("_bsoncxxDisableWarningImpl_for_Clang")

#pragma pop_macro("BSONCXX_CONCAT")
#pragma pop_macro("BSONCXX_CONCAT_IMPL")

#pragma pop_macro("BSONCXX_PRAGMA")
#pragma pop_macro("_bsoncxxPragma")
#pragma pop_macro("BSONCXX_STRINGIFY_IMPL")
#pragma pop_macro("BSONCXX_STRINGIFY")
#pragma pop_macro("BSONCXX_FORCE_SEMICOLON")

#pragma pop_macro("BSONCXX_IF_MSVC")
#pragma pop_macro("BSONCXX_IF_GCC")
#pragma pop_macro("BSONCXX_IF_CLANG")
#pragma pop_macro("BSONCXX_IF_GNU_LIKE")

#pragma pop_macro("BSONCXX_FWD")

///
/// @file
/// The bsoncxx macro guard postlude header.
///
/// @warning For internal use only!
///
/// This header uses macro pragmas to guard macros defined by the bsoncxx library for internal use
/// by "popping" their prior definition onto the stack after use by bsoncxx headers.
///
/// @see
/// - @ref bsoncxx/v_noabi/bsoncxx/config/prelude.hpp
///
