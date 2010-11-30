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
#include <boost/regex.hpp>
using namespace std;

#include "loggingexception.h"
#include "logparser.h"


LogParser* LogParser::Only = (LogParser*)0;


 
LogParser* LogParser::GetInstance(TImageType aImageType) throw (LOGGINGEXCEPTION) 
{
	if(! LogParser::Only)
	{
		if(aImageType == ERomImage)
		{
			LogParser::Only = new (std::nothrow) RomLogParser();
		}
		else if(aImageType == ERofsImage)
		{
			LogParser::Only = new (std::nothrow) RofsLogParser();
		}
		else
		{
			throw LoggingException(LoggingException::UNKNOWN_IMAGE_TYPE);
		}
		if(! LogParser::Only)
			throw LoggingException(LoggingException::RESOURCE_ALLOCATION_FAILURE);
	}

	return LogParser::Only;
}

void LogParser::Cleanup(void)
{
	return;
}


LogParser::LogParser(void)
{
	iImageType = EUnknownType;
	return;
}

RofsLogParser::RofsLogParser()
{
	iImageType = ERofsImage;
}
 
void RofsLogParser::ParseSymbol(const char* LogFilename) throw (LOGGINGEXCEPTION) 
{
	string linebuf;
	SymbolGenerator* symgen = SymbolGenerator::GetInstance();
	symgen->SetImageType(iImageType);
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
			else if(linebuf.compare(0,15,"Executable File") == 0)
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

RomLogParser::RomLogParser()
{
	iImageType = ERomImage;
}

void RomLogParser::ParseSymbol(const char* LogFilename) throw (LOGGINGEXCEPTION)
{
	string linebuf;
	SymbolGenerator* symgen = SymbolGenerator::GetInstance();
	symgen->SetImageType(iImageType);
	symgen->SetSymbolFileName(string(LogFilename));

	ifstream logfd(LogFilename);
	if(logfd.is_open())
	{
		//boost::regex beginFlag("^Creating Rom image (\\S*)");
		boost::regex endFlag("^Writing Rom image");
		boost::regex sourceFile("^Reading resource (.*) to rom linear address (.*)");
		boost::regex executableFile("^Processing file (.*)");
		boost::regex codeStart("^Code start addr:\\s*(\\w+)");
		boost::regex dataStart("^Data start addr:\\s+(\\w+)");
		boost::regex dataBssStart("^DataBssLinearBase:\\s+(\\w+)");
		boost::regex textSize("^Text size:\\s+(\\w+)");
		boost::regex dataSize("^Data size:\\s+(\\w+)");
		boost::regex bssSize("Bsssize:\\s+(\\w+)");
		boost::regex totalDataSize("^Total data size:\\s+(\\w+)");
		string tmpline, tmpaddr;
		boost::cmatch what;
		while(getline(logfd, tmpline))
		{
			TPlacedEntry tmpEntry;
			if(regex_search(tmpline.c_str(), what, endFlag))
			{
				break;
			}
			if(regex_search(tmpline.c_str(), what, sourceFile))
			{
				tmpEntry.iFileName.assign(what[1].first, what[1].second-what[1].first);
				tmpaddr.assign(what[2].first, what[2].second-what[2].first);
				tmpEntry.iDataAddress = strtol(tmpaddr.c_str(), NULL, 16);
				symgen->AddEntry(tmpEntry);
			}
			else if(regex_search(tmpline.c_str(), what, executableFile))
			{
				tmpEntry.iFileName.assign(what[1].first, what[1].second-what[1].first);
				while(getline(logfd, tmpline) && tmpline != "")
				{
					if(regex_search(tmpline.c_str(), what, codeStart))
					{
						tmpaddr.assign(what[1].first, what[1].second-what[1].first);
						tmpEntry.iCodeAddress = strtol(tmpaddr.c_str(), NULL, 16);
					} 
					else if(regex_search(tmpline.c_str(), what, dataStart))
					{
						tmpaddr.assign(what[1].first, what[1].second-what[1].first);
						tmpEntry.iDataAddress = strtol(tmpaddr.c_str(), NULL, 16);
					}
					else if(regex_search(tmpline.c_str(), what, dataBssStart))
					{
						tmpaddr.assign(what[1].first, what[1].second-what[1].first);
						tmpEntry.iDataBssLinearBase = strtol(tmpaddr.c_str(), NULL, 16);
					}
					else if(regex_search(tmpline.c_str(), what, textSize))
					{
						tmpaddr.assign(what[1].first, what[1].second-what[1].first);
						tmpEntry.iTextSize = strtol(tmpaddr.c_str(), NULL, 16);
					}
					else if(regex_search(tmpline.c_str(), what, dataSize))
					{
						tmpaddr.assign(what[1].first, what[1].second-what[1].first);
						tmpEntry.iDataSize = strtol(tmpaddr.c_str(), NULL, 16);
					}
					else if(regex_search(tmpline.c_str(), what, bssSize))
					{
						tmpaddr.assign(what[1].first, what[1].second-what[1].first);
						tmpEntry.iBssSize = strtol(tmpaddr.c_str(), NULL, 16);
					}
					else if(regex_search(tmpline.c_str(), what, totalDataSize))
					{
						tmpaddr.assign(what[1].first, what[1].second-what[1].first);
						tmpEntry.iTotalDataSize = strtol(tmpaddr.c_str(), NULL, 16);
					}
				}
				symgen->AddEntry(tmpEntry);
			}


		}
		symgen->SetFinished();
		symgen->Release();
	}
	else
	{
		throw LoggingException(LoggingException::INVALID_LOG_FILENAME);
	}
}

