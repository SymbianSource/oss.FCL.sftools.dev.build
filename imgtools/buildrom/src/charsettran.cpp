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

#include <iostream>
#include <string>
#include "uniconv.hpp"
#include "h_utl.h"

using namespace std;

void UTF82Host();
void Host2UTF8();
void PrintUsage();
const unsigned int maxlength = 512;
const float version = 0.1;

int main(int argc, char* argv[])
{
	if(argc != 2)
	{
		PrintUsage();
		return 0;
	}
	if(strncmp(argv[1], "-to=", 4))
	{
		cout << "Error parameters!" << endl;
		return 0;
	}
	char * p = argv[1]+4;
	if(!strnicmp(p, "hostcharset", 11))
	{
		UTF82Host();
	}
	else if(!strnicmp(p, "utf8", 4) || !strnicmp(p, "utf-8", 5))
	{
		Host2UTF8();
	}
	else
	{
		PrintUsage();
	}
}
void PrintUsage()
{
	cout << "Charset translation tool - version: " << version << endl;
	cout << "Usage: charsettran -to=[utf8|hostcharset]" << endl;
}
void UTF82Host()
{
	string tmpline;
	char* tmpBuf = new char[maxlength];
	unsigned int strLen = maxlength;
	while(getline(cin, tmpline))
	{
		if(UniConv::IsPureASCIITextStream(tmpline.c_str()))
		{
			cout << tmpline << endl;
			continue;
		}
		unsigned int outLen = maxlength;
		int ret = UniConv::UTF82DefaultCodePage(tmpline.c_str(), tmpline.length(), &tmpBuf, &outLen);
		if(ret == -1)
		{
			cout << tmpline << endl;
			continue;
		}
		if(outLen > strLen)
		{
			strLen = outLen;
		}
		cout << tmpBuf << endl;

	}
	delete[] tmpBuf;
}
void Host2UTF8()
{
	string tmpline;
	char* tmpBuf = new char[maxlength];
	unsigned int strLen = maxlength;
	while(cin >> tmpline)
	{
		if(UniConv::IsPureASCIITextStream(tmpline.c_str()))
		{
			cout << tmpline << endl;
			continue;
		}
		unsigned int outLen = maxlength;
		int ret = UniConv::DefaultCodePage2UTF8(tmpline.c_str(), tmpline.length(), &tmpBuf, &outLen);
		if(ret == -1)
		{
			cout << tmpline << endl;
			continue;
		}
		if(outLen > strLen)
		{
			strLen = outLen;
		}
		cout << tmpBuf << endl;

	}
	delete[] tmpBuf;
}
