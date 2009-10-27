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
* Error Handler Class for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef ERRORHANDLER_H
#define ERRORHANDLER_H

#include "messagehandler.h"
#include "constants.h"
#include <iostream>
#include <stdio.h>

/**
Class for Error handling

@internalComponent
@released
*/
class ErrorHandler
{
	public:
		ErrorHandler(int aMessageIndex,char* aSubMessage,char* aFileName, int aLineNumber);
        ErrorHandler(int aMessageIndex, char* aFileName, int aLineNumber);
		virtual ~ErrorHandler();
		void Report();

		String iMessage;
		int iMessageIndex;
		String iSubMessage;
        String iFileName;
        int iLineNumber;
};

#endif //ERRORHANDLER_H
