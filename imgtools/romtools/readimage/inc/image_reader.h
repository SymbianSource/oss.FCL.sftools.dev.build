/*
* Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* @internalComponent
* @released
*
*/


#ifndef __IMAGE_READER__
#define __IMAGE_READER__

#if defined(__VC32__) && (_MSC_VER < 1300)
#pragma warning(disable:4786) // std::map etc overflow debug symbol length :(
#endif


#include "common.h"
#include <direct.h>
#include <map>

typedef struct tag_FILEINFO
{
	TUint32 iOffset;
	TUint32 iSize;
}FILEINFO, *PFILEINFO;

typedef std::map<std::string, PFILEINFO> FILEINFOMAP;

class ImageReader
{
public:
	ImageReader(const char* aFile);
	virtual ~ImageReader();
	
	virtual void ReadImage()	= 0;
	virtual void ProcessImage() = 0;
	virtual void Validate()		= 0;
	virtual void Dump()			= 0;
	
	virtual void ExtractImageContents(){}
	void DumpData(TUint* aData, TUint aLength);

	void SetDisplayOptions(TUint32);
	bool DisplayOptions(TUint32);

	void ExtractFile(TUint aOffset, TInt aSize, const char* aFileName, const char* aPath, char* aFilePath,char* aData = NULL);
	void FindAndInsertString(string& aSrcStr,string& aDelimiter,string& aAppStr);
	void FindAndReplaceString(string& aSrcStr, string& aDelimiter, string& aReplStr);
	void CreateSpecifiedDir(char* aSrcPath,const char* aDelimiter);
	TBool IsDrive(char* aStr);

	virtual void GetFileInfo(FILEINFOMAP& /*fileInfoMap */){}
	void ExtractFileSet(char* aData);
	int FileNameMatch(string aPattern, string aFileName, int aRecursiveFlag);

	TUint32	iDisplayOptions;
	string	iImgFileName;
	static string  iZdrivePath;
	static string  iLogFileName;
	static string  iE32ImgFileName;
	static string  iPattern;
};

#endif //__IMAGE_READER__
