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
* Long name class for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef LONGNAME_H
#define LONGNAME_H

#include "cluster.h"
#include "longentry.h"

#define ToString(dataInteger) reinterpret_cast<char*>(&dataInteger),sizeof(dataInteger)

typedef std::stack<CLongEntry*> LongEntryStack;
typedef std::list<String> StringList;

//Long entry sub name lengths
enum TLongSubNameLength
{
	ESubName1Length = 5,
	ESubName2Length = 6,
	ESubName3Length = 2
};

//Name length constants
enum TNameLength
{
	EExtensionLength = 0x03,
	EShortNameInitialLength = 0x06,
	ETildeNumberPosition = 0x07,
	ENameLength = 0x8,
	ENameLengthWithExtension = 0x0B
};

//Holds all the short directory entry.
static StringList GShortEntryList;

/**
This class is used to prepare Long Name Directory entry portion of Directory Entry region

@internalComponent
@released
*/
class ClongName
{
private:
	StringList iSubNamesList;		//Holds the splitted file names 
	LongEntryStack iLongEntryStack;	//Holds all the long name directory entry node's
	unsigned int iClusterNumber;	//Current cluster number, where the current long entry needs to be written
	CCluster* iClusterPtr;
	String iLongName;
	char iLongEntryAttribute;
	String iShortName;
	unsigned int iLongNameLength;
	unsigned int iTildeNumberPosition;
	/**If the received sub name entry size is equal to its expected length, then
	two NULL character should be preceded at the start of next sub name 
	*/
	bool iSubNameProperEnd; //Is name ends without NULL character termination?
	bool iFirstNullName;// Is first name ending with NULL character?

private:
	String GetShortEntryName();
	unsigned char CalculateCheckSum();
	void WriteLongEntry(CLongEntry* aLongEntry,String& longEntryString);
	void WriteSubName(String& aSubName,unsigned short aSubNameLength,
					  String& alongEntryString);
	void FormatLongFileName(String& aLongName);
	void CheckAndUpdateShortName(String& aShortName);
	void PushAndErase(String& aFirstName,String& aSecondName,String& aThirdName);
	void GetSubName(String& aLongName,
				   int& aStartIndex,
				   int& aStringLength,
				   int aSubNameLength,
				   String& aSubName);
	void PopAndErase();
	void CalculateExtentionLength();

public:
	ClongName(CCluster* aClusterPtr, CDirectory* aEntry);
	~ClongName();
	CDirectory* CreateShortEntry(CDirectory* aEntry);
	String CreateLongEntries();
	static void DestroyShortEntryList();
};

#endif //LONGNAME_H
