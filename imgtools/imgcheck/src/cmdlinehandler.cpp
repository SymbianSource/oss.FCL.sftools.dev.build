/*
* Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Commandline handler for imgcheck Tool, responsible to parse the
* commandline options and preserve the data for later use
*
*/


/**
@file
@internalComponent
@released
*/

#include "cmdlinehandler.h"

/**
Constructor initializes the iOptionMap with short and long option names as key and
the value pair says whether the respective option can have value or not.

@internalComponent
@released
*/
CmdLineHandler::CmdLineHandler()
:iDebuggableFlagVal(false),iXmlFileName(GXmlFileName), iNoImage(true), iCommmandFlag(0), iValidations(0), iSuppressions(0)  {
	iOptionMap[KLongHelpOption] = ENone;
	iOptionMap[KLongAllOption] = ENone;
	iOptionMap[KLongXmlOption] = ENone;
	iOptionMap[KLongOutputOption] = ESingle; //option can have only 1 value
	iOptionMap[KLongQuietOption] = ENone;
	iOptionMap[KLongVerboseOption] = ENone;
	iOptionMap[KLongSuppressOption]= EMultiple; //This value should be updated, while introducing new validations
	iOptionMap[KLongVidValOption]= EMultiple;
	iOptionMap[KShortHelpOption] = ENone;
	iOptionMap[KShortAllOption] = ENone;
	iOptionMap[KShortXmlOption] = ENone;
	iOptionMap[KShortOutputOption] = ESingle; //option can have only 1 value
	iOptionMap[KShortQuietOption] = ENone;
	iOptionMap[KShortVerboseOption] = ENone;
	iOptionMap[KShortSuppressOption] = EMultiple;
	iOptionMap[KShortNoCheck] = ENone;
	iOptionMap[KLongSidAllOption] = ENone;
	iOptionMap[KLongEnableDepCheck] = ENone;
	iOptionMap[KLongEnableSidCheck] = ENone;
	iOptionMap[KLongEnableVidCheck] = ENone;
	iOptionMap[KLongEnableDbgFlagCheck] = EOptional;
	iOptionMap[KLongE32InputOption] = ENone;
	iOptionMap[KLongNoCheck] = ENone;
	iSuppressVal[KSuppressDependency] = EDep;
	iSuppressVal[KSuppressSid] = ESid;
	iSuppressVal[KSuppressVid] = EVid;

	Version();
	Usage();
}

/**
Destructor.

@internalComponent
@released
*/
CmdLineHandler::~CmdLineHandler() {
	iOptionMap.clear();
	iImageNameList.clear();
	iSuppressVal.clear();
	iVidValList.clear();
}

/**
Function to parse the command line options.
Responsible to
1. Parse the input values.
2. Print the usage note. 
3. Identify the valdations to be carried out.
4. Type of report needs to be generated.

@internalComponent
@released

@param aArgc - argument count
@param aArgv[] - argument values
*/
ReturnType CmdLineHandler::ProcessCommandLine(unsigned int aArgc, char* aArgv[]) {
	if(aArgc < 2) {
		cout << PrintVersion().c_str() << endl;
		cout << PrintUsage().c_str() << endl;
		return EQuit;
	}
	//ArgumentList argumentList(&aArgv[0], aArgv + aArgc);
	//int argCount = argumentList.size();

	iInputCommand = KToolName;

	for(unsigned int i = 1; i < aArgc; i++ )  {//Skip tool name		 
		iInputCommand.append(1,' ');
		char* arg = aArgv[i];
		iInputCommand.append(arg);
		int longOptionFlag = 0;
		if(IsOption(arg, longOptionFlag)) { 
			bool optionValue = false;
			cstrings optionValueList;
			ParseOption(arg, optionValueList, optionValue);
			string optionName(arg) ;
			ReaderUtil::ToLower(optionName);
			char shortOption = 0;
			if(Validate(optionName, optionValue, optionValueList.size())) {
				if(longOptionFlag) {
					shortOption = optionName.at(2);
				}
				else {
					shortOption = optionName.at(1);
				}
			}

			switch(shortOption) {
				case 'q':
					iCommmandFlag |= QuietMode;
					break;
				case 'a': 
					iCommmandFlag |= KAll;
					break;
				case 'x':
					iCommmandFlag |= KXmlReport;
					break;
				case 'o':
					iXmlFileName = string(optionValueList.front()); 
					NormaliseName();
					break;
				case 's':
					if((optionName == KShortSuppressOption) || (optionName == KLongSuppressOption)) {
						int size = optionValueList.size();
						for(int idx = 0 ; idx < size ; idx++) {
							string value(optionValueList.at(idx));
							SuppressionsMap::iterator it = iSuppressVal.find(value);
							if(it != iSuppressVal.end()) {
								if(iValidations > 0) { //Is any check enabled? 
									if(iValidations & it->second) {
										iValidations ^= it->second; //Consider only 3 LSB's
									}
								}
								else {//Is this valid value? 
									iSuppressions |= it->second;
								}
							}
							else {
								throw ExceptionReporter(UNKNOWNSUPPRESSVAL,optionValueList.at(idx));
							} 
						}
						optionValueList.clear();
					}
					else if(optionName == KLongEnableSidCheck) {
						iValidations |= KMarkEnable;
						iValidations |= ESid;
					}
					else if(optionName == KLongSidAllOption) {
						iCommmandFlag |= KSidAll;
					}
					break;
				case 'd':
					if(optionName == KLongEnableDbgFlagCheck) {
						iValidations |= KMarkEnable;
						iValidations |= EDbg;
						if(optionValueList.size() > 0) {
							if(strcmp(optionValueList.front(),"true") == 0) {
								iDebuggableFlagVal = true;
							}
							else if (strcmp(optionValueList.front(),"false") == 0) {
								iDebuggableFlagVal = false; 
							}
							else {
								throw ExceptionReporter(UNKNOWNDBGVALUE);
							}
						}
					}
					else if (optionName == KLongEnableDepCheck) {
						iValidations |= KMarkEnable;
						iValidations |= EDep;
					}
					break;

				case 'e':
					if (optionName == KLongE32InputOption) {
						iCommmandFlag |= KE32Input;
					}
					break;

				case 'v':
					if(optionName == KLongVidValOption) {
						StringListToUnIntList(optionValueList, iVidValList);
					}
					else if(optionName == KLongEnableVidCheck) {
						iValidations |= KMarkEnable;
						iValidations |= EVid;
					}
					else {
						iCommmandFlag |= KVerbose;
						/**Initialize ExceptionImplementation class with verbose mode flag
						to print all status information to standard output*/
						ExceptionImplementation::Instance(iCommmandFlag);
					}
					break;
				case 'n':
					iCommmandFlag |= KNoCheck;
					break;
				case 'h':
					cout << PrintVersion().c_str() << endl;
					cout << PrintUsage().c_str() << endl;
					return EQuit; //Don't proceed further
			}
		}
		else {
			if(!AlreadyReceived(arg)) {
				iImageNameList.push_back(arg);
			}
			else {
				ExceptionReporter(IMAGENAMEALREADYRECEIVED, arg).Report();
			}

			iNoImage = false;
		}
	} //While loop ends here
	if((iCommmandFlag || iValidations || iSuppressions) && iNoImage) {
		PrintVersion();
		PrintUsage();
	}
	//Always log the version information into log file
	ExceptionImplementation::Instance(iCommmandFlag)->Log(iVersion);
	ValidateArguments();
	ValidateE32NoCheckArguments();
	if(iCommmandFlag & KE32Input) {
		ValidateImageNameList();
	}
	return ESuccess;
}

/**
Function identify whether the passed string is an option or not.

@internalComponent
@released

@param aName - a string received as part of command line
@param aLongOptionFlag - this flag is set if the option is long else
it is assumed as short option.

@return - returns true or false
*/
bool CmdLineHandler::IsOption(const char* aName, int& aLongOptionFlag) {
	int prefixCount = 0;
	int len = strlen(aName);
	while(aName[prefixCount] == KShortOptionPrefix) {
		if(len == ++prefixCount) {
			throw ExceptionReporter(UNKNOWNOPTION, aName);
		}
	}

	switch(prefixCount) {
		case 0: //argument can be an image
			return false;
		case 1: // '-'
			return true;
		case 2: // '--'
			aLongOptionFlag = 1;
			return true;
		default:
			throw ExceptionReporter(UNKNOWNPREFIX, aName);
	}
}

/**
Function to do syntax validation on the received option.
1. Identifies whether the received option is valid or not.
2. Identifies whether the option can have vaue or not.
3. Throws an error if no value received for an option which should have value.
4. Throws an error if more number of values received.
5. Throws an error if an unwanted value received.
6. Throws an error if the option is not a valid one.

@internalComponent
@released

@param aOption - a string received as part of command line.
@param aOptionValue - Whether option value received or not.
@param aNoOfVal - Number of values received for this option.

@return - returns true if it is a valid option
*/
bool CmdLineHandler::Validate(const string& aOption, bool aOptionValue, unsigned int aNoOfVal) {
	if(iOptionMap.find(aOption) != iOptionMap.end()) {
		if(iOptionMap[aOption]) {//Option can have value? 
			if((aNoOfVal == ENone) && (iOptionMap[aOption] != EOptional)) {//No values received? 
				throw ExceptionReporter(VALUEEXPECTED, aOption.c_str());
			}

			if((iOptionMap[aOption] == ESingle) && (ESingle < aNoOfVal)){ //Received values are more than expected 
				throw ExceptionReporter(UNEXPECTEDNUMBEROFVALUE,aOption.c_str());
			}
		}
		else {
			if(aOptionValue) {//Is option value received? Any character after the option considered as value. 
				throw ExceptionReporter(VALUENOTEXPECTED, aOption.c_str());
			}
		}
		return true;
	}
	throw ExceptionReporter(UNKNOWNOPTION, aOption.c_str());
}

/**
Function to split the option name and option values.
1. Ignore's the '=' symbol which is following the option. But this is an error, if that
option does not expecting any value.
2. Parses the value received with options.

@internalComponent
@released

@param aFullName - Option with its value 
@param aOptionValues - Option values put into this parameter
@param aOptionValue - Set this flag if any value received with the option.
*/
void CmdLineHandler::ParseOption(char* aFullName, cstrings& aOptionValues, bool& aOptionValue) { 
	//unsigned int optionEndLocation = aFullName.find('='); 
	char* p = strchr(aFullName,'=');
	if(NULL != p) {
		aOptionValue = true;
		*p = 0 ;
		p++ ;
		if(0 == *p) {
			throw ExceptionReporter(VALUEEXPECTED, aFullName);
		}		 
		 
		//Get all the values; use (,) as delimiter
		char* start = p , *stop = p ; 
		bool cont = true ;
		while(cont){
			while(*stop != ',' && *stop != 0)
				stop ++;	
			cont = (0 != *stop) ;
			if(stop > start){  
				*stop = 0 ;
				aOptionValues.push_back(start); 
				
			}			 
			start = stop + 1;
			stop = start ;
		}  
	} 
}

/**
Function to initialize the usage.

@internalComponent
@released
*/
void CmdLineHandler::Usage(void) {
	iUsage.assign("syntax: imgcheck [options] <img1> [<img2 .. imgN>] \n"
		"imgcheck --e32input [options] (<file> | <directory>) \n"
		"\n"
		"options: \n"
		"  -a, --all,             Report all executable's status\n"
		"  -q, --quiet,           Command line display off\n"
		"  -x, --xml,             Generate XML report\n"
		"  -o=xxx, --output=xxx   Override default XML file name\n"
		"  -v, --verbose,         Verbose mode output\n"
		"  -h, --help,            Display this message\n"
		"  -s=val1[,val2][...], --suppress=val1[,val2][...] \n"
		"                         Suppress one or more check,\n"
		"                         Possible values are dep, sid and vid\n"
		"  --vidlist=val1[,val2][...] \n"
		"                         One or more VID value(s) \n"
		"  --dep                  Enable dependency check\n"
		"  --vid                  Enable VID check\n"
		"  --sid                  Enable SID check, only EXEs are considered by default\n"
		"  --sidall               Include DLL also into SID check\n"
		"  --dbg[=val]            Enable Debug flag check,\n"
		"                         Optionally over ride the default value 'false'\n"
		"  --e32input             Switches the tool to filesystem mode\n"
		"  -n, --nocheck          Don't report any check(s) status\n");
}

/**
Function to return the usage.

@internalComponent
@released
*/
const string& CmdLineHandler::PrintUsage(void) const {
	return iUsage;
}

/**
Function to prepare the version information.

@internalComponent
@released
*/
void CmdLineHandler::Version(void) {
	iVersion.append(gToolDesc);
	iVersion.append(gMajorVersion);
	iVersion.append(gMinorVersion);
	iVersion.append(gMaintenanceVersion);
	iVersion.append(gCopyright);
}

/**
Function to return the version information.

@internalComponent
@released
*/
const string& CmdLineHandler::PrintVersion(void) const {
	return iVersion;
}

/**
Function to return the image name one by one.

@internalComponent
@released

@return - returns image name
*/
const char* CmdLineHandler::NextImageName(void) {
	const char* imageName = 0 ;
	if( iImageNameList.size() > 0 ) {
		imageName = iImageNameList.at(0);
		iImageNameList.erase(iImageNameList.begin());
	}
	return imageName;
}

/**
Function to return the iCommmandFlag.

@internalComponent
@released

@return - returns iCommmandFlag value.
*/
const unsigned int CmdLineHandler::ReportFlag(void) const {
	return iCommmandFlag;
}

/**
Function to return the iXmlFileName.

@internalComponent
@released

@return - returns iXmlFileName value.
*/
const string& CmdLineHandler::XmlReportName(void) const {
	return iXmlFileName;
}


/**
Function to append the XML extension to the received XML name.

@internalComponent
@released
*/
void CmdLineHandler::NormaliseName(void) {
	if (iXmlFileName.find(KXmlExtension) == string::npos) {
		iXmlFileName.append(KXmlExtension);
	}
}

/**
Function to validate the arguements to ensure that the tool is invoked with proper
arguments.

@internalComponent
@released
*/
void CmdLineHandler::ValidateArguments(void) const {
	unsigned int validations = EnabledValidations();
	validations = (validations & KMarkEnable) ? iValidations ^ KMarkEnable:validations; //disable MSB

	if( iCommmandFlag & QuietMode && !(iCommmandFlag & KXmlReport)) {
		throw ExceptionReporter(QUIETMODESELECTED);
	}

	if(!(iCommmandFlag & KXmlReport) && (iXmlFileName != GXmlFileName)) {
		ExceptionReporter(XMLOPTION).Report();
	}

	if((iVidValList.size() > 0) && (validations & EVid) == 0) {
		ExceptionReporter(SUPPRESSCOMBINEDWITHVIDVAL).Report();
	}

	if((iCommmandFlag & KSidAll) && ((validations & ESid)==0)) {
		ExceptionReporter(SIDALLCOMBINEDWITHSID).Report();
	}

	if( validations == ENone) {
		throw ExceptionReporter(ALLCHECKSSUPPRESSED);
	}

	if(iNoImage) {
		throw ExceptionReporter(NOIMAGE);
	}
}

/**
Function to return number of images received through command line.

@internalComponent
@released
*/
unsigned int CmdLineHandler::NoOfImages(void) const {
	return iImageNameList.size();
}

/**
Function to return Validations needs to be performed.
1. If any validation is enabled, then only enabled validations are carried.
2. If any validation is suppressed, then all validations are carried execept the suppressed ones.

@internalComponent
@released

@return - returns the enabled Validations
*/
const unsigned int CmdLineHandler::EnabledValidations(void) const {
	if(iValidations > 0) {
		return iValidations;
	}
	return (iSuppressions ^ EAllValidation); //Enable unsuppressed options
}
static int indexOf(const char* str, char ch){ 
	for(int i = 0 ; str[i] != 0 ; i++){
		if(str[i] == ch) 
			return i ;
	}
	return -1 ;
}
/**
Function to convert cstrings to integers.
1. If any validation is enabled, then only enabled validations are carried.
2. If any validation is suppressed, then all validations are carried execept the suppressed ones.
3. Throws an error if the value is not a decimal or hexadecimal one.

@internalComponent
@released

@param aStrList - List VID values received at command line
@param aUnIntList - Received values are validated and put into this container.
*/
void CmdLineHandler::StringListToUnIntList(cstrings& aStrList, UnIntList& aUnIntList) { 
	int size = aStrList.size();
	for(int i = 0 ; i < size ; i++ ) {
		const char* arg = aStrList.at(i); 
		unsigned int val = 0 ;
		if('0' == arg[0]  && 'x' == (arg[1] | 0x20)){ // hex
			arg += 2; 		
			const char* savedStr = arg ;
			int index;			
			while(*arg){ 
				if(val > 0x0fffffff)
					throw ExceptionReporter(DATAOVERFLOW,savedStr);
				index = indexOf(KHexNumber,*arg);
				if(-1 == index)
					throw ExceptionReporter(INVALIDVIDVALUE,savedStr);
				val <<= 4 ;
				val += index ;
				arg ++ ;
			}
		}else{ // dec
			const char* savedStr = arg ;
			int index;
			while(*arg){ 
				if(val >= 0x1999999A) // 0xffffffff / 10
					throw ExceptionReporter(DATAOVERFLOW,savedStr);
				index = indexOf(KDecNumber,*arg);
				if(-1 == index)
					throw ExceptionReporter(INVALIDVIDVALUE,savedStr);
				val *= 10 ;
				val += index ;
				arg ++ ;
			}
		}		
		aUnIntList.push_back(val);	 
	}
	aStrList.clear();
}



/**
Function to return vid value list.

@internalComponent
@released

@return - returns vid value list.
*/
UnIntList& CmdLineHandler::VidValueList() {
	return iVidValList;
}

/**
Function to return input command string.

@internalComponent
@released

@return - returns iInputCommand.
*/
const string& CmdLineHandler::Command() const {
	return iInputCommand;
}

/**
Function identifies whether the image is already received or not.

@internalComponent
@released

@return	- returns true if the image is already received.
- returns false if the image is not received already.
*/
bool CmdLineHandler::AlreadyReceived(const char* aName) {
	for(cstrings::iterator it = iImageNameList.begin(); it != iImageNameList.end();it++) {
		if(aName == *it || strcmp(aName,*it) == 0) {
			return true;
		} 
	}
	return false;
}

/**
Function to return debug flag value.

@internalComponent
@released

@return - returns iDebuggableFlagVal.
*/
bool CmdLineHandler::DebuggableFlagVal() {
	return iDebuggableFlagVal;
}

/**
Function to validate the e32 input.

@internalComponent
@released

*/
void CmdLineHandler::ValidateImageNameList(void)  {
	if(iImageNameList.size() > 1) {
		throw ExceptionReporter(ONLYSINGLEDIRECTORYEXPECTED);
	}
}


/**
Function to validate the e32 and no check option arguments.

@internalComponent
@released

*/
void CmdLineHandler::ValidateE32NoCheckArguments(void) {
	if((iCommmandFlag & KE32Input) && !iValidations) {
		throw ExceptionReporter(NOVALIDATIONSENABLED);
	}

	if((iCommmandFlag & KE32Input) && (iValidations & (EDep | ESid))) {
		ExceptionReporter(INCORRECTVALUES).Report();
	}
}
