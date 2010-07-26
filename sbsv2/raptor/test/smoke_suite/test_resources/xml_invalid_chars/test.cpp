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

TInt E32Main()
{
	TInt t = 1;
	t = 3;
	TInt s = 5;
	s = t + t*3;
	t = s + s*3;
	return 0;
}
