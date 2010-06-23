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
* Receives the long file name and prepares short and long directory 
* entries.
* @internalComponent
* @released
*
*/


#include "longname.h"


/** 
Constructor: Responsible to create 
1. Short entry
2. Sub components of long entry name as per microsoft FAT spec.

@internalComponent
@released

@param aClusterPtr - Cluster instance address
@param aEntry - CDirectory class pointer
*/

ClongName::ClongName(CCluster* aClusterPtr,
					 CDirectory* aEntry):
					 iClusterPtr(aClusterPtr),
					 iTildeNumberPosition(ETildeNumberPosition),
					 iSubNameProperEnd(false),
					 iFirstNullName(false)
{
	iLongName = aEntry->GetEntryName();
	iLongEntryAttribute = aEntry->GetEntryAttribute();
	iClusterNumber = aClusterPtr->GetCurrentClusterNumber();
	iLongNameLength = iLongName.length();
	if(iLongNameLength == 0)
	{
		throw ErrorHandler(EMPTYFILENAME, __FILE__, __LINE__);
	}
	FormatLongFileName(iLongName);
	iShortName = GetShortEntryName();
	GShortEntryList.push_back(iShortName);
}


/**
Static function to clear the strings stored in static Global Stringlist

@internalComponent
@released
*/
void ClongName::DestroyShortEntryList()
{
	GShortEntryList.clear();
}

/**
Destructor: To clear the contents from the STL containers in any exception case.
In normal case the containers are cleared once its usage is finished

@internalComponent
@released
*/

ClongName::~ClongName()
{
	iSubNamesList.clear();
	while(iLongEntryStack.size() > 0)
	{
		delete iLongEntryStack.top();
		iLongEntryStack.pop();
	}
	/* Cluster instance should be deleted only by dirregion, So just assign 
	 * NULL value to the pointer
	 */
	iClusterPtr = NULL;
}

/**
Function takes a long entry and writes all of the attributes into iLongNameEntryString.
To write the sub name's in a formatted WriteSubName() function invoked

@internalComponent
@released

@param aLongEntry - the long entry
*/
void ClongName::WriteLongEntry(CLongEntry* aLongEntry,string& longEntryString)
{
	longEntryString.append(KWriteOnce, aLongEntry->GetDirOrder());
	WriteSubName(aLongEntry->GetSubName1(),(ESubName1Length*2),longEntryString);
	longEntryString.append(KWriteOnce, aLongEntry->GetAttribute());
	longEntryString.append(KWriteOnce, aLongEntry->GetDirType());
	longEntryString.append(KWriteOnce, aLongEntry->GetCheckSum());
	WriteSubName(aLongEntry->GetSubName2(),(ESubName2Length*2),longEntryString);
	unsigned short int lowClusterNumber = aLongEntry->GetClusterNumberLow();
	longEntryString.append(ToString(lowClusterNumber));
	WriteSubName(aLongEntry->GetSubName3(),(ESubName3Length*2),longEntryString);
}

/**
Function responsible to 
1. Write the sub name of the long entry, every character splitted by '.'(00)
2. If the name is not multiple of 13 this function applies NULL character padding and 
   padding with 'FF'.

@internalComponent
@released

@param aName - Sub name of a long entry
@param aSubNameLength - No of characters to be filled
@param alongEntryString - formatted sub name appended to this string
*/
void ClongName::WriteSubName(string& aSubName,unsigned short aSubNameLength,string& alongEntryString)
{
	unsigned int subNameCurrLength = aSubName.length();
	if(subNameCurrLength == 0)
	{
		iFirstNullName = true;
	}
	else
	{
		iFirstNullName = false;
	}
	unsigned int beginIndex = 1;
	if(subNameCurrLength > 0)
	{
		//Insert zero between every character, as per FAT spec requirement
		while(subNameCurrLength > 0)
		{
			aSubName.insert(beginIndex,1,0); //Insert zero once
			beginIndex += 2; //Jump 2 characters
			--subNameCurrLength;
		}
		subNameCurrLength = aSubName.length();
		if(subNameCurrLength == aSubNameLength)
		{
			iSubNameProperEnd = true;
		}
		//Apply padding with two zero's to mention Long Name end.
		if(subNameCurrLength < aSubNameLength)
		{
			aSubName.insert(subNameCurrLength, KPaddingCharCnt, 0); 
			iSubNameProperEnd = false;
		}
	}
	subNameCurrLength = aSubName.length();
	if((iSubNameProperEnd == true) && (iFirstNullName == true))
	{
		aSubName.insert(subNameCurrLength, KPaddingCharCnt, 0);
		iSubNameProperEnd = false;
		iFirstNullName = false;
	}
	subNameCurrLength = aSubName.length();
	//Insert FF for all unfilled characters.
	if(subNameCurrLength < aSubNameLength)
	{
			aSubName.insert(subNameCurrLength,(aSubNameLength - subNameCurrLength),
							KLongNamePaddingChar);
	}
	alongEntryString.append(aSubName.c_str(),aSubName.length());
}

/**
Function responsible to push the string into iNameList container and to erase the input
strings data

@internalComponent
@released

@param aFirstName - first sub name
@param aSecondName - Second sub name
@param aThirdName - third sub name
*/
void ClongName::PushAndErase(string& aFirstName,string& aSecondName,string& aThirdName)
{
	iSubNamesList.push_back(aFirstName);
	aFirstName.erase();
	iSubNamesList.push_back(aSecondName);
	aSecondName.erase();
	iSubNamesList.push_back(aThirdName);
	aThirdName.erase();
}

/**
Function responsible split single sub name from the long name

@internalComponent
@released

@param aLongName - The long name need to be splitted
@param aStartIndex - Sub name starting index
@param aStringLength - total string length
@param aSubNameLength - Length of the Sub Name of required length
@param aSubName - splitted Sub Name assigned using this string
*/
void ClongName::GetSubName(string& aLongName,
						   int& aStartIndex,
						   int& aStringLength,
						   int aSubNameLength,
						   string& aSubName)
{
	if((aStartIndex + aSubNameLength) <= aStringLength)
	{
		aSubName = aLongName.substr(aStartIndex,aSubNameLength);
		aStartIndex += aSubNameLength;
		return;
	}
	aSubName = aLongName.substr(aStartIndex);
	aStartIndex += aSubName.length();
}

/** 
Function to split the long file name into smaller sub names,such as it should be 
written into long directory entries. All splitted names are pushed into the 
iNameList container.

@internalComponent
@released
*/
void ClongName::FormatLongFileName(string& aLongName)
{
	int stringLength = aLongName.length();
	int startIndex = 0;
	string iSubName1;
	string iSubName2;
	string iSubName3;

	while(startIndex < stringLength)
	{
		GetSubName(aLongName,startIndex,stringLength,ESubName1Length,iSubName1);
		GetSubName(aLongName,startIndex,stringLength,ESubName2Length,iSubName2);
		GetSubName(aLongName,startIndex,stringLength,ESubName3Length,iSubName3);
		PushAndErase(iSubName1,iSubName2,iSubName3);
	}
}

/**
Function responsible to create new short name if the currently generated short name 
already exists. 

eg. Input:UNITTE~1TXT returns:UNITTE~2TXT

@internalComponent
@released

@return - returns the short name
*/
void ClongName::CheckAndUpdateShortName(string& aShortName)
{
	char trailingChar;
	StringList::iterator beginIter = GShortEntryList.begin();
	StringList::iterator endIter = GShortEntryList.end();
	string tempString;
	while(beginIter != endIter)
	{
		tempString = (*beginIter);
		if(strcmp(tempString.c_str(),aShortName.c_str()) == 0)
		{
			trailingChar = aShortName.at(iTildeNumberPosition);
			aShortName[iTildeNumberPosition] = ++trailingChar; //Increment the character value by 1
			continue;
		}
		++beginIter;
	}
        int gap = ENameLengthWithExtension - aShortName.length();
        if(gap >0 )
            aShortName.append(gap,KSpace);
}

/**
Function responsible to take the long file name as input and to prepare the short name.
e.g. Long File Name.pl to LONGFI~1PL

@internalComponent
@released

@return - returns the short name
*/

string ClongName::GetShortEntryName()
{
	string shortName;
	unsigned int extensionIndex = iLongName.find_last_of(KDot);

	unsigned int dotIndex = extensionIndex;
	//Erase all the dots from the string, but keep the extension index 
	while(dotIndex != string::npos)
	{
		iLongName.erase(dotIndex,1); //Erase the dot
		dotIndex = iLongName.find_first_of(KDot);
		if(dotIndex != string::npos)
		{
			//Decrement only if more than one dot exists
			--extensionIndex;
		}
	}

	if((iLongEntryAttribute & EAttrDirectory)== 0) 
	{
		if(extensionIndex <= EShortNameInitialLength)
		{
			//if the full name length is less than 6 characters, assign the whole name
			shortName.assign(iLongName.c_str(),extensionIndex);
		}
		else
		{
			shortName.assign(iLongName.c_str(),EShortNameInitialLength);
		}
		//+1 is added to get '~' symbol position
		iTildeNumberPosition = shortName.length() + 1;
	}
	else
	{
		shortName.assign(iLongName.c_str(),EShortNameInitialLength);
	}
	shortName += KTilde;
	shortName += KTildeNumber;
	shortName.assign(ToUpper(shortName));
	if(extensionIndex <  iLongName.length()) //to identify whether the name has any extension.
	{
		if(shortName.length() < ENameLength)
		{
			shortName.append((ENameLength - shortName.length()),KSpace);
		}
		string shortNameString = iLongName.substr(extensionIndex,EExtensionLength);
		shortName.append(ToUpper(shortNameString));
		CheckAndUpdateShortName(shortName);
		return shortName;
	}
	//extension padding
	shortName.append(EExtensionLength,KSpace);
	CheckAndUpdateShortName(shortName);
	return shortName;
}

/**
Function takes the short entry name as input and calculates checksum as per the 
Microsoft FAT spec.

@internalComponent
@released

@return - returns checkSum
*/

unsigned char ClongName::CalculateCheckSum()
{
	char* tempShortNamePtr = (char*)iShortName.c_str();
	unsigned short int nameLength = 0;
	unsigned char chckSum = '\0';
	for(nameLength = ENameLengthWithExtension; nameLength != 0; nameLength--)
	{
		chckSum = ((chckSum & 1) ? 0x80 : NULL) + (chckSum >>1) + *tempShortNamePtr++;
	}
	return chckSum;
}

/**
Function responsible to initialize short entry attributes.
Short entry is also an sub entry along with Long entries

@internalComponent
@released

@param aEntry - directory entry which has long file name
@return shortEntry - returns the initialized short Directory entry
*/
CDirectory* ClongName::CreateShortEntry(CDirectory* aEntry)
{
	CDirectory* shortEntry = new CDirectory(iShortName.c_str(),NULL);
	shortEntry->SetEntryAttribute(aEntry->GetEntryAttribute()); 
	if(aEntry->IsFile())
	{	 
		shortEntry->SetFilePath((char*)aEntry->GetFilePath().c_str());
	}
	shortEntry->SetFileSize(aEntry->GetFileSize());
	/** Initialize the cluster number variables by splitting high and low words of
	current cluster number
	*/
	shortEntry->SetClusterNumberHi((unsigned short)(iClusterNumber >> KBitShift16));
	shortEntry->SetClusterNumberLow((unsigned short)(iClusterNumber & KHighWordMask));
	return shortEntry;
}

/**
Function responsible
1. To erase the string from the iNameList container.
2. To pop out the element

@internalComponent
@released
*/
void ClongName::PopAndErase()
{
	iSubNamesList.front().erase();
	iSubNamesList.pop_front();
}

/** 
Function responsible to 
1. Pop all the name's 3 by 3 from iNameList container
2. Construct long name directory entries
3. Push the long entries into iLongEntryStack 
4. finally create Long name sub entries as string and append it to longEntryString.

@internalComponent
@released

@return - returns the formatted long name string
*/
string ClongName::CreateLongEntries()
{
	string longEntryString;
	CLongEntry* longEntryObject;
	unsigned char chckSum = CalculateCheckSum();
	unsigned char dirOrderNumber = 0x00;
	while(iSubNamesList.size() > 0)
	{
		longEntryObject = new CLongEntry(chckSum);
		longEntryObject->SetSubName1(iSubNamesList.front());
		PopAndErase();
		longEntryObject->SetSubName2(iSubNamesList.front());
		PopAndErase();
		longEntryObject->SetSubName3(iSubNamesList.front());
		PopAndErase();
		longEntryObject->SetDirOrder(++dirOrderNumber);
	
		iLongEntryStack.push(longEntryObject);
	}

	bool lastLongEntry = true;
	while(iLongEntryStack.size() > 0)
	{
		if(lastLongEntry == true)
		{
			longEntryObject = iLongEntryStack.top();
			/* As per Microsoft FAT spec, Last sub entry of Long name Directory Order attribute
			 * should be logically OR'ed with value '0x40'
			 */
			longEntryObject->SetDirOrder(longEntryObject->GetDirOrder() | ELastLongEntry);
			lastLongEntry = false;
		}
		WriteLongEntry(iLongEntryStack.top(),longEntryString);
		delete iLongEntryStack.top();
		iLongEntryStack.pop();
	}
	return longEntryString;
}
