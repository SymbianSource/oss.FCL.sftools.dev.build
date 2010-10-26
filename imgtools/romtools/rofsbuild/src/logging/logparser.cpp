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


#include <new>
#include <iostream>
#include <fstream>
#include <string>
using namespace std;

#include "logging/loggingexception.hpp"
#include "logging/logparser.hpp"
#include "symbolgenerator.h"


LogParser* LogParser::Only = (LogParser*)0;


LogParser* LogParser::GetInstance(void) throw (LoggingException)
{
	if(! LogParser::Only)
	{
		LogParser::Only = new (std::nothrow) LogParser();
		if(! LogParser::Only)
			throw LoggingException(LoggingException::RESOURCE_ALLOCATION_FAILURE);
	}

	return LogParser::Only;
}


void LogParser::ParseSymbol(const char* LogFilename) throw (LoggingException)
{
	string linebuf;
	SymbolGenerator* symgen = SymbolGenerator::GetInstance();
	symgen->SetSymbolFileName(string(LogFilename));

	ifstream logfd(LogFilename);
	if(logfd.is_open())
	{
		while(! logfd.eof())
		{
			getline(logfd, linebuf);
			if(linebuf.compare(0,4,"File") == 0)
			{
				if(linebuf.find("size:", 4) != string::npos)
				{
					size_t startpos = linebuf.find('\'') ;
					size_t endpos   = linebuf.rfind('\'');
					if((startpos!=string::npos) && (endpos!=string::npos))
					{
						symgen->AddFile(linebuf.substr(startpos+1,endpos-startpos-1), false);
					}
				}
			}
			else if(linebuf.compare(0,26,"Compressed executable File") == 0)
			{
				if(linebuf.find("size:", 26) != string::npos)
				{
					size_t startpos = linebuf.find('\'') ;
					size_t endpos   = linebuf.rfind('\'');
					if((startpos!=string::npos) && (endpos!=string::npos))
					{
						symgen->AddFile(linebuf.substr(startpos+1,endpos-startpos-1), true);
					}
				}
			}
		}
		symgen->SetFinished();
		symgen->Release();
	}
	else
	{
		throw LoggingException(LoggingException::INVALID_LOG_FILENAME);
	}

	return;
}


void LogParser::Cleanup(void)
{
	return;
}


LogParser::LogParser(void)
{
	return;
}
