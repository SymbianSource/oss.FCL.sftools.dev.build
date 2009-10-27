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
* ImageChecker controller class declaration
* @internalComponent
* @released
*
*/


#ifndef IMGCHECKMANAGER_H
#define IMGCHECKMANAGER_H

#include "cmdlinehandler.h"
#include "imagereader.h"
#include "checker.h"

/** 
This class is a controller class for imgcheck tool. Controls the instantiation and 
operations of ImageReader, Checker, Reporter and ReportWriter.

@internalComponent
@released
*/
class ImgCheckManager
{
public:
	ImgCheckManager(CmdLineHandler* aCmdPtr);
	~ImgCheckManager(void);
	void Process(ImageReader* aImgReader);
	void CreateObjects(void); 
	void Execute(void);
	void FillReporterData(void);
	void GenerateReport(void);
	void InsertWriter(ReportWriter* aWriter);

private:
	void HandleImage(const String& aImgName, EImageType aImageType = EUnknownImage);
    
protected:
	CmdLineHandler* iCmdLine;
	Reporter *iReporter;
	ImageReaderPtrList iImageReaderList;
	CheckerPtrList iCheckerList;
	WriterPtrList iWriterList;
	bool iNoRomImage;
};

#endif //IMGCHECKMANAGER_H
