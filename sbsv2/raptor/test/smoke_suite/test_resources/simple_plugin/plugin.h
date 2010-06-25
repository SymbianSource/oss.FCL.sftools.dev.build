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



#if !defined(__EXAMPLERECOGNIZER_H__)
#define __EXAMPLERECOGNIZER_H__

#if !defined(__APMREC_H__)
#include <apmrec.h>
#endif

/*
CExampleNewRecognizer is a concrete data recognizer.
It implements CApaDataRecognizerType, the abstract base
class for recognizers.
*/
class CExampleNewRecognizer: public CApaDataRecognizerType
	{
public:
    CExampleNewRecognizer();
    TUint PreferredBufSize();
	TDataType SupportedDataTypeL(TInt) const;
    static CApaDataRecognizerType* CreateRecognizerL();
private:
    void DoRecognizeL(const TDesC&, const TDesC8&);
	};

#endif
