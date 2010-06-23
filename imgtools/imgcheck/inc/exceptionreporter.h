/*
* Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Class ExceptionReporter declaration
* @internalComponent
* @released
*
*/


#ifndef EXCEPTIONREPORTER_H
#define EXCEPTIONREPORTER_H

#include "exceptionimplementation.h"
#include <stdarg.h>

/** 
class exception reporter

@internalComponent
@released
*/
class ExceptionReporter
{
public:
	ExceptionReporter(int aMsgIndex, ...);
	~ExceptionReporter(void);
	void Log(void) const;
	void Report(void) const;

private:
	string iMessage;
	ExceptionImplementation* iExcepImplPtr;
};

#endif //EXCEPTIONREPORTER_H


