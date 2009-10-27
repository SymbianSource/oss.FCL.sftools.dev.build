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
* @internalComponent
* @released
*
*/

#include "patchdataprocessor.h"

/**
Add patchdata statement to the vector containing all patchdata statements

@param aPatchDataStatement new patchdata statement.

@internalComponent
@released
*/
void CPatchDataProcessor::AddPatchDataStatement(StringVector aPatchDataStatement)
{
	iPatchDataStatements.push_back(aPatchDataStatement);
}

/**
Get the vector containing patchdata statements 

@return iPatchDataStatements list of patchdata statements.

@internalComponent
@released
*/
VectorOfStringVector CPatchDataProcessor::GetPatchDataStatements(void) const
{
	return iPatchDataStatements;
}

/**
Add a new entry to renamed file map.

@param aCurrentName current name of the file.
@param aNewName new name of the file.

@internalComponent
@released
*/
void CPatchDataProcessor::AddToRenamedFileMap(String aCurrentName, String aNewName)
{
	iRenamedFileMap[aCurrentName]=aNewName;
}

/**
Get renamed file map.

@return iRenamedFileMap renamed file map

@internalComponent
@released
*/
MapOfString CPatchDataProcessor::GetRenamedFileMap() const
{
	return iRenamedFileMap;
}

/**
Add link to the patchdata linked list

@param aDllData pointer to a patchdata link.

@internalComponent
@released
*/
void DllDataEntry::AddDllDataEntry(DllDataEntry *aDllData)
{
	iNextDllEntry=aDllData;	
}

/**
Get the next node in the patchdata linked list

@return  pointer to the next node.

@internalComponent
@released
*/
DllDataEntry*	DllDataEntry::NextDllDataEntry() const
{
	if (iNextDllEntry)
	{
		return iNextDllEntry;
	}
	else
	{
		return NULL;
	}
}
