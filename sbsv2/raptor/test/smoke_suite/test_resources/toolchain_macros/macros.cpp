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


#include "e32def.h"

TInt E32Main()
	{

// Confirm macro presence in processing through warnings

#ifdef __ARMCC__
#warning __ARMCC__
#endif

#ifdef __ARMCC_2__
#warning __ARMCC_2__
#endif

#ifdef __ARMCC_2_2__
#warning __ARMCC_2_2__
#endif

#ifdef __ARMCC_3__
#warning __ARMCC_3__
#endif

#ifdef __ARMCC_3_1__
#warning __ARMCC_3_1__
#endif

#ifdef __ARMCC_4__
#warning __ARMCC_4__
#endif

#ifdef __ARMCC_4_0__
#warning __ARMCC_4_0__
#endif

#ifdef __GCCE__
#warning __GCCE__
#endif

#ifdef __GCCE_4__
#warning __GCCE_4__
#endif

#ifdef __GCCE_4_3__
#warning __GCCE_4_3__
#endif

#ifdef __GCCE_4_4__
#warning __GCCE_4_4__
#endif

	return 0;
	}
