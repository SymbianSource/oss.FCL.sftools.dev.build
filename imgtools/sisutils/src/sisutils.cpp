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
#ifdef _STLP_INTERNAL_WINDOWS_H
#define __INTERLOCKED_DECLARED
#endif
#include <windows.h>
#include <direct.h>
#define MKDIR mkdir
#else
#include <unistd.h>
#include <sys/wait.h>

#include <sys/stat.h>
#include <sys/types.h>
#define MKDIR(a) mkdir(a,0777)
#endif

#include "sisutils.h"
#include <errno.h>


/**
Constructor: SisUtilsException class
Initilize the parameters to data members.

@internalComponent
@released

@param aFile	- Name of the file
@param aErrMessage - Error message
*/
SisUtilsException::SisUtilsException(const char* aFile, const char* aErrMessage) : \
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
	cout << "Error : " << iSisFileName.c_str() << " : " << iErrMessage.c_str() << endl;
}

/**
Constructor: SisUtils class
Initilize the parameters to data members.

@internalComponent
@released

@param aFile	- Name of the SIS file
*/
SisUtils::SisUtils(const char* aFile) :  iVerboseMode(EFalse),iSisFile(aFile)
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
const char* SisUtils::SisFileName()
{
	return iSisFile.c_str();
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
TBool SisUtils::IsFileExist(string aFile)
{
	ifstream file;
	TrimQuotes(aFile);
	file.open(aFile.c_str(), ios_base::in);
	TBool retVal = EFalse ;
	if(file.is_open()){
		file.close();
		retVal = ETrue ;
	}
	return retVal;
}

/**
RunCommand: Runs the given command

@internalComponent
@released

@param cmd - Command line as string
*/
TUint32 SisUtils::RunCommand(const char* aCmd) {
	TUint32 iExitCode = STAT_SUCCESS;

#ifdef WIN32
	STARTUPINFO si ; 
	PROCESS_INFORMATION pi ; 
	memset(&si,0,sizeof(STARTUPINFO));
	si.cb = sizeof(STARTUPINFO);
	memset(&pi,0,sizeof(PROCESS_INFORMATION));

    if( !::CreateProcess( NULL,   // No module name (use command line)
        const_cast<char*>(aCmd),        // Command line
        NULL,           // Process handle not inheritable
        NULL,           // Thread handle not inheritable
        FALSE,          // Set handle inheritance to FALSE
        DETACHED_PROCESS | CREATE_NO_WINDOW,              // process creation flags
        NULL,           // Use parent's environment block
        NULL,           // Use parent's starting directory 
        &si,            // Pointer to STARTUPINFO structure
        &pi ))           // Pointer to PROCESS_INFORMATION structure     
		return static_cast<TUint32>(STAT_FAILURE);
    

	TUint32 dwWaitResult = ::WaitForSingleObject( pi.hProcess, INFINITE );
	if(dwWaitResult == WAIT_OBJECT_0) {
		::GetExitCodeProcess(pi.hProcess, &iExitCode);
		if(iExitCode != STAT_SUCCESS){
			iExitCode = static_cast<TUint32>(STAT_FAILURE);
		}
	}
	else {
		iExitCode = static_cast<TUint32>(STAT_FAILURE);
	}

	::CloseHandle( pi.hProcess );
	::CloseHandle( pi.hThread );
#else

	TInt child_pid  = fork();
	if( -1 == child_pid)
		return (TUint32)STAT_FAILURE;
	if(0 == child_pid){
		if(-1 == execl(aCmd,"",NULL))
			return (TUint32)STAT_FAILURE;
	}
	else{
		TInt status = 0 ;
		iExitCode = (TUint32)STAT_FAILURE;
        while(wait(&status) != child_pid);
        iExitCode  = WEXITSTATUS(status)  ;
	}
	
#endif

	return iExitCode;
}

/**
TrimQuotes: Remove the quotes in the given file name

@internalComponent
@released

@param aStr - File name
*/
void SisUtils::TrimQuotes(string& aStr) {

	TUint spos  = aStr.find("\"");
	if(spos == string::npos)
		return;

	TUint epos = aStr.rfind("\"");

	if(spos == epos) {
		epos = aStr.size();
		aStr = aStr.substr(spos+1,epos);
	}
	else {
		aStr = aStr.substr(spos+1,epos-1);
		spos = aStr.find("\"");
		while( spos != string::npos )
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
TBool SisUtils::MakeDirectory(const string& aPath) {
	TBool status = ETrue;
	TUint currpos = 0;
	string dir;

	do 	{
		currpos = aPath.find_first_of(PATHSEPARATOR, currpos);
		if(currpos == string::npos) {
			dir = aPath.substr(0, aPath.length());
		} else {
			dir = aPath.substr(0, currpos);
			currpos++;
		}
 
		if(MKDIR(dir.c_str()) != 0){
			if(errno != EEXIST)	{
				status = EFalse;
			}
		} 
		if(status == EFalse)
			break;
	} while(currpos != string::npos);

	return status;
}
#ifndef WIN32
/*static inline wchar_t to_lowerW(wchar_t aChar){
	return (aChar >= L'A' && aChar <= L'Z') ? (aChar | 0x20) : aChar ; 
}
int wcsnicmp(const wchar_t* str1,const wchar_t* str2,size_t n){
	wchar_t a , b ;
	size_t i = 0 ;
	while(*str1 && *str2){
		a = to_lowerW(*str1) ;
		b = to_lowerW(*str2) ; 
		if(a > b )
			return 1 ;
		else if(a < b)
			return -1 ;
		if(++i >= n) break ;
		str1++ ;
		str2++ ;		
	}
	return 0;
}
int wcsicmp(const wchar_t* str1,const wchar_t* str2){
	wchar_t a , b ;
	while(*str1 && *str2){
		a = to_lowerW(*str1) ;
		b = to_lowerW(*str2) ; 
		if(a > b )
			return 1 ;
		else if(a < b)
			return -1 ;
		str1++ ;
		str2++ ;
	}
	if(0 == *str1 && 0 == *str2){
		return 0 ;
	}
	else if(*str1)
		return 1;
	else
		return -1;
}
int iswdigit(wchar_t ch){
	if(ch >= L'0' && ch <= L'9') return 1 ;
	return 0;
}*/
char *_fullpath(char* absPath, const char*relPath, size_t maxLength){
	if(*relPath == '/'){
		return strncpy(absPath,relPath,maxLength);
	}
	*absPath = 0 ;
	getcwd(absPath,maxLength);
	size_t len = strlen(absPath);
	//absPath[len++] = '/';
	int upward = 0 ;
	int status = 0 ;
	const char* savedPath = relPath ;
	while(*relPath){
		if(*relPath == '.'){
			status ++ ;
		}
		else if(*relPath == '/'){
			if(status == 2){
				upward ++ ;
			}
			else if(status != 1)
				break ;
			status = 0 ;
			savedPath = relPath + 1;
		}
		else {
			break ;
		}
		relPath ++ ;
			
	}
	if(0 == *relPath){ // like ".." or "." 
		if(2 == status) 
			upward ++ ;			 
	}
	else {
		relPath = savedPath ;
	}
	char* pathEnd = &absPath[len];	
	while(upward > 0){ // we have "../" in the beginning of relPath
		pathEnd -- ;
		if(pathEnd <= absPath)	return NULL ;
		while(pathEnd > absPath){
			pathEnd -- ;
			if(*pathEnd == '/')
				break ;
		}
		upward -- ;
	}
	if(0 != *relPath){
		*pathEnd = '/' ;
		char* conjBegin = pathEnd + 1;
		size_t bufLen = maxLength - (conjBegin - absPath);	
		strncpy(conjBegin,relPath,bufLen);
	}else {
		*pathEnd = 0 ;
	}
		
	return absPath ;
	 
}
#endif
