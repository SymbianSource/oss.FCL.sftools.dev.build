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
* Reporter class declaration.
* @internalComponent
* @released
*
*/


#ifndef REPORTER_H
#define REPORTER_H

#include "common.h"
#include "exceptionreporter.h"
#include "reportwriter.h"
#include "cmdlinewriter.h"
#include "xmlwriter.h"
#include <vector>

typedef std::list<ExeAttribute*> ExeAttList;

struct ExeContainer
{
	String iExeName;
	IdData* iIdData;
	StringList iDepList;
	ExeAttList iExeAttList;
};

typedef std::map<std::string, ExeContainer> ExeVsMetaData;
typedef std::map<std::string, ExeVsMetaData> ImgVsExeStatus;

/** 
Base class for all type of report generation.

@internalComponent
@released
*/
class Reporter
{

public:
	~Reporter();
	void CreateReport(const WriterPtrList& aWriterList);
	static void DeleteInstance(void);
	ImgVsExeStatus& GetContainerReference(void);
	static Reporter* Instance(unsigned int aCmdOptions);

protected:
	// Container required for report object storing.
	WriterPtrList iReportWriterPtrList;
	//Integrated container
	ImgVsExeStatus iImgVsExeStatus;
private:
	static Reporter* iInstance;
	Reporter(unsigned int aCmdOptions);
	bool IsAttributeAvailable(void);
	unsigned int iInputOptions;
};

#endif // REPORTER_H
