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
* Message Handler Class for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef MESSAGEHANDLER_H
#define MESSAGEHANDLER_H

#include "messageimplementation.h"

/**
Class for Message Handler which will be used for getting instance of Message Implementation
and start logging, creating message file, initializing messages.

@internalComponent
@released
*/
class MessageHandler
{
    public:
		static Message *GetInstance();
		static void CleanUp();
		static void StartLogging(char *filename);
		static void CreateMessageFile(char *fileName);
		static void ReportMessage(int aMsgType, int aMsgIndex,char* aName);

    private:
		static Message* iInstance;
};

#endif //MESSAGEHANDLER_H
