/*
* Copyright (c) 1995-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#ifndef ROM_TOOLS_ROFSBUILD_LOGGING_LOGGINGEXCEPTION_H_
#define ROM_TOOLS_ROFSBUILD_LOGGING_LOGGINGEXCEPTION_H_


/*
 * @class LoggingException
 */
class LoggingException
{
public:
	LoggingException(int ErrorCode);

	int GetErrorCode(void);

	const char* GetErrorMessage(void);

	static int RESOURCE_ALLOCATION_FAILURE;
	static int INVALID_LOG_FILENAME       ;
	static int UNKNOWN_IMAGE_TYPE	      ;

	virtual ~LoggingException(void);
protected:
	int errcode;
private:
	LoggingException(void);

	LoggingException& operator = (const LoggingException&);
};


#endif  /* defined ROM_TOOLS_ROFSBUILD_LOGGING_LOGGINGEXCEPTION_H_ */
