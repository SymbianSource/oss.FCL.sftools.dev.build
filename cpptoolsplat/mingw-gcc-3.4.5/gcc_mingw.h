// Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
// All rights reserved.
// This component and the accompanying materials are made available
// under the terms of the License "Eclipse Public License v1.0"
// which accompanies this distribution, and is available
// at the URL "http://www.eclipse.org/legal/epl-v10.html".
//
// Initial Contributors:
// Nokia Corporation - initial contribution.
//
// Contributors:
//
// Description:
// This is the preinclude file for the MinGW GCC compiler
// 
//

/**
 @file
 @publishedAll
 @released
*/

// compiler and STLport things first 
#define _STLP_THREADS
#define _STLP_DESIGNATED_DLL

// Pick up relevant macros under __GCC32__, since __GCC32__ is not a valid macro for TOOLS2

#define __NO_CLASS_CONSTS__
#define __NORETURN__  __attribute__ ((noreturn))
#ifdef __GCCV3__
#define __NORETURN_TERMINATOR()
#else
#define __NORETURN_TERMINATOR()		abort()
#endif
#define IMPORT_C
#if !defined __WINS__ && defined _WIN32
#define EXPORT_C
/** @internalTechnology */
#define asm(x)
#else
#define EXPORT_C __declspec(dllexport)
#endif
#define NONSHARABLE_CLASS(x) class x
#define NONSHARABLE_STRUCT(x) struct x
#define __NO_THROW
#define __DOUBLE_WORDS_SWAPPED__
typedef long long Int64;
typedef unsigned long long Uint64;
#define	I64LIT(x)	x##LL
#define	UI64LIT(x)	x##ULL
#define TEMPLATE_SPECIALIZATION template<>
#define __TText_defined
typedef wchar_t __TText;


#include <exception>

// A few extras for compiling on Windows
//#ifdef __TOOLS2_WINDOWS__
//#define _STLP_LITTLE_ENDIAN
//#define __MINGW__
//#endif

// Symbian things next ///////////////////////////////////////////////////////

#ifdef __PRODUCT_INCLUDE__
#include __PRODUCT_INCLUDE__
#endif

// Do not use inline new in e32cmn.h
#define __PLACEMENT_NEW_INLINE
#define __PLACEMENT_VEC_NEW_INLINE
// avoid e32tools/filesystem/include/mingw.inl nonsense
#define _MINGW_INL

// the end of the pre-include

