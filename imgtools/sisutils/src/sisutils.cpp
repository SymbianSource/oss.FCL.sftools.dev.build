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
*
*/


#ifdef WIN32
#include <windows.h>
#include <direct.h>
#endif

#include "sisutils.h"

/**
Constructor: SisUtilsException class
Initilize the parameters to data members.

@internalComponent
@released

@param aFile	- Name of the file
@param aErrMessage - Error message
*/
SisUtilsException::SisUtilsException(char* aFile, char* aErrMessage) : \
	iSisFileName(aFile), iErrMessage(aErrMessage)
{
}

/**
Destructor: SisUtilsException class
Deallocates the memory for data members

@internalComponent
@released
*/
SisUtilsException::~SisUtilsException()
{
}

/**
Report: Reports error message on the console

@internalComponent
@released
*/
void SisUtilsException::Report()
{
	std::cout << "Error : ";
	std::cout << iSisFileName.c_str() << " : ";
	std::cout << iErrMessage.c_str();
	std::cout << std::endl;
}

/**
Constructor: SisUtils class
Initilize the parameters to data members.

@internalComponent
@released

@param aFile	- Name of the SIS file
*/
SisUtils::SisUtils(char* aFile) :  iVerboseMode(EFalse),iSisFile(aFile)
{
}

/**
Destructor: SisUtils class
Deallocates the memory for data members

@internalComponent
@released
*/
SisUtils::~SisUtils()
{
}

/**
SetVerboseMode: Sets the verbose mode

@internalComponent
@released
*/
void SisUtils::SetVerboseMode()
{
	iVerboseMode = ETrue;
}

/**
SisFileName: Returns the SIS file name

@internalComponent
@released
*/
String SisUtils::SisFileName()
{
	return iSisFile;
}

/**
IsVerboseMode: Returns the status of the verbose mode

@internalComponent
@released
*/
TBool SisUtils::IsVerboseMode()
{
	return iVerboseMode;
}

/**
IsFileExist: Tests whether the give file exists or not

@internalComponent
@released

@param aFile - Name of the file
*/
TBool SisUtils::IsFileExist(String aFile)
{
	std::ifstream aIfs;

	TrimQuotes(aFile);

	aIfs.open((char*)aFile.data(), std::ios::in);

	if( aIfs.fail() )
	{
		aIfs.close();
		return EFalse;
	}

	aIfs.close();

	return ETrue;
}

/**
RunCommand: Runs the given command

@internalComponent
@released

@param cmd - Command line as string
*/
TUint32 SisUtils::RunCommand(String cmd)
{
	TUint32 iExitCode = STAT_SUCCESS;

#ifdef WIN32
    STARTUPINFO si;
    PROCESS_INFORMATION pi;
	DWORD dwWaitResult;

    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);
    memset(&pi, 0, sizeof(pi));

    if( !::CreateProcess( NULL,   // No module name (use command line)
        (char*)cmd.data(),        // Command line
        NULL,           // Process handle not inheritable
        NULL,           // Thread handle not inheritable
        FALSE,          // Set handle inheritance to FALSE
        DETACHED_PROCESS | CREATE_NO_WINDOW,              // process creation flags
        NULL,           // Use parent's environment block
        NULL,           // Use parent's starting directory 
        &si,            // Pointer to STARTUPINFO structure
        &pi )           // Pointer to PROCESS_INFORMATION structure
    ) 
    {
		return static_cast<TUint32>(STAT_FAILURE);
    }

	dwWaitResult = ::WaitForSingleObject( pi.hProcess, INFINITE );

	if(dwWaitResult == WAIT_OBJECT_0)
	{
		::GetExitCodeProcess(pi.hProcess, &iExitCode);
		if(iExitCode != STAT_SUCCESS)
		{
			iExitCode = static_cast<TUint32>(STAT_FAILURE);
		}
	}
	else
	{
		iExitCode = static_cast<TUint32>(STAT_FAILURE);
	}

	::CloseHandle( pi.hProcess );
	::CloseHandle( pi.hThread );
#else
#error "TODO: Implement this function under other OS than Windows"
#endif

	return iExitCode;
}

/**
TrimQuotes: Remove the quotes in the given file name

@internalComponent
@released

@param aStr - File name
*/
void SisUtils::TrimQuotes(String& aStr)
{
	TUint spos = 0, epos = 0;

	spos = aStr.find("\"");
	if(spos == String::npos)
		return;

	epos = aStr.rfind("\"");

	if(spos == epos)
	{
		epos = aStr.size();
		aStr = aStr.substr(spos+1,epos);
	}
	else
	{
		aStr = aStr.substr(spos+1,epos-1);

		spos = aStr.find("\"");
		while( spos != String::npos )
		{
			aStr.erase(spos,1);
			spos = aStr.find("\"");
		}
	}

	return;
}

/**
MakeDirectory: Creates directory if it is not exist

@internalComponent
@released

@param aPath - Directory name to be created
*/
TBool SisUtils::MakeDirectory(String aPath)
{
	TBool status = ETrue;
	TUint currpos = 0;
	String dir;

	do
	{
		currpos = aPath.find_first_of(PATHSEPARATOR, currpos);
		if(currpos == String::npos)
		{
			dir = aPath.substr(0, aPath.length());
		}
		else
		{
			dir = aPath.substr(0, currpos);
			currpos++;
		}

#ifdef WIN32
		if(mkdir((char*)dir.data()) != 0)
		{
			if(errno != EEXIST)
			{
				status = EFalse;
			}
		}
#else
#error "TODO: Implement this function under other OS than Windows"
#endif
		if(status == EFalse)
			break;
	} while(currpos != String::npos);

	return status;
}
