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

char test[]="Assembler test";

void fake_assembler_function1(void);
void fake_assembler_function2(void);

TInt E32Main()
{
	fake_assembler_function1();
	fake_assembler_function2();
	return 0;
}
