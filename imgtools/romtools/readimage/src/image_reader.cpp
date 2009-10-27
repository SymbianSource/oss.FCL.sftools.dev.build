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

ImageReader::ImageReader(const char* aFile) : iDisplayOptions(0),iImgFileName(aFile)
{
}

ImageReader::~ImageReader()
{
}

void ImageReader::SetDisplayOptions(TUint32 aFlag)
{
	iDisplayOptions |= aFlag;
}

bool ImageReader::DisplayOptions(TUint32 aFlag)
{
	return ((iDisplayOptions & aFlag) != 0);
}

void ImageReader::DumpData(TUint* aData, TUint aLength)
{
	TUint *p=aData;
	TUint i=0;
	char line[256];
	char *cp=(char*)aData;
	TUint j=0;
	memset(line,' ',sizeof(line));
	while (i<aLength)
		{
		TUint ccount=0;
		char* linep=&line[8*5+2];
		*out<< "0x";
		out->width(6);
		out->fill('0');
		*out << i << ":";
		while (i<aLength && ccount<4)
			{
			*out<< " ";
			out->width(8);
			out->fill('0');
			*out << *p++;
			i+=4;
			ccount++;
			for (j=0; j<4; j++)
				{
				char c=*cp++;
				if (c<32)
					{
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
void ImageReader::ExtractFile(TUint aOffset,TInt aSize,const char* aFileName,const char* aPath,char* aFilePath,char* aData)
{
	// concatenate path where specified file needs to be extracted with
	// path where file is located in the image.
	string fullPath( aFilePath );
	string delimiter( "\\" );
	string appStr( "\\\\" );
	fullPath.append( aPath );
	
	// replace all the occurrence of slash with double slash. 
	FindAndInsertString( fullPath, delimiter, delimiter );
	// now terminate the string with double slash.
	fullPath.append( appStr );

	// create specified directory where file needs to be extracted.
	CreateSpecifiedDir( &fullPath[0], appStr.c_str() );

	// concatenate path information with the filename
	fullPath.append( aFileName );

	// create an output stream to extract the specified file.
	ofstream outfile (fullPath.c_str(), ios::out | ios::binary);
	// create an input stream by opening the specified image file.
	ifstream infile(ImageReader::iImgFileName.c_str(),ios::in|ios::binary);

	//declare a buffer to store the data.
	char* buffer = new char[aSize];

	if(aData != NULL)
	{
		memcpy(buffer, aData + aOffset, aSize);
	}
	else if(infile.is_open())
	{
		// place the get pointer for the current input stream to offset bytes away from origin.
		infile.seekg(aOffset,ios::beg);
		//read number of bytes specified by the variable size 
		//from the stream and place it on to buffer.
		infile.read(buffer,aSize);
		//close the input stream after reading.
		infile.close();
	}
	else
	{
		throw ImageReaderException(ImageReader::iImgFileName.c_str(), "Failed to open the image file");
	}

	if(outfile.is_open())
	{
		//writes number of bytes specified by the variable size 
		//from buffer to the current output stream.
		outfile.write(buffer,aSize);
		//close the output stream after writing.
		outfile.close();
	}
	else
	{
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
@param aDelimiter - delimiter.
*/
void ImageReader::CreateSpecifiedDir(char* aSrcPath,const char* aDelimiter)
{
	char* currWorkingDir = new char[_MAX_BUFFER_SIZE_];
	string origPath;

	origPath.assign(aSrcPath);


	// get the current working directory and store in buffer.
	if( _getcwd(currWorkingDir,_MAX_BUFFER_SIZE_) == NULL )
	{
		// throw an exception if unable to get current working directory information.
		throw ImageReaderException((char*)ImageReader::iImgFileName.c_str(), "Failed to get the current working directory");
	}
	else
	{
		char* cPtr = strtok(aSrcPath,aDelimiter);

		// check whether cPtr is a drive or a directory.
		if(IsDrive(cPtr))
		{
			// if yes, then change the directory to cPtr.
			string changeToDrive ;
			changeToDrive.assign(cPtr);
			changeToDrive.append(aDelimiter);
			
			// change the current working directory to the specified directory.
			if( _chdir(changeToDrive.c_str()) )
			{
				// throw an exception if unable to change the directory specified.
				throw ImageReaderException((char*)ImageReader::iImgFileName.c_str(), "Failed to change to the directory specified");
			}
		}
		else
		{
			// if not,then create a cPtr directory. 
			_mkdir(cPtr);
			// change the current working directory to cPtr.
			_chdir(cPtr);
		}
		// repeat till cPtr is NULL.
		while (cPtr!=NULL)
		{
			if (cPtr = strtok(NULL,aDelimiter))
			{
				// create the directory.
				_mkdir(cPtr);
				// change current working directory.
				_chdir(cPtr);
			}
		}
		// revert back the working directory.
		_chdir(currWorkingDir);
		// replace the source path with the original path information.
		strcpy(aSrcPath,origPath.c_str());
		delete[] currWorkingDir;
	}
}


/** 
Function to check whether the given string is a drive or a folder.

@internalComponent
@released

@param aStr - string to be checked.
@return - returns True if the given string is a drive else returns false.
*/
TBool ImageReader::IsDrive(char* aStr)
{
	TInt strlength = strlen(aStr);
	//check for the last character in a given string,
	//if the last character is colon then return true else false.
	if(!strcmp(&aStr[strlength - 1],":"))
	{
		return true;
	}
	else
	{
		return false;
	}
}


/** 
Function to insert a given string with a delimiter.

@internalComponent
@released

@param aSrcStr - string to be modified.
@param aDelimiter - string to be checked.
@param aAppStr - string to be inserted with the delimiter.
*/
void ImageReader::FindAndInsertString(string& aSrcStr,string& aDelimiter,string& aAppStr)
{
	string::size_type loc = 0;
	string::size_type pos =0;
	while(( pos = aSrcStr.find( aDelimiter, loc ) ) != ( string::npos ) )
	{
		if( pos != string::npos )
		{
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
void ImageReader::FindAndReplaceString( string& aSrcStr, string& aDelimiter, string& aReplStr )
{
	string::size_type loc = 0;
	string::size_type pos =0;
	while(( pos = aSrcStr.find( aDelimiter,loc) ) != ( string::npos ) )
	{
		if( pos != string::npos )
		{
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
void ImageReader::ExtractFileSet(char* aData)
{
	FILEINFOMAP fileInfoMap;
	string dirSep(DIR_SEPARATOR), backSlash("\\"), Pattern;
	TUint extfileCount = 0, noWcardFlag = 0, pos;

	//Get the filelist map
	GetFileInfo(fileInfoMap);

	//Check for wildcards
	pos = iPattern.rfind("\\");
	if(pos == string::npos)
	{
		pos = iPattern.rfind("/");
		if(pos == string::npos)
			pos = 0;
	}
	pos = iPattern.find_first_of("*?", pos);
	if(pos == string::npos)
	{
		noWcardFlag = 1;
	}

	//Process the map
	if(fileInfoMap.size() > 0)
	{
		FILEINFOMAP::iterator begin = fileInfoMap.begin();
		FILEINFOMAP::iterator end = fileInfoMap.end();

		// Replace all backslashes with forward slashes
		Pattern = iPattern;
		FindAndReplaceString(Pattern, backSlash, dirSep);

		// Insert root directory at the beginning if it is not there
		pos = Pattern.find_first_not_of(" ", 0);
		if(pos != string::npos)
		{
			if(Pattern.at(pos) != *DIR_SEPARATOR)
				Pattern.insert(pos, dirSep);
		}

		// Assign CWD for destination path if it is empty
		if(ImageReader::iZdrivePath.empty())
			ImageReader::iZdrivePath.assign(".");

		while(begin != end)
		{
			int status = 0;
			PFILEINFO pInfo = 0;
			string fileName = (*begin).first;
			pInfo = (*begin).second;

			// First match
			status = FileNameMatch(Pattern, fileName, (iDisplayOptions & RECURSIVE_FLAG));

			// If no match
			if((!status) && noWcardFlag)
			{
				string newPattern(Pattern);

				// Add * at the end
				if(newPattern.at(Pattern.length()-1) != *DIR_SEPARATOR)
				{
					newPattern.append(DIR_SEPARATOR);
				}
				newPattern += "*";
				status = FileNameMatch(newPattern, fileName, (iDisplayOptions & RECURSIVE_FLAG));

				// If it matches update the pattern and reset wildcard flag
				if(status)
				{
					Pattern = newPattern;
					noWcardFlag = 0;
				}
			}

			if(status)
			{
				// Extract the file

				// Separarate the path and file name
				string fullPath = fileName.substr(0, fileName.rfind(DIR_SEPARATOR));
				string file = fileName.substr(fileName.rfind(DIR_SEPARATOR)+1, fileName.length());
				FindAndReplaceString(fullPath, dirSep, backSlash);

				// Extract only those files exists in the image
				if(pInfo->iSize && pInfo->iOffset)
				{
					ExtractFile(pInfo->iOffset, pInfo->iSize, file.c_str(), fullPath.c_str() , 
						&ImageReader::iZdrivePath[0], aData);

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
	if(!extfileCount)
	{
		throw ImageReaderException((char*)ImageReader::iImgFileName.c_str(), "No matching files found for the given pattern");
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
int ImageReader::FileNameMatch(string aPattern, string aFileName, int aRecursiveFlag)
{
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
	while ((*InputString) && (*Pattern != '*')) 
	{
		if ((toupper(*Pattern) != toupper(*InputString)) && (*Pattern != '?')) 
		{
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
	while (*InputString) 
	{
		if ((*Pattern == '*')) 
		{
			if (!*++Pattern) 
			{
				// If recursive flag is set then this case matches for any character of the input string
				// from the current position
				if(aRecursiveFlag)
					return 1;
			}

			// Update the current pattern and the current inputstring
			CurrPattern = Pattern;
			CurrString = InputString+1;			
		} 
		else if ((toupper(*Pattern) == toupper(*InputString)) || (*Pattern == '?')) 
		{
			// Exact match for the path separator
			// So recursively call the function to look for the exact path level match
			if(*Pattern == '/')
				return FileNameMatch(Pattern, InputString, aRecursiveFlag);

			// Exact match so increment both
			Pattern++;
			InputString++;
		} 
		else if ((*InputString == *DIR_SEPARATOR) && (!aRecursiveFlag))
		{
			// Inputstring points to path separator and it is not expected here for non-recursive case
			return 0;
		}
		else
		{
			// Default case where it matches for the wildcard character *
			Pattern = CurrPattern;
			InputString = CurrString++;
		}
	}
	
	// Leave any more stars in the pattern
	while (*Pattern == '*') 
	{
		Pattern++;
	}
	
	// Return the status
	return !*Pattern;
}
