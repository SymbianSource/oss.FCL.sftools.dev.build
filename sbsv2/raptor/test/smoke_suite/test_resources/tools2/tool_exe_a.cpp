/*
* Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of the License "Eclipse Public License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.eclipse.org/legal/epl-v10.html".
*
* Initial Contributors:
* Nokia Corporation - initial contribution.
*
* Contributors:
*
* Description: 
*
*/

// the product HRH file
#ifdef __PRODUCT_INCLUDE__
#include __PRODUCT_INCLUDE__
#endif

// in the current directory
#include "header_abc.h"

// USERINCLUDES
#include "header_def.h"
#include "header_ghi.h"

// SYSTEMINCLUDES
#include <header_jkl.h>
#include <header_mno.h>

int tool_exe_b(int);
int tool_lib1_a(int);
int tool_lib1_b(int);
int tool_lib2_a(int);
int tool_lib2_b(int);


#include "../inc/macrotests.h"

int main(int argc, char *argv[])
{
    // use all the functions

	int a = tool_lib1_a(argc) + tool_lib2_a(argc);
	int b = tool_lib1_b(argc) + tool_lib2_b(argc);

	// defined in the headers
	int caps = A + B + C + D + E + F + G + H + I + J + K + L + M + N + O;

	return tool_exe_b(a + b + caps);
}
