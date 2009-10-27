/*
* Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Since the filesystem componenet is standalone, it is not using any definitions from Symbian EPOC.
* So the inclusion of unavailable definition are much important to avoid compile time errors
* @internalComponent
* @released
*
*/


#ifndef _MINGW_INL
#define _MINGW_INL

#ifndef __LINUX__
	#ifndef _MSC_VER

		/*
		 * TOOLS2 platform uses Mingw compiler, which does not have below definition in the compiler pre-include
		 * file "gcc_mingw_3_4_2.h" placed at "/epoc32/include/gcc_mingw".
		 */
		inline void* operator new(unsigned int, void* __p) throw() { return __p; }
	#endif
#endif

#endif //MINGW_INL
