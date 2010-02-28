/*
* Copyright (c) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
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

#ifdef HOST_WIN
#define HAS_SETENVIRONMENTVARIABLE 1
#define HAS_GETENVIRONMENTVARIABLE 1
#define HAS_GETCOMMANDLINE 1
#define HAS_MILLISECONDSLEEP 1
#define HAS_MSVCRT 1
#define HAS_WINSOCK2 1
#else
#define HAS_POLL 1
#define HAS_SETENV 1
#define HAS_GETENV 1
#define HAS_STDLIBH 1
#endif
