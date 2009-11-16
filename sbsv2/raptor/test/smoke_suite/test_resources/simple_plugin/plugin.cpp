/*
* Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Example data recognizer plugin
*
*/



#include <eikenv.h>
#include <implementationproxy.h>

// User include
#include "plugin.h"

const TInt KNumDataTypes = 1;
const TUid KExampleDllUid = {0xE8000002};
const TInt KImplementationUid = 0x101F7DA1;

// An example mime type
_LIT8(KExampleTextMimeType, "text/example");

/*
Constructor - sets the number of supported mime types,
the recognizer's priority and its UID.
*/
CExampleNewRecognizer::CExampleNewRecognizer():CApaDataRecognizerType(KExampleDllUid, CApaDataRecognizerType::EHigh)
	{
    iCountDataTypes = KNumDataTypes;
	}

/*
Specifies this recognizer's preferred data buffer size passed to DoRecognizeL().
The actual value used will be the maximum of all recognizers.
*/
TUint CExampleNewRecognizer::PreferredBufSize()
	{
    return 24;
	}


/*
Returns the indexed data type that the recognizer can recognize.
In this case, only 1 is supported.
*/
TDataType CExampleNewRecognizer::SupportedDataTypeL(TInt /*aIndex*/) const
	{
	return TDataType(KExampleTextMimeType);
	}

/*
Attempts to recognize the data type, given the filename and data buffer.
*/
void CExampleNewRecognizer::DoRecognizeL(const TDesC& aName, const TDesC8& aBuffer)
	{
	_LIT8(KExampleData, "example");
	_LIT(KDotExample, ".Example");

	TParse parse;
	parse.Set(aName,NULL,NULL);
	TPtrC ext=parse.Ext(); // extract the extension from the filename

	if (ext.CompareF(KDotExample)==0 && aBuffer.FindF(KExampleData)!=KErrNotFound)
		{
		iConfidence=ECertain;
		iDataType=TDataType(KExampleTextMimeType);
		}
    }

/*
The ECom implementation creation function.
*/
CApaDataRecognizerType* CExampleNewRecognizer::CreateRecognizerL()
	{
	return new (ELeave) CExampleNewRecognizer;
	}

/*
Standard ECom framework code
*/
const TImplementationProxy ImplementationTable[] =
    {
	IMPLEMENTATION_PROXY_ENTRY(KImplementationUid,CExampleNewRecognizer::CreateRecognizerL)
	};

/*
Standard ECom framework code
*/
EXPORT_C const TImplementationProxy* ImplementationGroupProxy(TInt& aTableCount)
    {
    aTableCount = sizeof(ImplementationTable) / sizeof(TImplementationProxy);
    return ImplementationTable;
    }
