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


#include "image_reader.h"
#include <stdio.h>
#include <stdlib.h>
#include <boost/filesystem.hpp>
 
using namespace boost::filesystem;
ImageReader::ImageReader(const char* aFile) : iDisplayOptions(0),iImgFileName(aFile) {
}

ImageReader::~ImageReader() {
}

void ImageReader::SetDisplayOptions(TUint32 aFlag) {
	iDisplayOptions |= aFlag;
}

bool ImageReader::DisplayOptions(TUint32 aFlag) {
	return ((iDisplayOptions & aFlag) != 0);
}

void ImageReader::DumpData(TUint* aData, TUint aLength) {
	TUint *p=aData;
	TUint i=0;
	char line[256];
	char *cp=(char*)aData;
	TUint j=0;
	memset(line,' ',sizeof(line));
	while (i<aLength) {
		TUint ccount=0;
		char* linep=&line[8*5+2];
		*out<< "0x";
		out->width(6);
		out->fill('0');
		*out << i << ":";
		while (i<aLength && ccount<4) {
			*out<< " ";
			out->width(8);
			out->fill('0');
			*out << *p++;
			i+=4;
			ccount++;
			for (j=0; j<4; j++) {
				char c=*cp++;
				if (c<32) {
					c = '.';
					}
				*linep++ = c;
				}
			}
		*linep = '\0';
		*out << line+(ccount*5) << endl;
		}
	}



/** 
Function to extract specified file from a given image. 

@internalComponent
@released
 
@param aOffset - starting offset of the file in the image.
@param aSize - size of the file in the image.
@param aFileName - name of the file.
@param aPath - full path of the file inside image.
@param aFilePath - path where file has to be extracted.
*/
void ImageReader::ExtractFile(TUint aOffset,TInt aSize,const char* aFileName,const char* aPath,const char* aFilePath,const char* aData) {
	// concatenate path where specified file needs to be extracted with
	// path where file is located in the image.
	string fullPath( aFilePath );
	if(*aPath != SLASH_CHAR1 && *aPath != SLASH_CHAR2){
		char ch = aFilePath[fullPath.length() - 1];
		if(ch != SLASH_CHAR1 && ch != SLASH_CHAR2)
			fullPath += SLASH_CHAR1 ;		
	}
	int startImagePath = (int)fullPath.length();
	fullPath += aPath ;	 
	
	// create specified directory where file needs to be extracted. 
	// to lower
	char* data = const_cast<char*>(fullPath.data() + startImagePath);
	for(; *data != 0 ; data++){
		if(*data >= 'A' && *data <= 'Z'){
			*data |= 0x20 ;
		}
	}
	CreateSpecifiedDir(fullPath);

	data -- ;
	if(*data != SLASH_CHAR1)
		fullPath += SLASH_CHAR1 ; 
	
	// concatenate path information with the filename	
	fullPath +=  aFileName ;

	// create an output stream to extract the specified file.  
	ofstream outfile (fullPath.c_str(), ios_base::out | ios_base::binary);
	// create an input stream by opening the specified image file.
	ifstream infile(ImageReader::iImgFileName.c_str(),ios_base::in|ios_base::binary);

	//declare a buffer to store the data.
	char* buffer = new char[aSize];

	if(aData != NULL){
		memcpy(buffer, aData + aOffset, aSize);
	}
	else if(infile.is_open()) {
		// place the get pointer for the current input stream to offset bytes away from origin.
		infile.seekg(aOffset,ios_base::beg);
		//read number of bytes specified by the variable size 
		//from the stream and place it on to buffer.
		infile.read(buffer,aSize);
		//close the input stream after reading.
		infile.close();
	}
	else 	{
		throw ImageReaderException(ImageReader::iImgFileName.c_str(), "Failed to open the image file");
	}

	if(outfile.is_open()) {
		//writes number of bytes specified by the variable size 
		//from buffer to the current output stream.
		outfile.write(buffer,aSize);
		//close the output stream after writing.
		outfile.close();
	}
	else {
		throw ImageReaderException(aFileName, "Failed to extract the file");
	}

	//delete the buffer.
	delete[] buffer;
}
 
/** 
Function to create a given directory. 

@internalComponent
@released

@param aSrcPath - path of the directory that needs to be created. 
*/
void ImageReader::CreateSpecifiedDir(const string& aSrcPath) {	 
	 char* currWorkingDir = new char[PATH_MAX];
	int len = aSrcPath.length() ;
	const char* origPath = aSrcPath.c_str();	 
	char* path = new char[len + 2]; 

	memcpy(path,origPath,len);
	if(path[len - 1] != SLASH_CHAR1 && path[len - 1] != SLASH_CHAR2){
		path[len] = SLASH_CHAR1 ;
		len ++ ;
	}
	path[len] = 0; 
	char* start = path;
	char* end  = path + len ;
	char errMsg[400]  ;
	*errMsg = 0;
	char* dirEnd ;
	
	// get the current working directory and store in buffer.
	if( getcwd(currWorkingDir,PATH_MAX) == NULL ) {		 
		// throw an exception if unable to get current working directory information.
		snprintf(errMsg,400,"Failed to get the current working directory") ;
		goto L_EXIT;
	}
#ifdef WIN32
//check dir 
	if(isalpha(start[0]) && start[1] == ':'){
		char ch = start[3] ;
		start[3] = 0;
		if(chdir(start)) {
			snprintf(errMsg, 400 ,"Failed to change to the directory \"%s\".",path);
			goto L_EXIT;
		}
		start[3] = ch ;
		start += 3 ;		 
	}
	else if(*start == SLASH_CHAR1 || *start == SLASH_CHAR2){
		if(chdir("\\")){
			snprintf(errMsg, 400 ,"Failed to change to the directory \"\\\".");
			goto L_EXIT;
		}
		start ++ ;
	}
#else
	if(*start == SLASH_CHAR1 || *start == SLASH_CHAR2){
		if(chdir("/")) {
			snprintf(errMsg, 400 ,"Failed to change to the directory \"/\".");
			goto L_EXIT;
		}
		start ++ ;
	}	
#endif
	dirEnd = start ;

	while( start < end ) {		
		while(*dirEnd != SLASH_CHAR1 && *dirEnd != SLASH_CHAR2)
			dirEnd ++ ;
		*dirEnd =  0 ;
		
		if(!exists(start)) {  
			MKDIR(start);
		}   
		if(chdir(start)){
			snprintf(errMsg, 400 ,"Failed to change to the directory \"%s\".",path);
			goto L_EXIT;
		}
		*dirEnd = SLASH_CHAR1;
		start = dirEnd + 1;
		dirEnd = start ;		 
	} 
L_EXIT:
	chdir(currWorkingDir);
	delete[] currWorkingDir;
	delete [] path;
	if(*errMsg)
	 throw ImageReaderException(ImageReader::iImgFileName.c_str(), errMsg); 
}

 
 


/** 
Function to insert a given string with a delimiter.

@internalComponent
@released

@param aSrcStr - string to be modified.
@param aDelimiter - string to be checked.
@param aAppStr - string to be inserted with the delimiter.
*/
void ImageReader::FindAndInsertString(string& aSrcStr,string& aDelimiter,string& aAppStr) {
	string::size_type loc = 0;
	string::size_type pos =0;
	while(( pos = aSrcStr.find( aDelimiter, loc ) ) != ( string::npos ) ) {
		if( pos != string::npos ) {
			aSrcStr.insert(pos,aAppStr);
			loc = pos + aAppStr.length() + 1;
		}
	}
}

/** 
Function to replace a delimiter with a given string.

@internalComponent
@released

@param aSrcStr - string to be modified.
@param aDelimiter - string to be checked.
@param aReplStr - string to be replaced with the delimiter.
*/
void ImageReader::FindAndReplaceString( string& aSrcStr, string& aDelimiter, string& aReplStr ) {
	string::size_type loc = 0;
	string::size_type pos =0;
	while(( pos = aSrcStr.find( aDelimiter,loc) ) != ( string::npos ) ) {
		if( pos != string::npos ) {
			aSrcStr.replace( pos, aReplStr.length(),aReplStr );
			loc = pos + aReplStr.length() + 1;
		}
	}
}

/** 
Function to extract individual or a subset of file.

@internalComponent
@released

@param aData - ROM/ROFS image buffer pointer.
*/
void ImageReader::ExtractFileSet(const char* aData) {
	FILEINFOMAP fileInfoMap; 
	TUint extfileCount = 0, noWcardFlag = 0 ;

	//Get the filelist map
	GetFileInfo(fileInfoMap);

	//Check for wildcards
	const char* patternStr = iPattern.c_str();
	TInt dp = iPattern.length() - 1;
	while(dp >= 0){
		if(patternStr[dp] == SLASH_CHAR1 || patternStr[dp] == SLASH_CHAR2)
			break ;
		dp -- ;
	} 
	size_t pos = iPattern.find_first_of("*?",dp + 1);
	if(pos == string::npos) 
		noWcardFlag = 1; 

	//Process the map
	if(fileInfoMap.size() > 0) {
		FILEINFOMAP::iterator begin = fileInfoMap.begin();
		FILEINFOMAP::iterator end = fileInfoMap.end();

		// Replace all backslashes with forward slashes
		string pat(iPattern);
		for(size_t n = 0 ; n < iPattern.length(); n++){
			if(patternStr[n] == SLASH_CHAR2)
				pat[n] = SLASH_CHAR1 ;
		}
	 
		// Insert root directory at the beginning if it is not there
		pos = pat.find_first_not_of(" ", 0);
		if(pos != string::npos) {
			if(pat.at(pos) != SLASH_CHAR1)
				pat.insert(pos, 1,SLASH_CHAR1);
		}

		// Assign CWD for destination path if it is empty
		if(ImageReader::iZdrivePath.empty())
			ImageReader::iZdrivePath.assign(".");

		while(begin != end) {
		 
			string fileName((*begin).first);
			PFILEINFO pInfo = (*begin).second;

			// First match
			int status = FileNameMatch(pat, fileName, (iDisplayOptions & RECURSIVE_FLAG));

			// If no match
			if((!status) && noWcardFlag) {
				string newPattern(pat);

				// Add * at the end
				if(newPattern.at(pat.length()-1) != SLASH_CHAR1) {
					newPattern += SLASH_CHAR1;
				}
				newPattern += "*";
				status = FileNameMatch(newPattern, fileName, (iDisplayOptions & RECURSIVE_FLAG));

				// If it matches update the pattern and reset wildcard flag
				if(status) {
					pat = newPattern;
					noWcardFlag = 0;
				}
			}

			if(status) {
				// Extract the file

				// Separarate the path and file name
				int slash_pos = fileName.rfind(SLASH_CHAR1);
				string fullPath = fileName.substr(0,slash_pos );
				string file = fileName.substr(slash_pos + 1, fileName.length());
				//FindAndReplaceString(fullPath, dirSep, backSlash);
				char* fpStr = const_cast<char*>(fullPath.c_str());
				for(size_t m = 0 ; m < fullPath.length() ; m++){
					if(fpStr[m] == SLASH_CHAR2)
						fpStr[m] = SLASH_CHAR1 ;
				}

				// Extract only those files exists in the image
				if(pInfo->iSize && pInfo->iOffset) {
					ExtractFile(pInfo->iOffset, pInfo->iSize, file.c_str(), fullPath.c_str() , 
						ImageReader::iZdrivePath.c_str(), aData);

					extfileCount++;
				}
			}

			if(pInfo)
				delete pInfo;
			++begin;
		}
		fileInfoMap.clear();
	}

	// Throw error if the extracted file count is zero
	if(!extfileCount) {
		throw ImageReaderException(ImageReader::iImgFileName.c_str(), "No matching files found for the given pattern");
	}
}

/** 
To match the given file name aganist the given pattern with wildcards

@internalComponent
@released

@param aPattern - input filename pattern.
@param aFileName - input file name.
@param aRecursiveFlag - recursive search flag.
*/
int ImageReader::FileNameMatch(const string& aPattern, const string&  aFileName, int aRecursiveFlag) {
	const char *InputString = aFileName.c_str();
	const char *Pattern = aPattern.c_str();
	const char *CurrPattern = 0, *CurrString = 0;
	
	// If the input is empty then return false
	if((aPattern.empty()) || (!InputString))
		return 0;

	// First candidate match
	// Step 1: Look for the exact matches between the input pattern and the given file-name till 
	//         the first occurrence of wildcard character (*). This should also skip a character 
	//         from matching for the occurrence of wildcard character(?) in the pattern.
	while ((*InputString) && (*Pattern != '*'))  {
		if ((toupper(*Pattern) != toupper(*InputString)) && (*Pattern != '?'))  {
			return 0;
		}
		Pattern++;
		InputString++;
	}
	
	// Wildcard match
	// Step 2: Now the input string (file-name) should be checked against the wildcard characters (* and ?). 
	//         Skip the input string if the pattern points to wildcard character(*). Do the exact match for 
	//         other characters in the patterns except the wildcard character(?). The path-separator should be 
	//         considered as non-match for non-recursive option.
	while (*InputString) {
		if ((*Pattern == '*')) {
			if (!*++Pattern) {
				// If recursive flag is set then this case matches for any character of the input string
				// from the current position
				if(aRecursiveFlag)
					return 1;
			}

			// Update the current pattern and the current inputstring
			CurrPattern = Pattern;
			CurrString = InputString+1;			
		} 
		else if ((toupper(*Pattern) == toupper(*InputString)) || (*Pattern == '?')) {
			// Exact match for the path separator
			// So recursively call the function to look for the exact path level match
			if(*Pattern == SLASH_CHAR1)
				return FileNameMatch(Pattern, InputString, aRecursiveFlag);

			// Exact match so increment both
			Pattern++;
			InputString++;
		} 
		else if ((*InputString == SLASH_CHAR1) && (!aRecursiveFlag)) {
			// Inputstring points to path separator and it is not expected here for non-recursive case
			return 0;
		}
		else {
			// Default case where it matches for the wildcard character *
			Pattern = CurrPattern;
			InputString = CurrString++;
		}
	}
	
	// Leave any more stars in the pattern
	while (*Pattern == '*')  
		Pattern++; 
	
	// Return the status
	return !*Pattern;
}
