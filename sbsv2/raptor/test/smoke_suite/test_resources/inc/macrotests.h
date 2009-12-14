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
/* Different platforms (e.g. tools2 and the rest) can use 
   this to test that their FLMs
   support the MACRO keyword and that they support
   complex macros with quotes and parentheses.

   Make your mmp include macrotest.mmh to declare the appropriate macros
*/


#if !defined(MACRO_ADDED_FOR_TESTING)
#error Expected MACRO "MACRO_ADDED_FOR_TESTING" from the MMP but it is not defined
#endif

#define MULTIPLYBY100(x) x##00

#if COMPLEXMACRO != 100 
#error Expected  MACRO "##COMPLEXMACRO=MULTUPLYBY100(1)" from the MMP but it is not defined
#endif

