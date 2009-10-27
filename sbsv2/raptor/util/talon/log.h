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




#ifndef _TALONLOG_H_
#define _TALONLOG_H_

#define LOGNONE 0
#define LOGNORMAL 0
#define LOGDEBUG 1
#define DEBUG(xxx) debug xxx

extern int loglevel;

int debug(const char *format, ...);
int error(const char *format, ...);

#endif
