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


#ifndef PARAMETERFILEPROCESSOR_H
#define PARAMETERFILEPROCESSOR_H

#include<iostream>
#include<string>
#include<vector>
#include<fstream>

typedef std::string String;
typedef std::vector<String> VectorOfStrings;
typedef std::ifstream FileInputStream;

/**
Class CParameterFileProcessor for processing parameter-file

@internalComponent
@released
*/

class CParameterFileProcessor
{
	FileInputStream iParamFile;	 	
	String iParamFileName;		 // Parameter-file name
	VectorOfStrings iParameters; // Parameters read from parameter-file
	unsigned int iNoOfArguments; // Number of parameters present in the parameter-file.
	char **iParamFileArgs; // Pointer to 2D character array containing the parameters 
						   // read from parameter-file.	 
							   
public:			
	CParameterFileProcessor(String aParamFileName);	
	bool ParameterFileProcessor();	
	unsigned int GetNoOfArguments() const;
	char** GetParameters() const;
	~CParameterFileProcessor();

private:
	bool OpenFile();
	bool SplitLine(String& aLine);
	bool SetNoOfArguments();
	void SetParameters();
	void CloseFile();
};	

#endif //PARAMETERFILEPROCESSOR_H
