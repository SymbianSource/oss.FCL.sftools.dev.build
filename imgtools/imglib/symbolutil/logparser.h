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

#include "loggingexception.h"
#include "symbolgenerator.h"

/**
 * @class LogParser
 */
class LogParser
{
public:
	static LogParser* GetInstance(TImageType aImageType) throw (LoggingException);

	virtual void ParseSymbol(const char* LogFilename) throw (LoggingException) = 0;

	void Cleanup(void);
	virtual ~LogParser() {}
protected:
	LogParser(void);
	static LogParser* Only;
	TImageType iImageType;
private:
	LogParser(const LogParser&);

	LogParser& operator = (const LogParser&);
};

class RofsLogParser : public LogParser
{
public:
	virtual void ParseSymbol(const char* LogFilename) throw (LoggingException);
	RofsLogParser(void);
};

class RomLogParser : public LogParser
{
public:
	virtual void ParseSymbol(const char* LogFilename) throw (LoggingException);
	RomLogParser(void);
};



#endif  /* defined ROM_TOOLS_ROFSBUILD_LOGGING_LOGPARSER_H_ */
