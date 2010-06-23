/*
* Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Class for Patching Exported Data 
* @internalComponents
* @released
*
*/


#ifndef PATCHDATAPROCESSOR_H
#define PATCHDATAPROCESSOR_H

#include <e32def.h>
#include <string> 
#include <iostream>
#include <vector>
#include <map>
#include <sstream>


using namespace std;
typedef vector<string> StringVector;
typedef vector<StringVector> VectorOfStringVector;
typedef map<string,string> MapOfString;
typedef map<string,string>::iterator MapOfStringIterator; 

/**
Class for patching exported data.

@internalComponent
@released
*/
class CPatchDataProcessor
{
	VectorOfStringVector iPatchDataStatements; // Vector of string containing patchdata statements.
	MapOfString iRenamedFileMap; // Map containing information of renamed files. 

public:	
	void AddPatchDataStatement(StringVector aPatchDataStatement);
	void AddToRenamedFileMap(string aCurrentName, string aNewName);
	VectorOfStringVector GetPatchDataStatements() const;
	MapOfString GetRenamedFileMap() const;		
};


class TRomNode;

/**
Class to form a patchdata linked-list contatining symbol size, address/ordinal 
new value to be patched.

@internalComponent
@released
*/
class DllDataEntry
{
	
public:
	DllDataEntry(TUint32 aSize, TUint32 aNewValue) :
				 iSize(aSize), iDataAddress((TUint32)-1), iOrdinal((TUint32)-1), iOffset(0),
				 iNewValue(aNewValue), iRomNode(NULL), iNextDllEntry(NULL)
	{
	}


	TUint32			iSize;
	TLinAddr		iDataAddress;
	TUint32			iOrdinal;
	TUint32			iOffset;
	TUint32			iNewValue;
	TRomNode*		iRomNode;
	DllDataEntry*	iNextDllEntry;
 
 	void			AddDllDataEntry(DllDataEntry*);
	DllDataEntry*	NextDllDataEntry() const;
};

#endif //PATCHDATAPROCESSOR_H
