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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <new>

#ifdef WIN32
#include <windows.h>
#else
#include <strings.h>
#include <iconv.h>
#endif

#include "uniconv.hpp"


int UniConv::DefaultCodePage2UTF8(const char* DCPStringRef, unsigned int DCPLength, char** UTF8StringRef, unsigned int* UTFLength) throw ()
{
	int reslen = -1;

	if(!UTF8StringRef || !UTFLength || !DCPStringRef)
		return (int)-1;

#ifdef WIN32
	//make Unicode string from its default code page
	reslen = MultiByteToWideChar(CP_ACP, 0, DCPStringRef, DCPLength, NULL, 0);
	if(0 == reslen)
		return (int)-1;
	WCHAR* unistr = new (std::nothrow) WCHAR[reslen+1];
	if(!unistr)
		return (int)-1;

	reslen = MultiByteToWideChar(CP_ACP, 0, DCPStringRef, DCPLength, unistr, reslen);
	if(0 == reslen)
	{
		delete[] unistr;
		return (int)-1;
	}

	//make UTF-8 string from its Unicode encoding
	unsigned int realutflen = 0;
	realutflen = WideCharToMultiByte(CP_UTF8, 0, unistr, reslen, NULL, 0, NULL, NULL);
	if(0 == realutflen)
	{
		delete[] unistr;
		return (int)-1;
	}
	if(realutflen+1 > *UTFLength)
	{
		if(*UTF8StringRef)
			delete[] *UTF8StringRef;
		*UTF8StringRef = new (std::nothrow) char[realutflen+1];
		if(!*UTF8StringRef)
		{
			delete[] unistr;
			*UTFLength = 0;
			return (int)-1;
		}
	}
	*UTFLength = realutflen;
	reslen = WideCharToMultiByte(CP_UTF8, 0, unistr, reslen, *UTF8StringRef, *UTFLength, NULL, NULL);
	(*UTF8StringRef)[realutflen] = 0;

	if(0 == reslen)
		reslen = (int)-1;

	//clean up temporarily allocated resources
	delete[] unistr;
#else
	//character set format: language[_territory][.codeset][@modifier]
	char* dcp = getenv("LANG");
	if(!dcp)
		return (int)-1;
	char* dot = strstr(dcp, ".");
	if(dot)
		dcp += ((dot-dcp) + 1);
	char* atmark = strstr(dcp, "@");
	if(atmark)
		*(atmark) = 0;
	if(strcasecmp(dcp, "UTF-8") == 0)
	{
		strcpy(*UTF8StringRef, DCPStringRef);
		*UTFLength = DCPLength;
		return DCPLength;
	}
	iconv_t convhan = iconv_open("UTF-8", dcp);
	if((iconv_t)(-1) == convhan)
		return (int)-1;
	char* utf8str = new (std::nothrow) char[DCPLength*4];
	if(!utf8str)
	{
		iconv_close(convhan);
		return (int)-1;
	}
	int realutflen = DCPLength*4;
	int origLen = realutflen;
	char* pout = utf8str;
	if(iconv(convhan, const_cast<char**>(&DCPStringRef), (size_t*)&DCPLength, &pout, (size_t*)&realutflen) < 0)
	{
		iconv_close(convhan);
		delete[] utf8str;
		return (int)-1;
	}
	realutflen = origLen - realutflen;
	if((unsigned int)(realutflen+1) > *UTFLength)
	{
		if(*UTF8StringRef)
			delete[] *UTF8StringRef;
		*UTF8StringRef = new (std::nothrow) char[realutflen+1];
		if(!*UTF8StringRef)
		{
			delete[] utf8str;
			iconv_close(convhan);
			return (int)-1;
		}
	}
	strncpy(*UTF8StringRef, utf8str, realutflen);
	(*UTF8StringRef)[realutflen] = 0;
	*UTFLength = realutflen;
	reslen = realutflen;
	delete[] utf8str;
	iconv_close(convhan);
#endif

	return reslen;
}

int UniConv::UTF82DefaultCodePage(const char* UTF8StringRef, unsigned int UTFLength, char** DCPStringRef, unsigned int* DCPLength) throw ()
{
	int reslen = -1;

	if(!DCPStringRef || !DCPLength || !UTF8StringRef)
		return (int)-1;

#ifdef WIN32
	//make Unicode string from its UTF-8 encoding
	reslen = MultiByteToWideChar(CP_UTF8, 0, UTF8StringRef, UTFLength, NULL, 0);
	if(0 == reslen)
		return (int)-1;
	WCHAR* unistr = new (std::nothrow) WCHAR[reslen+1];
	if(!unistr)
		return (int)-1;

	reslen = MultiByteToWideChar(CP_UTF8, 0, UTF8StringRef, UTFLength, unistr, reslen);
	if(0 == reslen)
	{
		delete[] unistr;
		return (int)-1;
	}

	//make default code paged string from its Unicode encoding
	unsigned int realdcplen = 0;
	realdcplen = WideCharToMultiByte(CP_ACP, 0, unistr, reslen, NULL, 0, NULL, NULL);
	if(0 == realdcplen)
	{
		delete[] unistr;
		return (int)-1;
	}
	if(realdcplen+1 > *DCPLength)
	{
		if(*DCPStringRef)
			delete[] *DCPStringRef;
		*DCPStringRef = new (std::nothrow) char[realdcplen+1];
		if(!*DCPStringRef)
		{
			delete[] unistr;
			*DCPLength = 0;
			return (int)-1;
		}
	}
	*DCPLength = realdcplen;
	reslen = WideCharToMultiByte(CP_ACP, 0, unistr, reslen, *DCPStringRef, *DCPLength, NULL, NULL);
	(*DCPStringRef)[realdcplen] = 0;

	if(0 == reslen)
		reslen = (int)-1;

	//clean up temporarily allocated resources
	delete[] unistr;
#else
	//character set format: language[_territory][.codeset][@modifier]
	char* dcp = getenv("LANG");
	if(!dcp)
		return (int)-1;

	char* dot = strstr(dcp, ".");
	if(dot)
		dcp += ((dot-dcp) + 1);
	char* atmark = strstr(dcp, "@");
	if(atmark)
		*(atmark) = 0;
	iconv_t convhan = iconv_open(dcp, "UTF-8");
	if((iconv_t)(-1) == convhan)
		return (int)-1;
	char* dcpstr = new (std::nothrow) char[UTFLength*4];
	if(!dcpstr)
	{
		iconv_close(convhan);
		return (int)-1;
	}
	int realdcplen = UTFLength*4;
	int origLen = realdcplen;
	char* pout = dcpstr;
	if(iconv(convhan, const_cast<char**>(&UTF8StringRef), (size_t*)&UTFLength, &pout, (size_t*)&realdcplen) < 0)
	{
		iconv_close(convhan);
		delete[] dcpstr;
		return (int)-1;
	}
	realdcplen = origLen - realdcplen;
	if((unsigned int)(realdcplen+1) > *DCPLength)
	{
		if(*DCPStringRef)
			delete[] *DCPStringRef;
		*DCPStringRef = new (std::nothrow) char[realdcplen+1];
		if(!*DCPStringRef)
		{
			delete[] dcpstr;
			iconv_close(convhan);
			return (int)-1;
		}
	}
	strncpy(*DCPStringRef, dcpstr, realdcplen);
	(*DCPStringRef)[realdcplen] = 0;
	*DCPLength = realdcplen;
	reslen = realdcplen;
	delete[] dcpstr;
	iconv_close(convhan);
#endif

	return reslen;
}


bool UniConv::IsPureASCIITextStream(const char* StringRef) throw ()
{
	while (*StringRef && !(*StringRef++ & 0x80))
		;
	if (*StringRef)
		return false;
	else
		return true;
}
