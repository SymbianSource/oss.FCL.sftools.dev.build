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
* Long entry class for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef LONGENTRY_H
#define LONGENTRY_H

/**
This class is used to represents the single Long entry attributes.
The long entry can be directory/file/volume entry.
Also declares the functions to operate on them.

@internalComponent
@released
*/
#include "messagehandler.h"
#include "directory.h"
#include "constants.h"

class CLongEntry
{
public:
	char GetDirOrder() const;
	void SetDirOrder(char aDirOrder);
	String& GetSubName1();
	void SetSubName1(String aSubName1);
	String& GetSubName2();
	void SetSubName2(String aSubName2);
	String& GetSubName3();
	void SetSubName3(String aSubName3);
	char GetAttribute() const;
	char GetCheckSum() const;
	char GetDirType() const;
	unsigned short int GetClusterNumberLow() const;

private:
	char iDirOrder;		//Order of this entry in the sequence of long directory entries
	String iSubName1;	//character 1-5 of long name sub component
	char iAttribute;	//LONG_FILE_NAME attribute
	char iDirType;		//zero to mention subcomponent of directory entry
	char iCheckSum;		//Check sum of Short directory entry name
	String iSubName2;	//character 6-11 of long name sub component
	/* Low of cluster number, must be zero for existing disk utility compatible 
	 * reason
	 */
	unsigned short int iFirstClusterNumberLow;
	String iSubName3;	//character 12-13 of long name sub component

public:
	CLongEntry(char aChckSum);
	~CLongEntry();
};

#endif //LONGENTRY_H
