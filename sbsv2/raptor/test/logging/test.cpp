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
#include "e32def.h" // intentional  include

char test[]="Simple test";

TInt test1();
TInt test2();
TInt test3();
TInt test4();
TInt test5();
TInt test6();

TInt E32Main()
{
	test1();
	test2();
	test3();
	test4();
	test5();
	test6();
	return 0;
}
