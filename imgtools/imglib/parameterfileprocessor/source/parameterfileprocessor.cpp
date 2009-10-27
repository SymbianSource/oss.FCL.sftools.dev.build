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
* Class for processing parameter-file.
* @internalComponent
* @released
*
*/



#include "parameterfileprocessor.h"


/**
Constructor of CParameterFileProcessor class

@param aParamFileName parameter-file name

@internalComponent
@released
*/
CParameterFileProcessor::CParameterFileProcessor(String aParamFileName):
												 iParamFileName(aParamFileName),iNoOfArguments(0),
												 iParamFileArgs(NULL)
{
}	


/**
Function to open parameter-file

@internalComponent
@released

@return True/False depending on the status of parameter-file open statement.
*/
bool CParameterFileProcessor::OpenFile()
{
	
	iParamFile.open(iParamFileName.data(),std::ios::binary);
	if (iParamFile.is_open())
		return true;
	else
	{		
		std::cout<<"Error: Couldn't open parameter-file for reading:"<<iParamFileName.c_str()<<"\n";
		return false;
	}
}


/**
Function to parse the parameter-file

@internalComponent
@released

@return True/False depending on the status of parameter-file parsing.
*/
bool CParameterFileProcessor::ParameterFileProcessor()
{
	if(OpenFile())
	{
		while(!iParamFile.eof())
		{
			// Read the parameter-file line by line.
			String line;
			std::getline(iParamFile,line);

			// Read the line till the occurence of character ';' or EOL.
			unsigned int pos = line.find_first_of(";\r\n");
			if (pos != std::string::npos)
				line = line.substr(0,pos);
			
			// Split the line if multiple parameters are provided
			// in a single line.
			if(!SplitLine(line))
				return false;
		}		
		
		if (SetNoOfArguments() == false)
		{
			return false;
		}
		
		SetParameters();
		
		// Close parameter-file 
		CloseFile();

		return true;		
	}
	else
		return false;				
}


/**
Function to split line of paramfile-file 

@param aLine parameter-file line

@internalComponent
@released

@return True/False depending on the status of spliting.
*/
bool CParameterFileProcessor::SplitLine(String& aLine)
{
	unsigned int startPos=0;
	unsigned int endPos=0; 	

	// Segregate parameters based on white-space or tabs.
	startPos= aLine.find_first_not_of(" \t",endPos);
	while(startPos != std::string::npos)
	{		
		endPos= aLine.find_first_of(" \t",startPos);
		String paramStr= aLine.substr(startPos,endPos-startPos);

		unsigned int position= aLine.find_first_of("\"",startPos);

		// If the parameter contains double quotes('"') then also include the spaces(if provided)
		// within the quotes.		
		if((position!=std::string::npos) && position<=endPos)
		{
			endPos= aLine.find_first_of("\"",position+1);
			if(endPos!= std::string::npos)
			{				
				endPos= aLine.find_first_of(" \t",endPos+1);
				if(endPos != std::string::npos)
				{
					paramStr= aLine.substr(startPos,endPos-startPos);
				}
				
				// Remove '"' from parameter
				for(unsigned int count =0;count<paramStr.size();count++)
				{
					if (paramStr.at(count) == '"')
					{
						paramStr.erase(count,count+1);
					}
				}
			}
			// Generate error message if enclosing quotes are not found.
			else
			{
				std::cout<<"Error while parsing parameter-file"<<iParamFileName.c_str()<<". Closing \"\"\" not found\n";
				return false;				
			}
		}

		iParameters.push_back(paramStr);
		startPos= aLine.find_first_not_of(" \t",endPos);
	}	
	return true;
}


/**
Function to set number of parameters read.

@return false if no parameters are specified in parameter-file, else true
@internalComponent
@released
*/
bool CParameterFileProcessor::SetNoOfArguments()
{
	unsigned int noOfArguements = iParameters.size();	
	if (!noOfArguements)
	{
		std::cout<<"Warning: No parameters specified in paramer-file:"<<iParamFileName.data()<<"\n";
		return false;
	}
	iNoOfArguments = noOfArguements+1;
	return true;
}


/**
Function to set the value of parameters read in the 
form of 2D char array.

@internalComponent
@released
*/
void CParameterFileProcessor::SetParameters()
{
	// Store the parameters read in a 2D array of characters
	unsigned int paramSize = iParameters.size();
	iParamFileArgs=new char*[paramSize+1];			  
	
	for (unsigned int count=1; count<=paramSize; count++)
	{
		String param = iParameters.at(count-1);
		*(iParamFileArgs+count) = new char[param.size()+1];
		strcpy(*(iParamFileArgs+count),param.c_str());
	}
}


/**
Function to close parameter-file

@internalComponent
@released
*/
void CParameterFileProcessor::CloseFile()
{
	iParamFile.close();	
}


/**
Function to return number of parameters read from parameter-file

@internalComponent
@released

@return iNoOfArguments - Number of parameters read from parameter-file
*/
unsigned int CParameterFileProcessor::GetNoOfArguments() const
{
	return iNoOfArguments;
}


/**
Function to return parameters read from parameter-file

@internalComponent
@released

@return iParamFileArgs - Parameters read from parameter-file
*/
char** CParameterFileProcessor::GetParameters() const
{
	return iParamFileArgs;
}


/**
Destructor of CParameterFileProcessor class

@internalComponent
@released
*/
CParameterFileProcessor::~CParameterFileProcessor()
{
	for (unsigned int count=1;count<iNoOfArguments;count++)
		delete[] *(iParamFileArgs+count);	
}
