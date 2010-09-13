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
* @internalComponent * @released
* Driveimage general utilities.
*
*/


#include <string.h>
#include <stdlib.h>
#include <time.h>

#include <e32err.h>
#include "h_utl.h"
#include "r_driveutl.h"

/**
Derive log file name from the given driveobey file name(it could be absolute path)
        and update with .log extn.
Checks the validity of driveobey file name before creating the log file name.

@param adriveobeyFileName - Drive obey file.
@param &apadlogfile       - Reference to log file name.
  
@return - returns 'ErrorNone' if log file created, otherwise returns Error.
*/ 
TInt Getlogfile(char *aDriveObeyFileName,char* &aPadLogFile)
	{

	if(!(*aDriveObeyFileName))
		return KErrGeneral;

	// Validate the user entered driveoby file name.
	char* logFile = (char*)aDriveObeyFileName;

	TInt len = strlen(logFile);
	if(!len)
		return KErrGeneral;

	// Allocates the memory for log file name.
	aPadLogFile = new char[(len)+5]; 
	if(!aPadLogFile)
		return KErrNoMemory;

	// Create the log file name.
	strcpy((char*)aPadLogFile,logFile);
	strcat((char*)aPadLogFile,".LOG");
				
	return  KErrNone;
	}

/**
Time Stamp for Log file.
*/ 
TAny GetLocalTime(TAny)
	{
	struct tm *aNewTime = NULL;
	time_t aTime = 0;

	time(&aTime);
	aNewTime = localtime(&aTime);

	/* Print the local time as a string */
	if(aNewTime)
		Print(ELog,"%s\n", asctime(aNewTime));
	else
		Print(ELog,"Error : Getting Local Time\n");
	}
