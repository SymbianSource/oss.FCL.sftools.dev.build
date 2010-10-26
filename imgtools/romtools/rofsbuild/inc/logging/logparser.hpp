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


#ifndef ROM_TOOLS_ROFSBUILD_LOGGING_LOGPARSER_H_
#define ROM_TOOLS_ROFSBUILD_LOGGING_LOGPARSER_H_


/**
 * @class LogParser
 */
class LogParser
{
public:
	static LogParser* GetInstance(void) throw (LoggingException);

	void ParseSymbol(const char* LogFilename) throw (LoggingException);

	void Cleanup(void);
protected:
	static LogParser* Only;
private:
	LogParser(void);

	LogParser(const LogParser&);

	LogParser& operator = (const LogParser&);
};



#endif  /* defined ROM_TOOLS_ROFSBUILD_LOGGING_LOGPARSER_H_ */
