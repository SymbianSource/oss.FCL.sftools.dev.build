/*
* Copyright (c) 2000-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* test.cpp
* Test the use of a string pool
*
*/


#include "CommonFramework.h"
#include <strconsts.h>


// do the example
LOCAL_C void doExampleL()
{
        RStringPool pool;
	RString helloString;
	TBuf<100> wideHello;


        pool.OpenL(strconsts::Table);
	helloString = pool.String(strconsts::EHelloWorld,strconsts::Table);
	wideHello.Copy(helloString.DesC());
	console->Printf(wideHello);
        pool.Close();
}
